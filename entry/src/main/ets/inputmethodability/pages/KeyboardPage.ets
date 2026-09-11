/*
 * KeyboardPage — the ArkUI content hosted inside the IME soft-keyboard panel.
 * Owns the reactive keyboard state (mode + shift) and the FlorisBoard-style
 * input state machine; dispatches committed text through InputHandler.
 */
import inputMethod from '@ohos.inputMethod';
import inputMethodEngine from '@ohos.inputMethodEngine';
import mediaquery from '@ohos.mediaquery';
import { KeyButton } from '../../components/KeyButton';
import { InputHandler } from '../model/InputHandler';
import { LayoutStore } from '../../model/LayoutStore';
import { KeyboardMode, ShiftState, KeyCode, KeyDef, LayoutDef, RowDef, KeyUtils } from '../../model/KeyModels';
import { ThemeColors, FlorisLight, FlorisDark, Metrics } from '../../model/Theme';

const EMPTY_LAYOUT: LayoutDef = { name: 'empty', rows: [] };

@Entry
@Component
struct KeyboardPage {
  @State mode: string = KeyboardMode.CHARACTERS;
  @State shift: number = ShiftState.UNSHIFTED;
  @State accents: string[] = [];
  @State isDark: boolean = false;
  @StorageProp('enterKeyType') enterKeyType: number = 0;
  // Bumped by InputHandler.onInputStart; lets the page reset per editor session.
  @StorageProp('imeSession') @Watch('onNewSession') imeSession: number = 0;

  private layouts: Map<string, LayoutDef> = new Map<string, LayoutDef>();
  private lastShiftTap: number = 0;
  private lastSpaceTap: number = 0;
  private autoCap: boolean = true;
  private darkListener: mediaquery.MediaQueryListener | undefined = undefined;

  aboutToAppear(): void {
    const rm = getContext(this).resourceManager;
    const names: string[] = [KeyboardMode.CHARACTERS, KeyboardMode.SYMBOLS, KeyboardMode.SYMBOLS2, KeyboardMode.NUMERIC];
    for (const n of names) {
      try {
        this.layouts.set(n, LayoutStore.load(rm, n));
      } catch (e) {
        console.error(`FlorisIME failed to load layout ${n}`);
      }
    }
    // Follow the system light/dark setting (reactive).
    try {
      this.darkListener = mediaquery.matchMediaSync('(dark-mode: true)');
      this.isDark = this.darkListener.matches;
      this.darkListener.on('change', (res: mediaquery.MediaQueryResult) => {
        this.isDark = res.matches;
      });
    } catch (e) {
      console.error('FlorisIME dark-mode query failed');
    }
    this.evalAutoCap();
  }

  aboutToDisappear(): void {
    if (this.darkListener !== undefined) {
      this.darkListener.off('change');
      this.darkListener = undefined;
    }
  }

  // Reset to a clean state whenever a new editor binds (new field focused).
  onNewSession(): void {
    this.mode = KeyboardMode.CHARACTERS;
    this.shift = ShiftState.UNSHIFTED;
    this.accents = [];
    this.lastShiftTap = 0;
    this.lastSpaceTap = 0;
    this.evalAutoCap();
  }

  private theme(): ThemeColors {
    return this.isDark ? FlorisDark : FlorisLight;
  }

  private layout(): LayoutDef {
    const l: LayoutDef | undefined = this.layouts.get(this.mode);
    return l !== undefined ? l : EMPTY_LAYOUT;
  }

  // ---- input state machine ----

  private handler(): InputHandler {
    return InputHandler.getInstance();
  }

  private resetShiftAfterChar(): void {
    if (this.shift === ShiftState.SHIFTED_MANUAL || this.shift === ShiftState.SHIFTED_AUTOMATIC) {
      this.shift = ShiftState.UNSHIFTED;
    }
  }

  private evalAutoCap(): void {
    if (!this.autoCap || this.mode !== KeyboardMode.CHARACTERS) {
      return;
    }
    if (this.shift === ShiftState.CAPS_LOCK || this.shift === ShiftState.SHIFTED_MANUAL) {
      return;
    }
    // Only auto-capitalize plain text fields — not password / email / URI / number etc.
    const pattern: number = this.handler().getInputPattern();
    if (pattern !== inputMethodEngine.PATTERN_TEXT && pattern !== inputMethodEngine.PATTERN_NULL) {
      this.shift = ShiftState.UNSHIFTED;
      return;
    }
    const before: string = this.handler().textBeforeCursor(2);
    const atStart: boolean = before.length === 0;
    const afterSentence: boolean = /[.!?]\s$/.test(before);
    this.shift = (atStart || afterSentence) ? ShiftState.SHIFTED_AUTOMATIC : ShiftState.UNSHIFTED;
  }

  private commitChar(text: string): void {
    this.accents = [];
    this.handler().insert(text);
    this.resetShiftAfterChar();
  }

  private onCommit(text: string): void {
    this.commitChar(text);
  }

  private onAction(key: KeyDef): void {
    this.accents = [];
    switch (key.kind) {
      case 'shift':
        this.handleShift();
        break;
      case 'delete':
        this.handler().backspace();
        this.evalAutoCap();
        break;
      case 'enter':
        this.handler().enter();
        this.evalAutoCap();
        break;
      case 'space':
        this.handleSpace();
        break;
      case 'view':
        this.handleView(key.target);
        break;
      case 'lang':
        this.handleLang();
        break;
      default:
        break;
    }
  }

  private handleShift(): void {
    const now: number = Date.now();
    // Any double-tap (from any non-caps state) latches CAPS LOCK; otherwise a
    // single tap toggles the one-shot manual shift on/off. 400 ms is a bit more
    // forgiving than the 300 ms system double-tap timeout (easier caps-lock).
    if (this.shift !== ShiftState.CAPS_LOCK && (now - this.lastShiftTap) < 400) {
      this.shift = ShiftState.CAPS_LOCK;
    } else if (this.shift === ShiftState.UNSHIFTED) {
      this.shift = ShiftState.SHIFTED_MANUAL;
    } else {
      this.shift = ShiftState.UNSHIFTED;
    }
    this.lastShiftTap = now;
  }

  private handleSpace(): void {
    const now: number = Date.now();
    const consecutive: boolean = (now - this.lastSpaceTap) < 600;
    const before: string = this.handler().textBeforeCursor(2);
    if (consecutive && /[^.!?‽\s]\s$/.test(before)) {
      this.handler().backspace();
      this.handler().insert('. ');
    } else {
      this.handler().insert(' ');
    }
    this.lastSpaceTap = now;
    this.evalAutoCap();
  }

  private handleView(target: string | undefined): void {
    if (target === undefined) {
      return;
    }
    this.mode = target;
    this.shift = ShiftState.UNSHIFTED;
    if (target === KeyboardMode.CHARACTERS) {
      this.evalAutoCap();
    }
  }

  private handleLang(): void {
    try {
      inputMethod.getSetting().showOptionalInputMethods();
    } catch (e) {
      console.error('FlorisIME showOptionalInputMethods failed');
    }
  }

  private onDeleteRepeat(): void {
    this.handler().backspace();
  }

  private onShowAccents(popups: string[]): void {
    const up: boolean = KeyUtils.isUppercase(this.shift);
    this.accents = up ? popups.map((p: string) => p.toUpperCase()) : popups;
  }

  // ---- per-key view computations ----

  private displayLabel(key: KeyDef): string {
    switch (key.kind) {
      case 'char':
        return KeyUtils.casedOutput(key, this.shift);
      case 'shift':
        // Plain text glyphs only — the filled U+2B06 arrow renders as a blue
        // emoji tile on this system. One-shot shift is signalled by the keys
        // going uppercase; caps-lock additionally tints the glyph (keyFg).
        return this.shift === ShiftState.CAPS_LOCK ? '⇪' : '⇧';
      case 'delete':
        return '⌫';
      case 'enter':
        return this.enterLabel();
      case 'space':
        return 'English';
      case 'lang':
        return '🌐';
      case 'view':
        return key.label !== undefined ? key.label : '';
      default:
        return '';
    }
  }

  private enterLabel(): string {
    switch (this.enterKeyType) {
      case inputMethodEngine.ENTER_KEY_TYPE_GO: return 'Go';
      case inputMethodEngine.ENTER_KEY_TYPE_SEARCH: return 'Search';
      case inputMethodEngine.ENTER_KEY_TYPE_SEND: return 'Send';
      case inputMethodEngine.ENTER_KEY_TYPE_NEXT: return 'Next';
      case inputMethodEngine.ENTER_KEY_TYPE_DONE: return 'Done';
      case inputMethodEngine.ENTER_KEY_TYPE_PREVIOUS: return 'Prev';
      default: return '⏎';
    }
  }

  private commitTextFor(key: KeyDef): string {
    return KeyUtils.casedOutput(key, this.shift);
  }

  private isSpecial(kind: string): boolean {
    return kind === 'shift' || kind === 'delete' || kind === 'view' || kind === 'lang';
  }

  private keyBg(key: KeyDef): string {
    const t: ThemeColors = this.theme();
    if (key.kind === 'enter') {
      return t.enterKeyBackground;
    }
    // FlorisBoard Day/Night: every key is `--surface`; only enter is tinted.
    if (this.isSpecial(key.kind)) {
      return t.specialKeyBackground;
    }
    return t.keyBackground;
  }

  private keyFg(key: KeyDef): string {
    const t: ThemeColors = this.theme();
    if (key.kind === 'enter') {
      return t.enterKeyForeground;
    }
    // Caps-lock recolors the shift glyph to the secondary accent (orange).
    if (key.kind === 'shift') {
      return this.shift === ShiftState.CAPS_LOCK ? t.secondary : t.specialKeyForeground;
    }
    if (key.kind === 'space') {
      return t.spaceForeground;
    }
    if (this.isSpecial(key.kind)) {
      return t.specialKeyForeground;
    }
    return t.keyForeground;
  }

  private keyPressedBg(key: KeyDef): string {
    const t: ThemeColors = this.theme();
    if (key.kind === 'enter') {
      return t.enterKeyPressed;
    }
    return t.keyPressedBackground;
  }

  private keyFontSize(key: KeyDef): number {
    if (key.kind === 'char') {
      return Metrics.keyFontSize;
    }
    if (key.kind === 'space') {
      return Metrics.spaceFontSize;
    }
    return Metrics.specialKeyFontSize;
  }

  @Builder
  AccentBar() {
    Row() {
      ForEach(this.accents, (a: string) => {
        Text(a)
          .fontSize(Metrics.popupFontSize)
          .fontColor(this.theme().popupForeground)
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .margin(2)
          .borderRadius(6)
          .backgroundColor(this.theme().popupBackground)
          .onClick(() => {
            this.commitChar(a);
          })
      }, (a: string, idx: number) => `${a}_${idx}`)
    }
    .padding(6)
    .backgroundColor(this.theme().keyboardBackground)
    .borderRadius(8)
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Column({ space: Metrics.rowGap }) {
        ForEach(this.layout().rows, (row: RowDef, r: number) => {
          Row() {
            ForEach(row.keys, (key: KeyDef, c: number) => {
              KeyButton({
                label: this.displayLabel(key),
                commitText: this.commitTextFor(key),
                bg: this.keyBg(key),
                fg: this.keyFg(key),
                pressedBg: this.keyPressedBg(key),
                fontSize: this.keyFontSize(key),
                weight: key.weight,
                kind: key.kind,
                hasPopups: key.popups !== undefined && key.popups.length > 0,
                popups: key.popups !== undefined ? key.popups : [],
                hint: key.hint !== undefined ? key.hint : '',
                hintColor: this.theme().hintForeground,
                onCommit: (text: string) => this.onCommit(text),
                onAction: () => this.onAction(key),
                onDeleteRepeat: () => this.onDeleteRepeat(),
                onShowAccents: (p: string[]) => this.onShowAccents(p),
              })
            }, (key: KeyDef, c: number) => `${this.mode}_${r}_${c}`)
          }
          .width('100%')
          .layoutWeight(1)
        }, (row: RowDef, r: number) => `${this.mode}_row_${r}`)
      }
      .width('100%')
      .height('100%')
      .backgroundColor(this.theme().keyboardBackground)
      // The extra bottom padding is the strip the panel was grown by in
      // KeyboardController — it keeps the bottom key row clear of the system
      // gesture-navigation bar, which is drawn over the panel. The keyboard
      // background still fills it, so the bar sits on a plain coloured strip.
      .padding({
        left: Metrics.boardPadding,
        right: Metrics.boardPadding,
        top: Metrics.boardPadding,
        bottom: Metrics.boardPadding + Metrics.gestureBarInset,
      })

      if (this.accents.length > 0) {
        this.AccentBar()
      }
    }
    .width('100%')
    .height('100%')
  }
}

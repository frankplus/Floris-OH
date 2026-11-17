/*
 * One row of the keyboard: the Row of KeyButtons for a RowDef. Split out of
 * KeyboardPage.build() to keep it short; everything it needs (the row, the
 * current mode/shift, the settings and the resolved theme) comes in as
 * @Param, so a rebuild of the parent (a new layout, a setting change) updates
 * it like any other reactive child — nothing here is a captured copy.
 */
import { KeyButton } from '../../../components/KeyButton';
import { KeyboardMode, ShiftState, KeyDef, RowDef, KeyUtils } from '../../../model/KeyModels';
import { ThemeColors } from '../../../model/Theme';
import { KeyboardPrefs } from '../../../model/KeyboardPrefs';
import { KeyboardSettingsLogic } from '../../model/KeyboardSettingsLogic';

const EMPTY_ROW: RowDef = { keys: [] as KeyDef[] };

@ComponentV2
export struct KeyRow {
  @Param row: RowDef = EMPTY_ROW;
  @Param rowIndex: number = 0;
  @Param mode: string = KeyboardMode.CHARACTERS;
  @Param shift: number = ShiftState.UNSHIFTED;
  @Param prefs: KeyboardPrefs = new KeyboardPrefs();
  @Param theme: ThemeColors | undefined = undefined;
  @Param enterLabel: string = '';
  @Param spaceLabel: string = '';
  @Param layerKey: string = '';
  @Event onCommit: (text: string) => void = () => {};
  @Event onAction: (key: KeyDef) => void = () => {};
  @Event onDeleteRepeat: () => void = () => {};
  @Event onShowAccents: (popups: string[]) => void = () => {};

  private actsAs(idx: number): KeyDef {
    const k: KeyDef = this.row.keys[idx];
    if (k.kind !== 'spacer') {
      return k;
    }
    for (let i = idx + 1; i < this.row.keys.length; i++) {
      if (this.row.keys[i].kind !== 'spacer') {
        return this.row.keys[i];
      }
    }
    for (let i = idx - 1; i >= 0; i--) {
      if (this.row.keys[i].kind !== 'spacer') {
        return this.row.keys[i];
      }
    }
    return k;
  }

  private popupsOf(idx: number): string[] {
    const p: string[] | undefined = this.actsAs(idx).popups;
    return p !== undefined ? p : [];
  }

  private isSpecial(kind: string): boolean {
    return kind === 'shift' || kind === 'delete' || kind === 'view' || kind === 'lang';
  }

  private displayLabel(key: KeyDef): string {
    switch (key.kind) {
      case 'char':
        return KeyUtils.casedOutput(key, this.shift);
      case 'shift':
        return this.shift === ShiftState.CAPS_LOCK ? '⇪' : '⇧';
      case 'delete':
        return '⌫';
      case 'enter':
        return this.enterLabel;
      case 'space':
        return this.spaceLabel;
      case 'lang':
        return '🌐';
      case 'view':
        return key.label !== undefined ? key.label : '';
      default:
        return '';
    }
  }

  private commitTextFor(key: KeyDef): string {
    return KeyUtils.casedOutput(key, this.shift);
  }

  private themeColors(): ThemeColors {
    return this.theme as ThemeColors;
  }

  private keyBg(key: KeyDef): ResourceColor {
    const t: ThemeColors = this.themeColors();
    if (key.kind === 'enter') {
      return t.enterKeyBackground;
    }
    if (this.isSpecial(key.kind)) {
      return t.specialKeyBackground;
    }
    return t.keyBackground;
  }

  private keyFg(key: KeyDef): ResourceColor {
    const t: ThemeColors = this.themeColors();
    if (key.kind === 'enter') {
      return t.enterKeyForeground;
    }
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

  private keyPressedBg(key: KeyDef): ResourceColor {
    const t: ThemeColors = this.themeColors();
    if (key.kind === 'enter') {
      return t.enterKeyPressed;
    }
    return t.keyPressedBackground;
  }

  private keyFontSize(key: KeyDef): number {
    return KeyboardSettingsLogic.keyFontSize(key.kind, this.prefs.fontSizePercent);
  }

  private hintFor(key: KeyDef): string {
    return KeyboardSettingsLogic.hintFor(key, this.rowIndex, this.mode, this.prefs.hintedSymbols, this.prefs.numberRow);
  }

  private hintFontSize(): number {
    return KeyboardSettingsLogic.hintFontSize(this.prefs.fontSizePercent);
  }

  private keyId(key: KeyDef): string {
    return KeyboardSettingsLogic.keyId(key);
  }

  private hintId(key: KeyDef): string {
    return KeyboardSettingsLogic.hintId(key);
  }

  build() {
    Row() {
      ForEach(this.row.keys, (key: KeyDef, c: number) => {
        KeyButton({
          ghost: key.kind === 'spacer',
          label: this.displayLabel(this.actsAs(c)),
          commitText: this.commitTextFor(this.actsAs(c)),
          bg: this.keyBg(this.actsAs(c)),
          fg: this.keyFg(this.actsAs(c)),
          pressedBg: this.keyPressedBg(this.actsAs(c)),
          fontSize: this.keyFontSize(this.actsAs(c)),
          weight: key.weight,
          kind: this.actsAs(c).kind,
          hasPopups: this.popupsOf(c).length > 0,
          popups: this.popupsOf(c),
          hint: this.hintFor(key),
          hintColor: this.themeColors().hintForeground,
          hintFontSize: this.hintFontSize(),
          keyId: key.kind === 'spacer' ? '' : this.keyId(this.actsAs(c)),
          hintId: this.hintFor(key).length > 0 ? this.hintId(key) : '',
          hapticEnabled: this.prefs.hapticEnabled,
          hapticDurationMs: this.prefs.hapticDurationMs,
          onCommit: (text: string) => this.onCommit(text),
          onAction: () => this.onAction(this.actsAs(c)),
          onDeleteRepeat: () => this.onDeleteRepeat(),
          onShowAccents: (p: string[]) => this.onShowAccents(p),
        })
      }, (key: KeyDef, c: number) => `${this.layerKey}_${this.rowIndex}_${c}`)
    }
    .width('100%')
    .layoutWeight(1)
  }
}

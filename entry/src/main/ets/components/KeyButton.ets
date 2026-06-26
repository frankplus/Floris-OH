/*
 * A single keyboard key. Handles press highlight (onTouch), long-press to open
 * the accent picker (char keys with popups), and hold-to-repeat (backspace).
 * Visual styling is computed by the parent and passed in, so the key stays dumb.
 *
 * Backspace repeat is driven by self-rescheduling setTimeouts (not a
 * LongPressGesture) so the repeat cadence is fully controllable — it starts
 * after a short hold and accelerates from ~75 ms down to ~22 ms per delete.
 */
import vibrator from '@ohos.vibrator';
import { Metrics } from '../model/Theme';

const REPEAT_START_DELAY: number = 320;   // ms hold before delete repeat begins
const REPEAT_INTERVAL_MAX: number = 75;   // first repeat gap (ms)
const REPEAT_INTERVAL_MIN: number = 22;   // fastest repeat gap (ms)
const REPEAT_ACCEL: number = 6;           // shave this many ms off each step
const REPEAT_MAX_COUNT: number = 600;     // runaway guard
const LONGPRESS_DELAY: number = 300;      // ms hold before the accent popup opens

@Component
export struct KeyButton {
  @Prop label: string;
  @Prop commitText: string;
  @Prop bg: string;
  @Prop fg: string;
  @Prop pressedBg: string;
  @Prop fontSize: number;
  @Prop weight: number;
  @Prop kind: string;
  @Prop hasPopups: boolean;
  @Prop hint: string;
  @Prop hintColor: string;
  // Plain (non-reactive) members supplied at construction. Action closures
  // already capture the specific key in the parent, so the child never needs
  // to carry the key model itself (avoids stale plain-member object props).
  popups: string[] = [];
  onCommit: (text: string) => void = () => {};
  onAction: () => void = () => {};
  onDeleteRepeat: () => void = () => {};
  onShowAccents: (popups: string[]) => void = () => {};

  @State pressed: boolean = false;
  private didRepeat: boolean = false;
  private didLongPress: boolean = false;
  private holdTimer: number = -1;     // initial hold delay (repeat start / popup)
  private repeatTimer: number = -1;   // recurring delete
  private repeatDelay: number = REPEAT_INTERVAL_MAX;
  private repeatCount: number = 0;

  private tick(): void {
    try {
      vibrator.startVibration({ type: 'time', duration: 16 }, { usage: 'physicalFeedback' });
    } catch (e) {
      // haptics are best-effort
    }
  }

  private commitOrAct(): void {
    if (this.kind === 'char') {
      this.onCommit(this.commitText);
    } else if (this.kind !== 'spacer') {
      this.onAction();
    }
  }

  private clearTimers(): void {
    if (this.holdTimer !== -1) {
      clearTimeout(this.holdTimer);
      this.holdTimer = -1;
    }
    if (this.repeatTimer !== -1) {
      clearTimeout(this.repeatTimer);
      this.repeatTimer = -1;
    }
  }

  private scheduleDelete(): void {
    this.onDeleteRepeat();
    this.tick();
    this.repeatCount++;
    if (this.repeatCount > REPEAT_MAX_COUNT) {
      this.clearTimers();
      return;
    }
    this.repeatDelay = Math.max(REPEAT_INTERVAL_MIN, this.repeatDelay - REPEAT_ACCEL);
    this.repeatTimer = setTimeout(() => this.scheduleDelete(), this.repeatDelay);
  }

  private startHold(): void {
    if (this.kind === 'delete') {
      this.holdTimer = setTimeout(() => {
        this.didRepeat = true;
        this.repeatDelay = REPEAT_INTERVAL_MAX;
        this.repeatCount = 0;
        this.scheduleDelete();
      }, REPEAT_START_DELAY);
    } else if (this.kind === 'char' && this.hasPopups) {
      this.holdTimer = setTimeout(() => {
        this.didLongPress = true;
        this.onShowAccents(this.popups);
      }, LONGPRESS_DELAY);
    }
  }

  build() {
    Stack({ alignContent: Alignment.TopEnd }) {
      Stack() {
        if (this.kind !== 'spacer') {
          Text(this.label)
            .fontSize(this.fontSize)
            .fontColor(this.fg)
            .maxLines(1)
        }
      }
      .width('100%')
      .height('100%')

      if (this.kind !== 'spacer' && this.hint.length > 0) {
        Text(this.hint)
          .fontSize(Metrics.hintFontSize)
          .fontColor(this.hintColor)
          .maxLines(1)
          .padding({ right: 5, top: 3 })
      }
    }
    .layoutWeight(this.weight)
    .height('100%')
    // Horizontal gap only — the inter-row (vertical) gap is the Column `space` in
    // KeyboardPage. A vertical margin here would overflow the 100%-tall tile, not
    // create a gap (see Metrics.rowGap).
    .margin({ left: Metrics.keyMarginH, right: Metrics.keyMarginH })
    .borderRadius(Metrics.keyCornerRadius)
    .backgroundColor(this.kind === 'spacer' ? Color.Transparent : (this.pressed ? this.pressedBg : this.bg))
    .shadow(this.kind === 'spacer' ? undefined : { radius: 3, color: '#26000000', offsetX: 0, offsetY: 1 })
    .onTouch((event: TouchEvent) => {
      if (this.kind === 'spacer') {
        return;
      }
      switch (event.type) {
        case TouchType.Down:
          this.pressed = true;
          this.didRepeat = false;
          this.didLongPress = false;
          this.clearTimers();
          this.tick();
          this.startHold();
          break;
        case TouchType.Up:
          this.clearTimers();
          this.pressed = false;
          if (!this.didLongPress && !this.didRepeat) {
            this.commitOrAct();
          }
          break;
        case TouchType.Cancel:
          this.clearTimers();
          this.pressed = false;
          break;
        default:
          break;
      }
    })
  }
}

/*
 * A single keyboard key. Handles press highlight (onTouch), long-press to open
 * the accent picker (char keys with popups), and hold-to-repeat (backspace).
 * Visual styling is computed by the parent and passed in, so the key stays dumb.
 *
 * Backspace repeat is driven by self-rescheduling setTimeouts (not a
 * LongPressGesture) so the repeat cadence is fully controllable — it starts
 * after a short hold and accelerates from ~75 ms down to ~22 ms per delete.
 *
 * Three rules keep fast typing from losing keystrokes:
 *
 *  1. Touch state is per finger. Rolling typing puts a second finger on the
 *     board (sometimes on the same key) before the first one lifts, so a single
 *     shared `pressed` / `didLongPress` would let one finger wipe the other's
 *     state and swallow its letter.
 *
 *  2. The component owns its full key pitch and paints a smaller tile inside it
 *     (see Metrics.keyMarginH / rowGapHalf). Gaps drawn with margins or Column
 *     spacing belong to no key, so a tap landing in one is swallowed without a
 *     trace — 27% of the board's surface, and the main reason fast typing lost
 *     letters.
 *
 *  3. How long a key was held is measured from the TouchEvent's own hardware
 *     timestamp, never from when our handler happened to run. The keyboard
 *     shares its thread with the editor round-trip, and a slow editor can stall
 *     us for hundreds of ms; a wall-clock hold timer that expires inside such a
 *     stall would otherwise promote an ordinary 80 ms tap to a long-press and
 *     silently eat the letter. A timer that fires late is therefore ignored and
 *     re-armed, and the Up handler re-decides from the event timestamps.
 */
import vibrator from '@ohos.vibrator';
import { Metrics } from '../model/Theme';

const REPEAT_START_DELAY: number = 320;   // ms hold before delete repeat begins
const REPEAT_INTERVAL_MAX: number = 75;   // first repeat gap (ms)
const REPEAT_INTERVAL_MIN: number = 22;   // fastest repeat gap (ms)
const REPEAT_ACCEL: number = 6;           // shave this many ms off each step
const REPEAT_MAX_COUNT: number = 600;     // runaway guard
const LONGPRESS_DELAY: number = 300;      // ms hold before the accent popup opens
const LATE_TIMER_SLACK: number = 100;     // a timer later than this ran inside a stall
const LATE_TIMER_RETRY: number = 60;      // ...so re-arm it this far out instead
const MOVE_SLOP: number = 20;             // vp of travel still counted as a tap

// One finger currently on this key. `downTs` is the TouchEvent hardware
// timestamp (ns) of its Down — the only clock immune to handler delay.
class FingerState {
  id: number = -1;
  downTs: number = 0;
  dueAt: number = 0;      // ms, when the pending timer was supposed to run
  x0: number = 0;
  y0: number = 0;
  moved: number = 0;
  timer: number = -1;
  longPressed: boolean = false;
  repeated: boolean = false;
  repeatDelay: number = REPEAT_INTERVAL_MAX;
  repeatCount: number = 0;
}

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
  // A ghost key is invisible but still typed: it lets the layout's filler
  // columns act as an extension of the key beside them instead of a dead strip.
  @Prop ghost: boolean;
  // Plain (non-reactive) members supplied at construction. Action closures
  // already capture the specific key in the parent, so the child never needs
  // to carry the key model itself (avoids stale plain-member object props).
  popups: string[] = [];
  onCommit: (text: string) => void = () => {};
  onAction: () => void = () => {};
  onDeleteRepeat: () => void = () => {};
  onShowAccents: (popups: string[]) => void = () => {};

  @State pressed: boolean = false;
  private fingers: FingerState[] = [];

  private tick(): void {
    try {
      vibrator.startVibration({ type: 'time', duration: 16 }, { usage: 'physicalFeedback' })
        .catch(() => {});   // haptics are best-effort; an unhandled rejection would be fatal
    } catch (e) {
      // ditto for a synchronous throw
    }
  }

  private commitOrAct(): void {
    if (this.kind === 'char') {
      this.onCommit(this.commitText);
    } else if (this.kind !== 'spacer') {
      this.onAction();
    }
  }

  private find(id: number): FingerState | undefined {
    for (const f of this.fingers) {
      if (f.id === id) {
        return f;
      }
    }
    return undefined;
  }

  private release(f: FingerState): void {
    if (f.timer !== -1) {
      clearTimeout(f.timer);
      f.timer = -1;
    }
    const rest: FingerState[] = [];
    for (const o of this.fingers) {
      if (o !== f) {
        rest.push(o);
      }
    }
    this.fingers = rest;
    this.pressed = this.fingers.length > 0;
  }

  private arm(f: FingerState, delay: number, run: () => void): void {
    f.dueAt = Date.now() + delay;
    f.timer = setTimeout(run, delay);
  }

  // True when the timer we are running in expired while the thread was blocked:
  // anything queued behind that stall (this finger's Up, most likely) has not
  // been seen yet, so the hold it seems to report never happened.
  private firedLate(f: FingerState): boolean {
    return (Date.now() - f.dueAt) > LATE_TIMER_SLACK;
  }

  private scheduleDelete(f: FingerState): void {
    this.onDeleteRepeat();
    this.tick();
    f.repeatCount++;
    if (f.repeatCount > REPEAT_MAX_COUNT) {
      f.timer = -1;
      return;
    }
    f.repeatDelay = Math.max(REPEAT_INTERVAL_MIN, f.repeatDelay - REPEAT_ACCEL);
    this.arm(f, f.repeatDelay, () => this.onRepeatTick(f));
  }

  private onRepeatTick(f: FingerState): void {
    // Never fire a burst of deletes to "catch up" after a stall — wait for the
    // queue to drain instead, so a released key cannot keep deleting.
    if (this.firedLate(f)) {
      this.arm(f, LATE_TIMER_RETRY, () => this.onRepeatTick(f));
      return;
    }
    this.scheduleDelete(f);
  }

  private startHold(f: FingerState): void {
    if (this.kind === 'delete') {
      this.arm(f, REPEAT_START_DELAY, () => this.onRepeatStart(f));
    } else if (this.kind === 'char' && this.hasPopups) {
      this.arm(f, LONGPRESS_DELAY, () => this.onLongPressTick(f));
    }
  }

  private onRepeatStart(f: FingerState): void {
    if (this.firedLate(f)) {
      this.arm(f, LATE_TIMER_RETRY, () => this.onRepeatStart(f));
      return;
    }
    f.repeated = true;
    f.repeatDelay = REPEAT_INTERVAL_MAX;
    f.repeatCount = 0;
    this.scheduleDelete(f);
  }

  private onLongPressTick(f: FingerState): void {
    if (this.firedLate(f)) {
      this.arm(f, LATE_TIMER_RETRY, () => this.onLongPressTick(f));
      return;
    }
    f.longPressed = true;
    this.onShowAccents(this.popups);
  }

  // The Up/Cancel decision. `heldMs` comes from the two hardware timestamps, so
  // it is the time the finger really spent on the key.
  private finish(f: FingerState, upTs: number, cancelled: boolean): void {
    const heldMs: number = (upTs - f.downTs) / 1000000;
    const wasTap: boolean = heldMs < LONGPRESS_DELAY && f.moved < MOVE_SLOP;
    this.release(f);
    // A cancel is someone else claiming the touch (an edge gesture, a parent
    // scroll). If it was a plain short stab at the key, honour it as a press
    // rather than dropping the letter.
    if (cancelled && !wasTap) {
      return;
    }
    if (wasTap || (!f.longPressed && !f.repeated)) {
      this.commitOrAct();
    }
  }

  build() {
    // Outer box = the key's whole pitch, and the only thing that takes touches.
    // The padding is the inter-key gap; the tile inside it is what you see.
    Stack() {
      Stack({ alignContent: Alignment.TopEnd }) {
        Stack() {
          if (this.kind !== 'spacer' && !this.ghost) {
            Text(this.label)
              .fontSize(this.fontSize)
              .fontColor(this.fg)
              .maxLines(1)
          }
        }
        .width('100%')
        .height('100%')

        if (this.kind !== 'spacer' && !this.ghost && this.hint.length > 0) {
          Text(this.hint)
            .fontSize(Metrics.hintFontSize)
            .fontColor(this.hintColor)
            .maxLines(1)
            .padding({ right: 5, top: 3 })
        }
      }
      .width('100%')
      .height('100%')
      .borderRadius(Metrics.keyCornerRadius)
      .backgroundColor(this.kind === 'spacer' || this.ghost
        ? Color.Transparent
        : (this.pressed ? this.pressedBg : this.bg))
      .shadow(this.kind === 'spacer' || this.ghost
        ? undefined
        : { radius: 3, color: '#26000000', offsetX: 0, offsetY: 1 })
    }
    .layoutWeight(this.weight)
    .height('100%')
    .padding({
      left: Metrics.keyMarginH,
      right: Metrics.keyMarginH,
      top: Metrics.rowGapHalf,
      bottom: Metrics.rowGapHalf,
    })
    .onTouch((event: TouchEvent) => {
      if (this.kind === 'spacer') {
        return;
      }
      const known: boolean = event.changedTouches.length > 0;
      // Fall back to the oldest finger we hold: a lift we cannot match to a
      // press must still produce the keystroke, never nothing.
      const t: TouchObject | undefined = known ? event.changedTouches[0] : undefined;
      const id: number = t !== undefined ? t.id : -1;
      switch (event.type) {
        case TouchType.Down: {
          if (t === undefined) {
            break;
          }
          const f: FingerState = new FingerState();
          f.id = t.id;
          f.downTs = event.timestamp;
          f.x0 = t.x;
          f.y0 = t.y;
          this.fingers.push(f);
          this.pressed = true;
          this.tick();
          this.startHold(f);
          break;
        }
        case TouchType.Move: {
          if (t === undefined) {
            break;
          }
          const f: FingerState | undefined = this.find(t.id);
          if (f !== undefined) {
            const d: number = Math.abs(t.x - f.x0) + Math.abs(t.y - f.y0);
            if (d > f.moved) {
              f.moved = d;
            }
          }
          break;
        }
        case TouchType.Up:
        case TouchType.Cancel: {
          let f: FingerState | undefined = this.find(id);
          if (f === undefined && this.fingers.length > 0) {
            f = this.fingers[0];
          }
          if (f !== undefined) {
            this.finish(f, event.timestamp, event.type === TouchType.Cancel);
          }
          break;
        }
        default:
          break;
      }
    })
  }
}

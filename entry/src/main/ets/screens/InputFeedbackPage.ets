// Screen "InputFeedback": Haptic feedback, under the group 'Haptic feedback / Vibration': 'Enable haptic feedback' on or off (summary when off: 'Never vibrate for input events, regardless of system settings') and 'Vibration duration' (1 to 100 ms, step 1, shown as '50 ms'), disabled while haptic feedback is off; moving the slider plays one vibration of the chosen length as a preview. No sound feedback.
import { AppColors, Radius, Size, Space, Type } from '../theme/Theme';
import { AppBar, SectionHeader, Snackbar, ToggleRow } from '../kit/Kit';
import { SettingsStore } from '../model/SettingsStore';
import { vibrator } from '@kit.SensorServiceKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

@ComponentV2
export struct InputFeedbackPage {
  @Consumer('pathStack') pathStack: NavPathStack = new NavPathStack();
  @Local hapticEnabled: boolean = true;
  @Local hapticDurationMs: number = 50;
  @Local saveFailed: boolean = false;

  aboutToAppear(): void {
    this.reload();
  }

  private reload(): void {
    const prefs = SettingsStore.getInstance().prefs();
    this.hapticEnabled = prefs.hapticEnabled;
    this.hapticDurationMs = prefs.hapticDurationMs;
  }

  private onHapticEnabledChange(isOn: boolean): void {
    this.saveFailed = false;
    this.hapticEnabled = isOn;
    SettingsStore.getInstance().setHapticEnabled(isOn).catch((e: Error) => {
      hilog.error(0x0001, 'InputFeedback', 'setHapticEnabled failed: %{public}s', JSON.stringify(e));
      this.saveFailed = true;
    });
  }

  private onDurationChange(value: number, mode: SliderChangeMode): void {
    const rounded = Math.round(value);
    this.hapticDurationMs = rounded;
    if (mode === SliderChangeMode.Moving) {
      return;
    }
    this.saveFailed = false;
    SettingsStore.getInstance().setHapticDurationMs(rounded).catch((e: Error) => {
      hilog.error(0x0001, 'InputFeedback', 'setHapticDurationMs failed: %{public}s', JSON.stringify(e));
      this.saveFailed = true;
    });
    this.previewVibrate(rounded);
  }

  private previewVibrate(durationMs: number): void {
    try {
      vibrator.startVibration(
        { type: 'time', duration: durationMs },
        { id: 0, usage: 'touch' },
        (error: Error) => {
          if (error) {
            hilog.error(0x0001, 'InputFeedback', 'vibrate failed: %{public}s', JSON.stringify(error));
          }
        }
      );
    } catch (e) {
      hilog.error(0x0001, 'InputFeedback', 'vibrate threw: %{public}s', JSON.stringify(e));
    }
  }

  build() {
    NavDestination() {
      Stack({ alignContent: Alignment.BottomEnd }) {
        Column() {
          AppBar({ title: $r('app.string.title_InputFeedback'), onBack: () => { this.pathStack.pop(); } })
          Scroll() {
            Column({ space: Space.l }) {
              SectionHeader({ title: $r('app.string.input_feedback__group_haptic') })
              Column() {
                ToggleRow({
                  title: $r('app.string.input_feedback__haptic_enabled_title'),
                  subtitle: this.hapticEnabled ? '' : $r('app.string.input_feedback__haptic_enabled_summary_disabled'),
                  isOn: this.hapticEnabled,
                  eid: 'haptic_enabled',
                  onChange: (isOn: boolean) => { this.onHapticEnabledChange(isOn); },
                })
                Divider().color(AppColors.divider).margin({ left: Space.l })
                Column({ space: Space.s }) {
                  Row() {
                    Text($r('app.string.input_feedback__haptic_duration_title'))
                      .fontSize(Type.body)
                      .fontColor(AppColors.textPrimary)
                      .layoutWeight(1)
                    Text(SettingsStore.getInstance().durationText(this.hapticDurationMs))
                      .id('haptic_duration_value')
                      .fontSize(Type.body)
                      .fontColor(this.hapticEnabled ? AppColors.textSecondary : AppColors.textTertiary)
                      .textAlign(TextAlign.End)
                      .constraintSize({ minHeight: Size.icon })
                  }
                  .width('100%')
                  .constraintSize({ minHeight: Size.icon })

                  Slider({
                    value: this.hapticDurationMs,
                    min: 1,
                    max: 100,
                    step: 1,
                  })
                    .id('haptic_duration_slider')
                    .enabled(this.hapticEnabled)
                    .width('100%')
                    .onChange((value: number, mode: SliderChangeMode) => { this.onDurationChange(value, mode); })
                }
                .width('100%')
                .padding({ left: Space.l, right: Space.l, top: Space.m, bottom: Space.m })
              }
              .width('100%')
              .backgroundColor(AppColors.surface)
              .borderRadius(Radius.l)
            }
            .width('100%')
            .padding({ left: Space.l, right: Space.l, top: Space.l, bottom: Space.l })
          }
          .align(Alignment.Top)
          .layoutWeight(1)
          .width('100%')
        }
        .width('100%')
        .height('100%')
        if (this.saveFailed) {
          Snackbar({
            message: $r('app.string.input_feedback__save_error'),
            eid: 'input_feedback_save_error',
            lifted: false,
          })
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor(AppColors.background)
    }
    .hideTitleBar(true)
    .id('page_InputFeedback')
  }
}

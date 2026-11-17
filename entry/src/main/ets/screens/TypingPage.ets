// Screen "Typing": Typing corrections: 'Auto-capitalization' ('Capitalize words based on the current input context') and 'Double-space period' ('Tapping twice on spacebar inserts a period followed by a space'), each a switch, saved at once.
// Keep the root id 'page_Typing', the pathStack consumer and this frame (Stack > Column > AppBar, then
// the content): the factory's walker and the navigation host rely on them. Dialogs and a floating button go
// last in the Stack. Push other screens with this.pathStack.pushPathByName(<name>, <string param>).
import { AppColors, Radius, Space } from '../theme/Theme';
import { AppBar, SectionHeader, ToggleRow } from '../kit/Kit';
import { SettingsStore } from '../model/SettingsStore';
import { hilog } from '@kit.PerformanceAnalysisKit';

@ComponentV2
export struct TypingPage {
  @Consumer('pathStack') pathStack: NavPathStack = new NavPathStack();
  @Local autoCapitalization: boolean = true;
  @Local doubleSpacePeriod: boolean = true;

  reload(): void {
    const prefs = SettingsStore.getInstance().prefs();
    this.autoCapitalization = prefs.autoCapitalization;
    this.doubleSpacePeriod = prefs.doubleSpacePeriod;
  }

  aboutToAppear(): void {
    this.reload();
  }

  async onAutoCapitalizationChange(value: boolean): Promise<void> {
    this.autoCapitalization = value;
    try {
      await SettingsStore.getInstance().setAutoCapitalization(value);
    } catch (e) {
      hilog.error(0x0001, 'TypingPage', 'setAutoCapitalization failed: %{public}s', JSON.stringify(e));
      this.autoCapitalization = !value;
      this.getUIContext().getPromptAction().showToast({ message: $r('app.string.error_setting_save_failed') });
    }
  }

  async onDoubleSpacePeriodChange(value: boolean): Promise<void> {
    this.doubleSpacePeriod = value;
    try {
      await SettingsStore.getInstance().setDoubleSpacePeriod(value);
    } catch (e) {
      hilog.error(0x0001, 'TypingPage', 'setDoubleSpacePeriod failed: %{public}s', JSON.stringify(e));
      this.doubleSpacePeriod = !value;
      this.getUIContext().getPromptAction().showToast({ message: $r('app.string.error_setting_save_failed') });
    }
  }

  build() {
    NavDestination() {
      Stack({ alignContent: Alignment.BottomEnd }) {
        Column() {
          AppBar({ title: $r('app.string.title_Typing'), onBack: () => { this.pathStack.pop(); } })
          Scroll() {
            Column({ space: Space.m }) {
              SectionHeader({ title: $r('app.string.section_typing_corrections') })
              Column() {
                ToggleRow({
                  title: $r('app.string.label_auto_capitalization'),
                  subtitle: $r('app.string.summary_auto_capitalization'),
                  isOn: this.autoCapitalization,
                  eid: 'auto_capitalization',
                  onChange: (isOn: boolean) => { this.onAutoCapitalizationChange(isOn); }
                })
                Divider().color(AppColors.divider).margin({ left: Space.l })
                ToggleRow({
                  title: $r('app.string.label_double_space_period'),
                  subtitle: $r('app.string.summary_double_space_period'),
                  isOn: this.doubleSpacePeriod,
                  eid: 'double_space_period',
                  onChange: (isOn: boolean) => { this.onDoubleSpacePeriodChange(isOn); }
                })
              }
              .width('100%')
              .backgroundColor(AppColors.surface)
              .borderRadius(Radius.l)
            }
            .width('100%')
            .padding(Space.l)
            .align(Alignment.Top)
          }
          .align(Alignment.Top)
          .layoutWeight(1)
          .width('100%')
        }
        .width('100%')
        .height('100%')
      }
      .width('100%')
      .height('100%')
      .backgroundColor(AppColors.background)
    }
    .hideTitleBar(true)
    .onShown(() => { this.reload(); })
    .id('page_Typing')
  }
}

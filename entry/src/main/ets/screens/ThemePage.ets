// Screen "Theme": The keyboard's theme mode, under 'Theme mode': one radio row each for 'Follow system', 'Always day' and 'Always night' (Floris Day and Floris Night named in the summaries); the choice is saved at once.
import { AppColors, Space, Type } from '../theme/Theme';
import { AppBar, SectionHeader, Snackbar } from '../kit/Kit';
import { SettingsStore } from '../model/SettingsStore';
import { hilog } from '@kit.PerformanceAnalysisKit';

@ComponentV2
export struct ThemePage {
  @Consumer('pathStack') pathStack: NavPathStack = new NavPathStack();
  @Local themeMode: string = 'follow_system';
  @Local showError: boolean = false;
  @Local errorMessage: ResourceStr = $r('app.string.theme_save_error');

  aboutToAppear(): void {
    this.themeMode = SettingsStore.getInstance().prefs().themeMode;
  }

  async selectMode(mode: string): Promise<void> {
    this.showError = false;
    const previous = this.themeMode;
    this.themeMode = mode;
    try {
      await SettingsStore.getInstance().setThemeMode(mode);
    } catch (e) {
      hilog.error(0x0001, 'ThemePage', 'setThemeMode failed: %{public}s', JSON.stringify(e));
      this.themeMode = previous;
      this.errorMessage = $r('app.string.theme_save_error');
      this.showError = true;
    }
  }

  build() {
    NavDestination() {
      Stack({ alignContent: Alignment.BottomEnd }) {
        Column() {
          AppBar({ title: $r('app.string.title_Theme'), onBack: () => { this.pathStack.pop(); } })
          Scroll() {
            Column() {
              SectionHeader({ title: $r('app.string.group_theme_mode') })
              Column() {
                Row() {
                  Column() {
                    Text(SettingsStore.getInstance().themeModeName('follow_system'))
                      .fontSize(Type.body)
                      .fontColor(AppColors.textPrimary)
                      .width('100%')
                      .constraintSize({ minHeight: 24 })
                    Text($r('app.string.theme_summary_follow_system'))
                      .fontSize(Type.secondary)
                      .fontColor(AppColors.textSecondary)
                      .width('100%')
                  }
                  .alignItems(HorizontalAlign.Start)
                  .layoutWeight(1)
                  Radio({ value: 'follow_system', group: 'theme_mode' })
                    .radioStyle({ checkedBackgroundColor: AppColors.brand })
                    .checked(this.themeMode === 'follow_system')
                    .id('theme_mode_follow_system')
                    .onChange((c: boolean) => { if (c) { this.selectMode('follow_system'); } })
                }
                .width('100%')
                .padding(Space.l)
                .onClick(() => { this.selectMode('follow_system'); })
                Divider().color(AppColors.divider).margin({ left: Space.l })
                Row() {
                  Column() {
                    Text(SettingsStore.getInstance().themeModeName('always_day'))
                      .fontSize(Type.body)
                      .fontColor(AppColors.textPrimary)
                      .width('100%')
                      .constraintSize({ minHeight: 24 })
                    Text($r('app.string.theme_summary_always_day'))
                      .fontSize(Type.secondary)
                      .fontColor(AppColors.textSecondary)
                      .width('100%')
                  }
                  .alignItems(HorizontalAlign.Start)
                  .layoutWeight(1)
                  Radio({ value: 'always_day', group: 'theme_mode' })
                    .radioStyle({ checkedBackgroundColor: AppColors.brand })
                    .checked(this.themeMode === 'always_day')
                    .id('theme_mode_always_day')
                    .onChange((c: boolean) => { if (c) { this.selectMode('always_day'); } })
                }
                .width('100%')
                .padding(Space.l)
                .onClick(() => { this.selectMode('always_day'); })
                Divider().color(AppColors.divider).margin({ left: Space.l })
                Row() {
                  Column() {
                    Text(SettingsStore.getInstance().themeModeName('always_night'))
                      .fontSize(Type.body)
                      .fontColor(AppColors.textPrimary)
                      .width('100%')
                      .constraintSize({ minHeight: 24 })
                    Text($r('app.string.theme_summary_always_night'))
                      .fontSize(Type.secondary)
                      .fontColor(AppColors.textSecondary)
                      .width('100%')
                  }
                  .alignItems(HorizontalAlign.Start)
                  .layoutWeight(1)
                  Radio({ value: 'always_night', group: 'theme_mode' })
                    .radioStyle({ checkedBackgroundColor: AppColors.brand })
                    .checked(this.themeMode === 'always_night')
                    .id('theme_mode_always_night')
                    .onChange((c: boolean) => { if (c) { this.selectMode('always_night'); } })
                }
                .width('100%')
                .padding(Space.l)
                .onClick(() => { this.selectMode('always_night'); })
              }
              .backgroundColor(AppColors.surface)
              .borderRadius(Space.m)
              .margin({ left: Space.l, right: Space.l, top: Space.s })
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)
          }
          .align(Alignment.Top)
          .layoutWeight(1)
          .width('100%')
        }
        .width('100%')
        .height('100%')
        .backgroundColor(AppColors.background)

        if (this.showError) {
          Snackbar({
            message: this.errorMessage,
            eid: 'theme_error_snackbar',
            lifted: false,
          })
        }
      }
      .width('100%')
      .height('100%')
    }
    .hideTitleBar(true)
    .onShown(() => { this.themeMode = SettingsStore.getInstance().prefs().themeMode; })
    .id('page_Theme')
  }
}

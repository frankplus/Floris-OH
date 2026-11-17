// Screen "Localization": FlorisBoard's localization screen reduced to one subtype: under the group 'Subtypes', the subtype English, and below it the characters layout to use, one radio row each for QWERTY, QWERTZ and AZERTY; the summary of the subtype row reads 'English (QWERTY)' with the chosen layout.
// Keep the root id 'page_Localization', the pathStack consumer and this frame (Stack > Column > AppBar, then
// the content): the factory's walker and the navigation host rely on them. Dialogs and a floating button go
// last in the Stack. Push other screens with this.pathStack.pushPathByName(<name>, <string param>).
import { AppColors, Radius, Size, Space, Type } from '../theme/Theme';
import { AppBar, ListRow, SectionHeader, Snackbar } from '../kit/Kit';
import { SettingsStore } from '../model/SettingsStore';
import { hilog } from '@kit.PerformanceAnalysisKit';

@ComponentV2
export struct LocalizationPage {
  @Consumer('pathStack') pathStack: NavPathStack = new NavPathStack();
  @Local layout: string = 'qwerty';
  @Local showError: boolean = false;

  reload(): void {
    const prefs = SettingsStore.getInstance().prefs();
    this.layout = prefs.layout;
  }

  async selectLayout(layout: string): Promise<void> {
    this.showError = false;
    const previous = this.layout;
    this.layout = layout;
    try {
      await SettingsStore.getInstance().setLayout(layout);
    } catch (e) {
      hilog.error(0x0001, 'Localization', 'setLayout failed: %{public}s', JSON.stringify(e));
      this.layout = previous;
      this.showError = true;
    }
  }

  build() {
    NavDestination() {
      Stack({ alignContent: Alignment.BottomEnd }) {
        Column() {
          AppBar({ title: $r('app.string.title_Localization'), onBack: () => { this.pathStack.pop(); } })
          Column({ space: Space.l }) {
            SectionHeader({ title: $r('app.string.group_subtypes') })
            Column() {
              ListRow({
                title: $r('app.string.subtype_name_english'),
                subtitle: SettingsStore.getInstance().spaceBarLabel(this.layout),
                eid: 'subtype_english'
              })
            }
            .width('100%')
            .backgroundColor(AppColors.surface)
            .borderRadius(Radius.l)
            SectionHeader({ title: $r('app.string.group_layout') })
            Column() {
              ForEach(SettingsStore.getInstance().layouts(), (layoutOption: string, index: number) => {
                if (index > 0) {
                  Divider().color(AppColors.divider).margin({ left: Space.l })
                }
                Row() {
                  Text(SettingsStore.getInstance().layoutName(layoutOption))
                    .fontSize(Type.body)
                    .fontColor(AppColors.textPrimary)
                    .layoutWeight(1)
                  Radio({ value: layoutOption, group: 'layout' })
                    .checked(this.layout === layoutOption)
                    .id('layout_' + layoutOption)
                    .onChange((isChecked: boolean) => {
                      if (isChecked) {
                        this.selectLayout(layoutOption);
                      }
                    })
                }
                .width('100%')
                .height(Size.row)
                .padding({ left: Space.l, right: Space.l })
                .alignItems(VerticalAlign.Center)
                .onClick(() => { this.selectLayout(layoutOption); })
              }, (layoutOption: string) => layoutOption)
            }
            .width('100%')
            .backgroundColor(AppColors.surface)
            .borderRadius(Radius.l)
          }
          .width('100%')
          .padding({ left: Space.l, right: Space.l, top: Space.l })
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
        }
        .width('100%')
        .height('100%')
        if (this.showError) {
          Snackbar({
            message: $r('app.string.localization_save_failed'),
            eid: 'localization_save_error',
            lifted: false
          })
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor(AppColors.background)
    }
    .hideTitleBar(true)
    .onShown(() => { this.reload(); })
    .id('page_Localization')
  }
}

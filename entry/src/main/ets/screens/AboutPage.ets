// Screen "About": What the app is: the app icon and name FlorisBoard, the version (the bundle's versionName, read with bundleManager), 'Project license' with 'FlorisBoard is licensed under Apache-2.0', 'Repository (GitHub)' with https://github.com/florisboard/florisboard, and 'FlorisBoard for OpenHarmony' naming this port. Rows only show text.
// Keep the root id 'page_About', the pathStack consumer and this frame (Stack > Column > AppBar, then
// the content): the factory's walker and the navigation host rely on them. Dialogs and a floating button go
// last in the Stack. Push other screens with this.pathStack.pushPathByName(<name>, <string param>).
import { AppColors, Radius, Space, Type } from '../theme/Theme';
import { AppBar, ListRow } from '../kit/Kit';
import { bundleManager } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

@ComponentV2
export struct AboutPage {
  @Consumer('pathStack') pathStack: NavPathStack = new NavPathStack();
  @Local versionText: string = '';

  aboutToAppear(): void {
    this.loadVersion();
  }

  private loadVersion(): void {
    try {
      const info = bundleManager.getBundleInfoForSelfSync(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);
      this.versionText = info.versionName;
    } catch (e) {
      hilog.error(0x0001, 'About', 'load version failed: %{public}s', JSON.stringify(e));
      this.versionText = '0.0.0';
    }
  }

  build() {
    NavDestination() {
      Stack({ alignContent: Alignment.BottomEnd }) {
        Column() {
          AppBar({ title: $r('app.string.title_About'), onBack: () => { this.pathStack.pop(); } })
          Scroll() {
            Column({ space: Space.l }) {
              Column({ space: Space.m }) {
                Image($r('app.media.startIcon'))
                  .width(72)
                  .height(72)
                  .borderRadius(Radius.m)
                  .objectFit(ImageFit.Cover)
                Text($r('app.string.EntryAbility_label'))
                  .id('about_app_name')
                  .fontSize(Type.title)
                  .fontColor(AppColors.textPrimary)
                  .fontWeight(FontWeight.Medium)
                  .width('100%')
                  .textAlign(TextAlign.Center)
                  .constraintSize({ minHeight: 24 })
              }
              .width('100%')
              .alignItems(HorizontalAlign.Center)
              .padding({ top: Space.l, bottom: Space.s })

              Column() {
                ListRow({
                  title: $r('app.string.about__version_title'),
                  value: this.versionText,
                  eid: 'about_version_row',
                  valueId: 'about_version',
                })
                Divider().color(AppColors.divider).margin({ left: Space.l })
                ListRow({
                  title: $r('app.string.about__license_title'),
                  subtitle: $r('app.string.about__license_summary'),
                  eid: 'about_license_row',
                  subtitleId: 'about_license',
                })
                Divider().color(AppColors.divider).margin({ left: Space.l })
                ListRow({
                  title: $r('app.string.about__repository_title'),
                  subtitle: $r('app.string.about__repository_value'),
                  eid: 'about_repository_row',
                  subtitleId: 'about_repository',
                })
                Divider().color(AppColors.divider).margin({ left: Space.l })
                ListRow({
                  title: $r('app.string.about__port_title'),
                  eid: 'about_port_row',
                  titleId: 'about_port',
                })
              }
              .width('100%')
              .backgroundColor(AppColors.surface)
              .borderRadius(Radius.l)
            }
            .width('100%')
            .padding({ left: Space.l, right: Space.l, bottom: Space.l })
          }
          .align(Alignment.Top)
          .layoutWeight(1)
        }
        .width('100%')
        .height('100%')
      }
      .width('100%')
      .height('100%')
      .backgroundColor(AppColors.background)
    }
    .hideTitleBar(true)
    .id('page_About')
  }
}

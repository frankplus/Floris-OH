// Screen "Home": FlorisBoard's settings home merged with the base's setup page: a status card saying whether FlorisBoard is enabled and selected as the input method, a button that opens the system's input-method picker, a text field to try the keyboard in, and one row per settings screen (Languages & Layouts, Theme, Keyboard, Typing, About) in FlorisBoard's order. No back arrow in the app bar.
import { AppColors, Radius, Space, Type } from '../theme/Theme';
import { AppBar, ListRow, PrimaryButton, TextField } from '../kit/Kit';
import { BackBridge, HomeShown } from '../common/BackBridge';
import { inputMethod } from '@kit.IMEKit';
import type InputMethodSubtype from '@ohos.InputMethodSubtype';
import { window } from '@kit.ArkUI';
import type { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const BUNDLE_NAME: string = 'dev.patrickgold.florisboard';

type ImeStatus = 'checking' | 'not_enabled' | 'not_selected' | 'enabled_selected' | 'error';

@ComponentV2
export struct HomePage {
  @Consumer('pathStack') pathStack: NavPathStack = new NavPathStack();
  @Local imeStatus: ImeStatus = 'checking';
  @Local previewText: string = '';
  private imeChangeListener: ((p: inputMethod.InputMethodProperty, s: InputMethodSubtype) => void) | null = null;
  private windowObj: window.Window | null = null;
  private windowEventListener: ((event: window.WindowEventType) => void) | null = null;

  aboutToAppear(): void {
    HomeShown.set(() => { this.refreshStatus(); });
    BackBridge.set(null);
    this.refreshStatus();
    this.subscribeImeChange();
    this.subscribeWindowEvent();
  }

  aboutToDisappear(): void {
    HomeShown.set(null);
    this.unsubscribeImeChange();
    this.unsubscribeWindowEvent();
  }

  private subscribeImeChange(): void {
    try {
      this.imeChangeListener = (): void => { this.refreshStatus(); };
      inputMethod.getSetting().on('imeChange', this.imeChangeListener);
    } catch (e) {
      hilog.error(0x0001, 'HomePage', 'subscribeImeChange failed: %{public}s', JSON.stringify(e));
    }
  }

  private unsubscribeImeChange(): void {
    try {
      if (this.imeChangeListener) {
        inputMethod.getSetting().off('imeChange', this.imeChangeListener);
        this.imeChangeListener = null;
      }
    } catch (e) {
      hilog.error(0x0001, 'HomePage', 'unsubscribeImeChange failed: %{public}s', JSON.stringify(e));
    }
  }

  private subscribeWindowEvent(): void {
    try {
      const ctx: Context = this.getUIContext().getHostContext() as Context;
      window.getLastWindow(ctx, (err: BusinessError, data: window.Window) => {
        if (err && err.code) {
          hilog.error(0x0001, 'HomePage', 'getLastWindow failed: %{public}s', JSON.stringify(err));
          return;
        }
        this.windowObj = data;
        this.windowEventListener = (event: window.WindowEventType): void => {
          if (event === window.WindowEventType.WINDOW_ACTIVE || event === window.WindowEventType.WINDOW_SHOWN) {
            this.refreshStatus();
          }
        };
        this.windowObj.on('windowEvent', this.windowEventListener);
      });
    } catch (e) {
      hilog.error(0x0001, 'HomePage', 'subscribeWindowEvent failed: %{public}s', JSON.stringify(e));
    }
  }

  private unsubscribeWindowEvent(): void {
    try {
      if (this.windowObj && this.windowEventListener) {
        this.windowObj.off('windowEvent', this.windowEventListener);
      }
      this.windowObj = null;
      this.windowEventListener = null;
    } catch (e) {
      hilog.error(0x0001, 'HomePage', 'unsubscribeWindowEvent failed: %{public}s', JSON.stringify(e));
    }
  }

  private refreshStatus(): void {
    this.imeStatus = 'checking';
    try {
      inputMethod.getSetting().getInputMethods(true)
        .then((list: Array<inputMethod.InputMethodProperty>) => {
          const enabled: boolean = list.some((p: inputMethod.InputMethodProperty) => p.name === BUNDLE_NAME);
          if (!enabled) {
            this.imeStatus = 'not_enabled';
            return;
          }
          try {
            const current: inputMethod.InputMethodProperty = inputMethod.getCurrentInputMethod();
            this.imeStatus = current.name === BUNDLE_NAME ? 'enabled_selected' : 'not_selected';
          } catch (e) {
            hilog.error(0x0001, 'HomePage', 'getCurrentInputMethod failed: %{public}s', JSON.stringify(e));
            this.imeStatus = 'error';
          }
        })
        .catch((err: BusinessError) => {
          hilog.error(0x0001, 'HomePage', 'getInputMethods failed: %{public}s', JSON.stringify(err));
          this.imeStatus = 'error';
        });
    } catch (e) {
      hilog.error(0x0001, 'HomePage', 'refreshStatus failed: %{public}s', JSON.stringify(e));
      this.imeStatus = 'error';
    }
  }

  private openImePicker(): void {
    try {
      inputMethod.getSetting().showOptionalInputMethods()
        .then(() => {
          this.refreshStatus();
        })
        .catch((err: BusinessError) => {
          hilog.error(0x0001, 'HomePage', 'showOptionalInputMethods failed: %{public}s', JSON.stringify(err));
          this.refreshStatus();
        });
    } catch (e) {
      hilog.error(0x0001, 'HomePage', 'openImePicker failed: %{public}s', JSON.stringify(e));
      this.refreshStatus();
    }
  }

  private statusText(): ResourceStr {
    if (this.imeStatus === 'not_enabled') {
      return $r('app.string.home_ime_not_enabled');
    } else if (this.imeStatus === 'not_selected') {
      return $r('app.string.home_ime_not_selected');
    } else if (this.imeStatus === 'enabled_selected') {
      return $r('app.string.home_ime_enabled_selected');
    } else if (this.imeStatus === 'error') {
      return $r('app.string.home_ime_read_error');
    }
    return $r('app.string.home_ime_checking');
  }

  private statusTextColor(): ResourceColor {
    if (this.imeStatus === 'not_enabled' || this.imeStatus === 'error') {
      return AppColors.onDanger;
    } else if (this.imeStatus === 'not_selected') {
      return $r('app.color.home_warning_text');
    }
    return AppColors.textPrimary;
  }

  private statusBgColor(): ResourceColor {
    if (this.imeStatus === 'not_enabled' || this.imeStatus === 'error') {
      return AppColors.danger;
    } else if (this.imeStatus === 'not_selected') {
      return $r('app.color.home_warning_bg');
    }
    return AppColors.surface;
  }

  @Builder
  statusCard() {
    Column() {
      Text(this.statusText())
        .id('ime_status')
        .fontSize(Type.body)
        .fontColor(this.statusTextColor())
        .width('100%')
        .constraintSize({ minHeight: 24 })
    }
    .width('100%')
    .padding(Space.l)
    .borderRadius(Radius.l)
    .backgroundColor(this.statusBgColor())
    .onClick(() => { this.openImePicker(); })
  }

  @Builder
  navRows() {
    Column() {
      ListRow({
        title: $r('app.string.title_Localization'),
        chevron: true,
        eid: 'open_localization',
        onTap: () => { this.pathStack.pushPathByName('Localization', ''); },
      })
      Divider().color(AppColors.divider).margin({ left: Space.l })
      ListRow({
        title: $r('app.string.title_Theme'),
        chevron: true,
        eid: 'open_theme',
        onTap: () => { this.pathStack.pushPathByName('Theme', ''); },
      })
      Divider().color(AppColors.divider).margin({ left: Space.l })
      ListRow({
        title: $r('app.string.title_Keyboard'),
        chevron: true,
        eid: 'open_keyboard',
        onTap: () => { this.pathStack.pushPathByName('Keyboard', ''); },
      })
      Divider().color(AppColors.divider).margin({ left: Space.l })
      ListRow({
        title: $r('app.string.title_Typing'),
        chevron: true,
        eid: 'open_typing',
        onTap: () => { this.pathStack.pushPathByName('Typing', ''); },
      })
      Divider().color(AppColors.divider).margin({ left: Space.l })
      ListRow({
        title: $r('app.string.title_About'),
        chevron: true,
        eid: 'open_about',
        onTap: () => { this.pathStack.pushPathByName('About', ''); },
      })
    }
    .width('100%')
    .backgroundColor(AppColors.surface)
    .borderRadius(Radius.l)
  }

  build() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      Column() {
        AppBar({ title: $r('app.string.title_Home'), showBack: false })
        Scroll() {
          Column({ space: Space.l }) {
            this.statusCard()
            PrimaryButton({
              label: $r('app.string.home_choose_keyboard'),
              eid: 'choose_keyboard',
              onTap: () => { this.openImePicker(); },
            })
            TextField({
              label: $r('app.string.home_preview_label'),
              text: this.previewText,
              placeholder: $r('app.string.home_preview_placeholder'),
              eid: 'preview_field',
              onChange: (value: string) => { this.previewText = value; },
            })
            this.navRows()
          }
          .width('100%')
          .padding(Space.l)
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
    .id('page_Home')
  }
}

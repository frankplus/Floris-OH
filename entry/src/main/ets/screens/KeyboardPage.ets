// Screen "Keyboard": The keyboard's look and size: the number row on or off ('Number row', 'Show a number row above the character layout'), hint symbols on the keys on or off ('Hinted symbols'), the font size multiplier (50% to 150%, step 5) and, under the group 'Layout', the keyboard height (50% to 150%, step 5); under the group 'Key press', a row 'Sounds & Vibration' that opens the input feedback screen. Changes are saved at once.
// Keep the root id 'page_Keyboard', the pathStack consumer and this frame (Stack > Column > AppBar, then
// the content): the factory's walker and the navigation host rely on them. Dialogs and a floating button go
// last in the Stack. Push other screens with this.pathStack.pushPathByName(<name>, <string param>).
import { AppColors, Radius, Space } from '../theme/Theme';
import { AppBar, ListRow, SectionHeader, ToggleRow } from '../kit/Kit';
import { SliderSettingRow } from '../components/keyboard/SliderSettingRow';
import { SettingsStore } from '../model/SettingsStore';
import { hilog } from '@kit.PerformanceAnalysisKit';

@ComponentV2
export struct KeyboardPage {
  @Consumer('pathStack') pathStack: NavPathStack = new NavPathStack();
  private store: SettingsStore = SettingsStore.getInstance();
  @Local numberRow: boolean = false;
  @Local hintedSymbols: boolean = true;
  @Local fontSizePercent: number = 100;
  @Local heightPercent: number = 100;

  load(): void {
    const prefs = this.store.prefs();
    this.numberRow = prefs.numberRow;
    this.hintedSymbols = prefs.hintedSymbols;
    this.fontSizePercent = prefs.fontSizePercent;
    this.heightPercent = prefs.heightPercent;
  }

  reportSaveFailed(action: string, e: Error): void {
    hilog.error(0x0001, 'KeyboardPage', '%{public}s failed: %{public}s', action, JSON.stringify(e));
    this.getUIContext().getPromptAction().showToast({ message: $r('app.string.keyboard_save_failed') });
  }

  onNumberRowChange(isOn: boolean): void {
    this.numberRow = isOn;
    this.store.setNumberRow(isOn).catch((e: Error) => { this.reportSaveFailed('setNumberRow', e); });
  }

  onHintedSymbolsChange(isOn: boolean): void {
    this.hintedSymbols = isOn;
    this.store.setHintedSymbols(isOn).catch((e: Error) => { this.reportSaveFailed('setHintedSymbols', e); });
  }

  commitFontSize(value: number): void {
    this.store.setFontSizePercent(value).catch((e: Error) => { this.reportSaveFailed('setFontSizePercent', e); });
  }

  commitHeight(value: number): void {
    this.store.setHeightPercent(value).catch((e: Error) => { this.reportSaveFailed('setHeightPercent', e); });
  }

  build() {
    NavDestination() {
      Stack({ alignContent: Alignment.BottomEnd }) {
        Column() {
          AppBar({ title: $r('app.string.title_Keyboard'), onBack: () => { this.pathStack.pop(); } })
          Scroll() {
            Column({ space: Space.l }) {
              Column() {
                ToggleRow({
                  title: $r('app.string.keyboard_number_row_title'),
                  subtitle: $r('app.string.keyboard_number_row_subtitle'),
                  isOn: this.numberRow,
                  eid: 'number_row',
                  onChange: (isOn: boolean) => { this.onNumberRowChange(isOn); }
                })
                Divider().color(AppColors.divider).margin({ left: Space.l })
                ToggleRow({
                  title: $r('app.string.keyboard_hinted_symbols_title'),
                  isOn: this.hintedSymbols,
                  eid: 'hinted_symbols',
                  onChange: (isOn: boolean) => { this.onHintedSymbolsChange(isOn); }
                })
              }
              .width('100%')
              .backgroundColor(AppColors.surface)
              .borderRadius(Radius.l)

              SliderSettingRow({
                title: $r('app.string.keyboard_font_size_title'),
                value: this.fontSizePercent,
                min: 50,
                max: 150,
                step: 5,
                sliderId: 'font_size_slider',
                valueId: 'font_size_value',
                onLiveChange: (v: number) => { this.fontSizePercent = v; },
                onCommit: (v: number) => { this.commitFontSize(v); }
              })

              SectionHeader({ title: $r('app.string.group_layout') })
              SliderSettingRow({
                title: $r('app.string.keyboard_height_title'),
                value: this.heightPercent,
                min: 50,
                max: 150,
                step: 5,
                sliderId: 'height_slider',
                valueId: 'height_value',
                onLiveChange: (v: number) => { this.heightPercent = v; },
                onCommit: (v: number) => { this.commitHeight(v); }
              })

              SectionHeader({ title: $r('app.string.group_key_press') })
              Column() {
                ListRow({
                  title: $r('app.string.title_InputFeedback'),
                  chevron: true,
                  eid: 'open_input_feedback',
                  onTap: () => { this.pathStack.pushPathByName('InputFeedback', ''); }
                })
              }
              .width('100%')
              .backgroundColor(AppColors.surface)
              .borderRadius(Radius.l)
            }
            .width('100%')
            .padding(Space.l)
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
    .onShown(() => { this.load(); })
    .id('page_Keyboard')
  }
}

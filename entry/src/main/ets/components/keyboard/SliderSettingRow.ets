// A labelled slider row shared by Keyboard's font-size and height settings: a title and the
// current percentage on one line, the slider below. The value shown tracks the parent's state
// (passed in as @Param) so dragging stays live while only the committed value (on End/Click) is
// written to storage by the parent's onCommit handler.
import { AppColors, Radius, Space, Type } from '../../theme/Theme';
import { SettingsStore } from '../../model/SettingsStore';

@ComponentV2
export struct SliderSettingRow {
  @Param title: ResourceStr = '';
  @Param value: number = 100;
  @Param min: number = 50;
  @Param max: number = 150;
  @Param step: number = 5;
  @Param sliderId: string = '';
  @Param valueId: string = '';
  @Event onLiveChange: (value: number) => void = () => {};
  @Event onCommit: (value: number) => void = () => {};

  build() {
    Column({ space: Space.xs }) {
      Row() {
        Text(this.title)
          .fontSize(Type.body)
          .fontColor(AppColors.textPrimary)
          .layoutWeight(1)
        Text(SettingsStore.getInstance().percentText(Math.round(this.value)))
          .id(this.valueId)
          .fontSize(Type.body)
          .fontColor(AppColors.textSecondary)
          .textAlign(TextAlign.End)
          .constraintSize({ minHeight: 24 })
      }
      .width('100%')

      Slider({ value: this.value, min: this.min, max: this.max, step: this.step })
        .id(this.sliderId)
        .width('100%')
        .onChange((value: number, mode: SliderChangeMode) => {
          this.onLiveChange(value);
          if (mode === SliderChangeMode.End || mode === SliderChangeMode.Click) {
            this.onCommit(value);
          }
        })
    }
    .width('100%')
    .padding(Space.l)
    .backgroundColor(AppColors.surface)
    .borderRadius(Radius.l)
  }
}

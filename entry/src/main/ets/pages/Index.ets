/*
 * Host / setup screen for FlorisBoard-OHOS. Lets the user enable & choose the
 * keyboard (via the system optional-IME dialog) and test typing.
 */
import inputMethod from '@ohos.inputMethod';
import { BusinessError } from '@ohos.base';

const BUNDLE: string = 'dev.patrickgold.florisboard';

@Entry
@Component
struct Index {
  @State status: string = 'Checking…';
  @State imeEnabled: boolean = false;
  @State testText: string = '';

  aboutToAppear(): void {
    this.refreshStatus();
  }

  private refreshStatus(): void {
    try {
      inputMethod.getSetting().getInputMethods(true)
        .then((list: Array<inputMethod.InputMethodProperty>) => {
          const found: boolean = list.some((p: inputMethod.InputMethodProperty) => p.name === BUNDLE);
          this.imeEnabled = found;
          this.status = found ? 'FlorisBoard is enabled ✓' : 'FlorisBoard is not enabled yet';
        })
        .catch((err: BusinessError) => {
          this.status = `Could not read IME list (${err.code})`;
        });
    } catch (e) {
      const err = e as BusinessError;
      this.status = `Error: ${err.code}`;
    }
  }

  private openImePicker(): void {
    try {
      inputMethod.getSetting().showOptionalInputMethods()
        .then(() => {
          setTimeout(() => this.refreshStatus(), 800);
        })
        .catch((err: BusinessError) => {
          this.status = `Picker failed (${err.code})`;
        });
    } catch (e) {
      const err = e as BusinessError;
      this.status = `Picker error: ${err.code}`;
    }
  }

  build() {
    Column({ space: 16 }) {
      Text('FlorisBoard')
        .fontSize(30)
        .fontWeight(FontWeight.Bold)
        .fontColor('#4caf50')
      Text('for OpenHarmony')
        .fontSize(16)
        .fontColor('#888888')

      Text(this.status)
        .fontSize(15)
        .fontColor(this.imeEnabled ? '#388e3c' : '#d32f2f')
        .margin({ top: 8 })

      Button('Enable / Choose Keyboard')
        .width('80%')
        .backgroundColor('#4caf50')
        .onClick(() => this.openImePicker())

      Button('Refresh status')
        .width('80%')
        .backgroundColor('#9e9e9e')
        .onClick(() => this.refreshStatus())

      Column({ space: 6 }) {
        Text('Try it out:').fontSize(14).fontColor('#888888')
        TextInput({ placeholder: 'Tap here and type…', text: this.testText })
          .width('90%')
          .onChange((v: string) => { this.testText = v; })
        TextArea({ placeholder: 'Multiline test (Enter = newline)…' })
          .width('90%')
          .height(90)
      }
      .margin({ top: 12 })

      Text('Setup: 1) tap Enable and turn on FlorisBoard · 2) switch to it via the keyboard 🌐 key or the system input-switch.')
        .fontSize(12)
        .fontColor('#aaaaaa')
        .padding({ left: 24, right: 24 })
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .padding(20)
    .backgroundColor('#f5f5f5')
  }
}

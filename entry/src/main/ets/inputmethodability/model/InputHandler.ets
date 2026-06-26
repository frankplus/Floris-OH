/*
 * InputHandler — owns the live inputMethodEngine.InputClient between
 * 'inputStart' and 'inputStop'. Stored in AppStorage so the keyboard panel
 * page (running in the same extension VM) can commit text. Pattern adapted
 * from the in-tree KikaInputMethod sample.
 *
 * NOTE on OHOS delete semantics (verified against the sample + SDK docs):
 *   deleteForward(n)  -> deletes n chars BEFORE the cursor  == Backspace
 *   deleteBackward(n) -> deletes n chars AFTER  the cursor  == forward Delete
 */
import inputMethodEngine from '@ohos.inputMethodEngine';
import { BusinessError } from '@ohos.base';

export class InputHandler {
  private client: inputMethodEngine.InputClient | undefined = undefined;
  private kbController: inputMethodEngine.KeyboardController | undefined = undefined;
  private enterKeyType: number = inputMethodEngine.ENTER_KEY_TYPE_UNSPECIFIED;
  private inputPattern: number = inputMethodEngine.PATTERN_NULL;
  private session: number = 0;

  static getInstance(): InputHandler {
    let inst: InputHandler | undefined = AppStorage.get<InputHandler>('inputHandler');
    if (inst === undefined) {
      inst = new InputHandler();
      AppStorage.setOrCreate('inputHandler', inst);
    }
    return inst;
  }

  onInputStart(kb: inputMethodEngine.KeyboardController, client: inputMethodEngine.InputClient): void {
    this.kbController = kb;
    this.client = client;
    try {
      const attr: inputMethodEngine.EditorAttribute = client.getEditorAttributeSync();
      this.enterKeyType = attr.enterKeyType;
      this.inputPattern = attr.inputPattern;
    } catch (e) {
      const err = e as BusinessError;
      console.error(`FlorisIME getEditorAttribute failed: ${err.code} ${err.message}`);
    }
    AppStorage.setOrCreate('enterKeyType', this.enterKeyType);
    AppStorage.setOrCreate('inputPattern', this.inputPattern);
    this.session += 1;
    AppStorage.setOrCreate('imeSession', this.session);
  }

  onInputStop(): void {
    this.client = undefined;
    this.kbController = undefined;
  }

  isAttached(): boolean {
    return this.client !== undefined;
  }

  getInputPattern(): number {
    return this.inputPattern;
  }

  insert(text: string): void {
    if (this.client === undefined || text.length === 0) {
      return;
    }
    try {
      this.client.insertTextSync(text);
    } catch (e) {
      const err = e as BusinessError;
      console.error(`FlorisIME insert failed: ${err.code} ${err.message}`);
    }
  }

  backspace(): void {
    if (this.client === undefined) {
      return;
    }
    try {
      this.client.deleteForwardSync(1); // forward = before cursor (backspace)
    } catch (e) {
      const err = e as BusinessError;
      console.error(`FlorisIME backspace failed: ${err.code} ${err.message}`);
    }
  }

  // Used for best-effort auto-capitalization: text immediately before the cursor.
  textBeforeCursor(len: number): string {
    if (this.client === undefined) {
      return '';
    }
    try {
      return this.client.getForwardSync(len);
    } catch (e) {
      return '';
    }
  }

  enter(): void {
    if (this.client === undefined) {
      return;
    }
    try {
      if (this.enterKeyType === inputMethodEngine.ENTER_KEY_TYPE_UNSPECIFIED ||
        this.enterKeyType === inputMethodEngine.ENTER_KEY_TYPE_NEWLINE) {
        this.client.insertTextSync('\n');
      } else {
        this.client.sendKeyFunction(this.enterKeyType);
      }
    } catch (e) {
      const err = e as BusinessError;
      console.error(`FlorisIME enter failed: ${err.code} ${err.message}`);
    }
  }

  hideKeyboard(): void {
    if (this.kbController !== undefined) {
      this.kbController.hide();
    }
  }
}

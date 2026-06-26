/*
 * KeyboardController — creates the SOFT_KEYBOARD panel, wires the IME engine
 * lifecycle events, and hosts the keyboard ArkUI page. Adapted from the
 * in-tree KikaInputMethod sample (the known-working pattern for this OHOS).
 */
import inputMethodEngine from '@ohos.inputMethodEngine';
import { InputMethodExtensionContext } from '@kit.IMEKit';
import { display } from '@kit.ArkUI';
import { BusinessError } from '@ohos.base';
import { InputHandler } from './InputHandler';
import { Metrics } from '../../model/Theme';

const ime: inputMethodEngine.InputMethodAbility = inputMethodEngine.getInputMethodAbility();

export class KeyboardController {
  private context: InputMethodExtensionContext | undefined = undefined;
  private panel: inputMethodEngine.Panel | undefined = undefined;
  private destroyed: boolean = false;
  private listenersRegistered: boolean = false;

  // Stored as fields so the exact same references can be passed to .off() in
  // onDestroy — the extension process can outlive a single create/destroy cycle.
  private onInputStart: (kb: inputMethodEngine.KeyboardController, client: inputMethodEngine.InputClient) => void =
    (kb: inputMethodEngine.KeyboardController, client: inputMethodEngine.InputClient) => {
      InputHandler.getInstance().onInputStart(kb, client);
    };
  private onInputStop: () => void = () => {
    InputHandler.getInstance().onInputStop();
  };
  private onDisplayChange: (id: number) => void = (id: number) => {
    this.resizePanel();
  };

  onCreate(context: InputMethodExtensionContext): void {
    this.context = context;
    this.destroyed = false;
    this.registerListeners();
    this.initPanel();
  }

  onDestroy(): void {
    this.destroyed = true;
    this.unregisterListeners();
    if (this.panel !== undefined) {
      ime.destroyPanel(this.panel);
      this.panel = undefined;
    }
    if (this.context !== undefined) {
      this.context.destroy();
    }
  }

  private registerListeners(): void {
    if (this.listenersRegistered) {
      return;
    }
    ime.on('inputStart', this.onInputStart);
    ime.on('inputStop', this.onInputStop);
    try {
      display.on('change', this.onDisplayChange);
    } catch (e) {
      const err = e as BusinessError;
      console.error(`FlorisIME display.on failed: ${err.code} ${err.message}`);
    }
    this.listenersRegistered = true;
  }

  private unregisterListeners(): void {
    try {
      ime.off('inputStart', this.onInputStart);
      ime.off('inputStop', this.onInputStop);
      display.off('change', this.onDisplayChange);
    } catch (e) {
      const err = e as BusinessError;
      console.error(`FlorisIME off failed: ${err.code} ${err.message}`);
    }
    this.listenersRegistered = false;
  }

  // Size the panel so a weight-1 key is ~square: a row is as tall as a key is
  // wide × Metrics.keyAspect. This keeps keys square on the X23's tall
  // 720×1560 panel instead of stretching them to a fixed screen fraction.
  private panelHeight(): number {
    const dis: display.Display = display.getDefaultDisplaySync();
    const density: number = (dis.densityPixels !== undefined && dis.densityPixels > 0) ? dis.densityPixels : 2;
    const padPx: number = Metrics.boardPadding * density * 2;
    const keyWidthPx: number = (dis.width - padPx) / 10;       // 10 weight-units per row
    const rowPx: number = keyWidthPx * Metrics.keyAspect;
    const raw: number = Math.floor(rowPx * Metrics.visibleRows + padPx);
    // Clamp to a sane fraction of the screen as a guard (rotation / odd devices).
    const minH: number = Math.floor(dis.height * 0.16);
    const maxH: number = Math.floor(dis.height * 0.5);
    return Math.min(maxH, Math.max(minH, raw));
  }

  private initPanel(): void {
    if (this.context === undefined) {
      return;
    }
    const dis: display.Display = display.getDefaultDisplaySync();
    const width: number = dis.width;
    const height: number = this.panelHeight();
    const info: inputMethodEngine.PanelInfo = {
      type: inputMethodEngine.PanelType.SOFT_KEYBOARD,
      flag: inputMethodEngine.PanelFlag.FLG_FIXED,
    };
    ime.createPanel(this.context, info).then((panel: inputMethodEngine.Panel) => {
      if (this.destroyed) {
        ime.destroyPanel(panel); // ability was destroyed before createPanel resolved
        return;
      }
      this.panel = panel;
      panel.resize(width, height).then(() => {
        panel.setUiContent('inputmethodability/pages/KeyboardPage').then(() => {
          console.info('FlorisIME panel ready');
        }).catch((err: BusinessError) => {
          console.error(`FlorisIME setUiContent failed: ${err.code} ${err.message}`);
        });
      }).catch((err: BusinessError) => {
        console.error(`FlorisIME resize failed: ${err.code} ${err.message}`);
      });
    }).catch((err: BusinessError) => {
      console.error(`FlorisIME createPanel failed: ${err.code} ${err.message}`);
    });
  }

  private resizePanel(): void {
    if (this.panel === undefined) {
      return;
    }
    const dis: display.Display = display.getDefaultDisplaySync();
    this.panel.resize(dis.width, this.panelHeight()).catch((err: BusinessError) => {
      console.error(`FlorisIME resizePanel failed: ${err.code} ${err.message}`);
    });
  }
}

export const keyboardController: KeyboardController = new KeyboardController();

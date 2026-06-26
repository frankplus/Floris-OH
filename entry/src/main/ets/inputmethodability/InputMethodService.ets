/*
 * The InputMethodExtensionAbility entry point. Delegates to KeyboardController.
 */
import { InputMethodExtensionAbility } from '@kit.IMEKit';
import { Want } from '@kit.AbilityKit';
import { keyboardController } from './model/KeyboardController';

export default class InputMethodService extends InputMethodExtensionAbility {
  onCreate(want: Want): void {
    keyboardController.onCreate(this.context);
  }

  onDestroy(): void {
    keyboardController.onDestroy();
  }
}

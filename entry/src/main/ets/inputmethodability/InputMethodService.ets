/*
 * The InputMethodExtensionAbility entry point. Delegates to KeyboardController.
 */
import { InputMethodExtensionAbility } from '@kit.IMEKit';
import { Want } from '@kit.AbilityKit';
import { keyboardController } from './model/KeyboardController';
import { SettingsStore } from '../model/SettingsStore';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@ohos.base';

export default class InputMethodService extends InputMethodExtensionAbility {
  onCreate(want: Want): void {
    // The extension runs in its own process: it opens the shared Preferences
    // file itself before the keyboard controller (and the panel it hosts) is
    // created, so the first panel show already has real settings.
    SettingsStore.getInstance().init(this.context).then(() => {
      keyboardController.onCreate(this.context);
    }).catch((e: BusinessError) => {
      hilog.error(0x0001, 'InputMethodService', 'SettingsStore.init failed: %{public}s', JSON.stringify(e));
      keyboardController.onCreate(this.context);
    });
  }

  onDestroy(): void {
    keyboardController.onDestroy();
  }
}

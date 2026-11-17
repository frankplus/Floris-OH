/*
 * Bridges SettingsStore (the shared data layer) into the IME panel's UI. The
 * panel page (KeyboardPage, V1) cannot react to SettingsStore's @Trace fields
 * directly, so a reload bumps a plain AppStorage counter that the page
 * watches with @StorageProp/@Watch and re-reads prefs() from on every bump.
 */
import { SettingsStore } from '../../model/SettingsStore';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@ohos.base';

const DOMAIN = 0x0001;
const TAG = 'SettingsBridge';

export function bumpSettingsVersion(): void {
  const current: number | undefined = AppStorage.get<number>('settingsVersion');
  AppStorage.setOrCreate('settingsVersion', (current !== undefined ? current : 0) + 1);
}

// Re-reads the Preferences file (the app may have changed a setting since the
// panel last showed) and bumps the counter so the panel re-applies everything.
export async function reloadSettingsAndBump(): Promise<void> {
  try {
    await SettingsStore.getInstance().reload();
  } catch (e) {
    const err = e as BusinessError;
    hilog.error(DOMAIN, TAG, 'reload failed: %{public}s', JSON.stringify(err));
  }
  bumpSettingsVersion();
}

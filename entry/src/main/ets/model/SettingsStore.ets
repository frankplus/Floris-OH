// The data layer's contract, from the AppSpec: Keeps the keyboard settings (one KeyboardPrefs) in the Preferences file 'florisboard_settings' under FlorisBoard's keys, shared by the app's process and the input method's process; loaded in init, written and flushed by every setter, re-read from storage by reload.
import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { KeyboardPrefs } from './KeyboardPrefs';

const DOMAIN = 0x0001;
const TAG = 'SettingsStore';
const FILE_NAME = 'florisboard_settings';

const KEY_NUMBER_ROW = 'keyboard__number_row';
const KEY_HINTED_SYMBOLS = 'keyboard__hinted_symbols_enabled';
const KEY_FONT_SIZE = 'keyboard__font_size_multiplier_portrait';
const KEY_HEIGHT = 'keyboard__height_factor_portrait';
const KEY_HAPTIC_ENABLED = 'input_feedback__haptic_enabled';
const KEY_HAPTIC_DURATION = 'input_feedback__haptic_vibration_duration';
const KEY_AUTO_CAPITALIZATION = 'correction__auto_capitalization';
const KEY_DOUBLE_SPACE_PERIOD = 'correction__double_space_period';
const KEY_THEME_MODE = 'theme__mode';
const KEY_LAYOUT = 'localization__layout';

export class SettingsStore {
  private static instance: SettingsStore | null = null;

  static getInstance(): SettingsStore {
    if (SettingsStore.instance === null) {
      SettingsStore.instance = new SettingsStore();
    }
    return SettingsStore.instance;
  }

  private context: common.Context | null = null;
  private prefsInstance: preferences.Preferences | null = null;
  private opened: boolean = false;
  private cached: KeyboardPrefs = new KeyboardPrefs();

  private static clampPercent(value: number): number {
    const rounded = Math.round(value / 5) * 5;
    return Math.min(150, Math.max(50, rounded));
  }

  private static clampDuration(value: number): number {
    const rounded = Math.round(value);
    return Math.min(100, Math.max(1, rounded));
  }

  private requirePrefs(): preferences.Preferences {
    if (this.prefsInstance === null) {
      const err = new Error('SettingsStore is not initialized');
      hilog.error(DOMAIN, TAG, '%{public}s', err.message);
      throw err;
    }
    return this.prefsInstance;
  }

  private loadFromPrefs(p: preferences.Preferences): void {
    this.cached.numberRow = p.getSync(KEY_NUMBER_ROW, false) as boolean;
    this.cached.hintedSymbols = p.getSync(KEY_HINTED_SYMBOLS, true) as boolean;
    this.cached.fontSizePercent = p.getSync(KEY_FONT_SIZE, 100) as number;
    this.cached.heightPercent = p.getSync(KEY_HEIGHT, 100) as number;
    this.cached.hapticEnabled = p.getSync(KEY_HAPTIC_ENABLED, true) as boolean;
    this.cached.hapticDurationMs = p.getSync(KEY_HAPTIC_DURATION, 50) as number;
    this.cached.autoCapitalization = p.getSync(KEY_AUTO_CAPITALIZATION, true) as boolean;
    this.cached.doubleSpacePeriod = p.getSync(KEY_DOUBLE_SPACE_PERIOD, true) as boolean;
    this.cached.themeMode = p.getSync(KEY_THEME_MODE, 'follow_system') as string;
    this.cached.layout = p.getSync(KEY_LAYOUT, 'qwerty') as string;
  }

  private async writeValue(key: string, value: preferences.ValueType): Promise<void> {
    const p = this.requirePrefs();
    try {
      p.putSync(key, value);
      await p.flush();
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'write %{public}s failed: %{public}s', key, JSON.stringify(err));
      throw err as Error;
    }
  }

  private formatByName(name: string, value: number): string {
    if (this.context === null) {
      return `${value}`;
    }
    try {
      return this.context.resourceManager.getStringByNameSync(name, value);
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'getStringByNameSync %{public}s failed: %{public}s', name, JSON.stringify(err));
      return `${value}`;
    }
  }

  /** Opens what the store keeps (a database, a preferences file) and loads it. Awaited once by the entry ability; a second call does nothing. */
  async init(context: common.Context): Promise<void> {
    if (this.opened) {
      return;
    }
    this.context = context;
    try {
      this.prefsInstance = preferences.getPreferencesSync(context, { name: FILE_NAME });
      this.loadFromPrefs(this.prefsInstance);
      this.opened = true;
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'init failed: %{public}s', JSON.stringify(err));
      throw err as Error;
    }
  }

  /** Returns the one in-memory KeyboardPrefs instance loaded by init (defaults for keys not stored yet). Always the same object: setters and reload update its @Trace fields in place, so screens bound to it refresh. */
  prefs(): KeyboardPrefs {
    return this.cached;
  }

  /** Drops this process's cached Preferences instance (preferences.removePreferencesFromCacheSync(context, 'florisboard_settings')), opens the file again, copies every stored value into the prefs() instance (defaults for missing keys) and returns it. The input method calls it each time its panel shows, so changes made in the app apply. */
  async reload(): Promise<KeyboardPrefs> {
    if (this.context === null) {
      const err = new Error('SettingsStore is not initialized');
      hilog.error(DOMAIN, TAG, '%{public}s', err.message);
      throw err;
    }
    try {
      preferences.removePreferencesFromCacheSync(this.context, FILE_NAME);
      this.prefsInstance = preferences.getPreferencesSync(this.context, { name: FILE_NAME });
      this.loadFromPrefs(this.prefsInstance);
      this.opened = true;
      return this.cached;
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'reload failed: %{public}s', JSON.stringify(err));
      throw err as Error;
    }
  }

  /** Sets numberRow, writes keyboard__number_row and flushes. */
  async setNumberRow(value: boolean): Promise<void> {
    await this.writeValue(KEY_NUMBER_ROW, value);
    this.cached.numberRow = value;
  }

  /** Sets hintedSymbols, writes keyboard__hinted_symbols_enabled and flushes. */
  async setHintedSymbols(value: boolean): Promise<void> {
    await this.writeValue(KEY_HINTED_SYMBOLS, value);
    this.cached.hintedSymbols = value;
  }

  /** Rounds to the nearest multiple of 5, clamps to 50..150, sets fontSizePercent, writes keyboard__font_size_multiplier_portrait and flushes. */
  async setFontSizePercent(value: number): Promise<void> {
    const clamped = SettingsStore.clampPercent(value);
    await this.writeValue(KEY_FONT_SIZE, clamped);
    this.cached.fontSizePercent = clamped;
  }

  /** Rounds to the nearest multiple of 5, clamps to 50..150, sets heightPercent, writes keyboard__height_factor_portrait and flushes. */
  async setHeightPercent(value: number): Promise<void> {
    const clamped = SettingsStore.clampPercent(value);
    await this.writeValue(KEY_HEIGHT, clamped);
    this.cached.heightPercent = clamped;
  }

  /** Sets hapticEnabled, writes input_feedback__haptic_enabled and flushes. */
  async setHapticEnabled(value: boolean): Promise<void> {
    await this.writeValue(KEY_HAPTIC_ENABLED, value);
    this.cached.hapticEnabled = value;
  }

  /** Rounds to an integer, clamps to 1..100, sets hapticDurationMs, writes input_feedback__haptic_vibration_duration and flushes. */
  async setHapticDurationMs(value: number): Promise<void> {
    const clamped = SettingsStore.clampDuration(value);
    await this.writeValue(KEY_HAPTIC_DURATION, clamped);
    this.cached.hapticDurationMs = clamped;
  }

  /** Sets autoCapitalization, writes correction__auto_capitalization and flushes. */
  async setAutoCapitalization(value: boolean): Promise<void> {
    await this.writeValue(KEY_AUTO_CAPITALIZATION, value);
    this.cached.autoCapitalization = value;
  }

  /** Sets doubleSpacePeriod, writes correction__double_space_period and flushes. */
  async setDoubleSpacePeriod(value: boolean): Promise<void> {
    await this.writeValue(KEY_DOUBLE_SPACE_PERIOD, value);
    this.cached.doubleSpacePeriod = value;
  }

  /** Sets themeMode when mode is one of themeModes() ('follow_system', 'always_day', 'always_night'), writes theme__mode and flushes; an unknown mode is ignored. */
  async setThemeMode(mode: string): Promise<void> {
    if (!this.themeModes().includes(mode)) {
      return;
    }
    await this.writeValue(KEY_THEME_MODE, mode);
    this.cached.themeMode = mode;
  }

  /** Sets layout when it is one of layouts() ('qwerty', 'qwertz', 'azerty'), writes localization__layout and flushes; an unknown layout is ignored. */
  async setLayout(layout: string): Promise<void> {
    if (!this.layouts().includes(layout)) {
      return;
    }
    await this.writeValue(KEY_LAYOUT, layout);
    this.cached.layout = layout;
  }

  /** Returns ['follow_system', 'always_day', 'always_night'] in this order (the Theme screen's rows). */
  themeModes(): string[] {
    return ['follow_system', 'always_day', 'always_night'];
  }

  /** The label of a theme mode from the string resources: 'Follow system', 'Always day', 'Always night'; an unknown mode gives 'Follow system'. */
  themeModeName(mode: string): Resource {
    if (mode === 'always_day') {
      return $r('app.string.settings_store_theme_always_day');
    }
    if (mode === 'always_night') {
      return $r('app.string.settings_store_theme_always_night');
    }
    return $r('app.string.settings_store_theme_follow_system');
  }

  /** Returns ['qwerty', 'qwertz', 'azerty'] in this order (the Languages & Layouts rows). */
  layouts(): string[] {
    return ['qwerty', 'qwertz', 'azerty'];
  }

  /** The layout's name from the string resources: 'QWERTY', 'QWERTZ', 'AZERTY'; an unknown layout gives 'QWERTY'. */
  layoutName(layout: string): Resource {
    if (layout === 'qwertz') {
      return $r('app.string.settings_store_layout_qwertz');
    }
    if (layout === 'azerty') {
      return $r('app.string.settings_store_layout_azerty');
    }
    return $r('app.string.settings_store_layout_qwerty');
  }

  /** The subtype name FlorisBoard shows on the space bar and in the subtype row: 'English (QWERTY)', 'English (QWERTZ)', 'English (AZERTY)'; an unknown layout gives 'English (QWERTY)'. */
  spaceBarLabel(layout: string): Resource {
    if (layout === 'qwertz') {
      return $r('app.string.settings_store_space_bar_qwertz');
    }
    if (layout === 'azerty') {
      return $r('app.string.settings_store_space_bar_azerty');
    }
    return $r('app.string.settings_store_space_bar_qwerty');
  }

  /** The rawfile base name under layouts/ of the characters layer for a layout: 'characters' for qwerty (the base's file), 'characters_qwertz', 'characters_azerty'; an unknown layout gives 'characters'. */
  layoutFile(layout: string): string {
    if (layout === 'qwertz') {
      return 'characters_qwertz';
    }
    if (layout === 'azerty') {
      return 'characters_azerty';
    }
    return 'characters';
  }

  /** Formats a percentage for the slider value labels: 100 gives '100%'. */
  percentText(value: number): string {
    return this.formatByName('settings_store_percent_format', Math.round(value));
  }

  /** Formats a vibration duration: 50 gives '50 ms'. */
  durationText(ms: number): string {
    return this.formatByName('settings_store_duration_format', Math.round(ms));
  }
}

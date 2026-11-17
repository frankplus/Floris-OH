// Entity "KeyboardPrefs" from the AppSpec (persistence: preferences). Generated shape; the data work item may extend it,
// keeping KeyboardPrefsData, toJSON and fromJSON in step with the fields.

/** KeyboardPrefs as plain data: what goes to storage and comes back from it. */
export interface KeyboardPrefsData {
  numberRow: boolean;
  hintedSymbols: boolean;
  fontSizePercent: number;
  heightPercent: number;
  hapticEnabled: boolean;
  hapticDurationMs: number;
  autoCapitalization: boolean;
  doubleSpacePeriod: boolean;
  themeMode: string;
  layout: string;
}

@ObservedV2
export class KeyboardPrefs {
  @Trace numberRow: boolean = false;
  @Trace hintedSymbols: boolean = true;
  @Trace fontSizePercent: number = 100;
  @Trace heightPercent: number = 100;
  @Trace hapticEnabled: boolean = true;
  @Trace hapticDurationMs: number = 50;
  @Trace autoCapitalization: boolean = true;
  @Trace doubleSpacePeriod: boolean = true;
  @Trace themeMode: string = 'follow_system';
  @Trace layout: string = 'qwerty';

  /**
   * JSON.stringify calls this, for one entity or a list of them. Without it the fields are written under internal
   * names (__ob_<field>) and nothing reads back.
   */
  toJSON(): KeyboardPrefsData {
    return {
      numberRow: this.numberRow,
      hintedSymbols: this.hintedSymbols,
      fontSizePercent: this.fontSizePercent,
      heightPercent: this.heightPercent,
      hapticEnabled: this.hapticEnabled,
      hapticDurationMs: this.hapticDurationMs,
      autoCapitalization: this.autoCapitalization,
      doubleSpacePeriod: this.doubleSpacePeriod,
      themeMode: this.themeMode,
      layout: this.layout,
    };
  }

  /** An entity from data read back: (JSON.parse(raw) as KeyboardPrefsData[]).map((d: KeyboardPrefsData) => KeyboardPrefs.fromJSON(d)). A field the data lacks keeps its initial value. */
  static fromJSON(d: KeyboardPrefsData): KeyboardPrefs {
    const item = new KeyboardPrefs();
    if (d.numberRow !== undefined) {
      item.numberRow = d.numberRow;
    }
    if (d.hintedSymbols !== undefined) {
      item.hintedSymbols = d.hintedSymbols;
    }
    if (d.fontSizePercent !== undefined) {
      item.fontSizePercent = d.fontSizePercent;
    }
    if (d.heightPercent !== undefined) {
      item.heightPercent = d.heightPercent;
    }
    if (d.hapticEnabled !== undefined) {
      item.hapticEnabled = d.hapticEnabled;
    }
    if (d.hapticDurationMs !== undefined) {
      item.hapticDurationMs = d.hapticDurationMs;
    }
    if (d.autoCapitalization !== undefined) {
      item.autoCapitalization = d.autoCapitalization;
    }
    if (d.doubleSpacePeriod !== undefined) {
      item.doubleSpacePeriod = d.doubleSpacePeriod;
    }
    if (d.themeMode !== undefined) {
      item.themeMode = d.themeMode;
    }
    if (d.layout !== undefined) {
      item.layout = d.layout;
    }
    return item;
  }
}

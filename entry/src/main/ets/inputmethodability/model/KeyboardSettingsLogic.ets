/*
 * The pure part of how the keyboard applies the settings (KeyboardPrefs): which
 * rows the characters layer shows, which corner hints and ids its keys carry,
 * how big the keys and the panel are, when two spaces become a period, when the
 * board auto-capitalizes, and which Floris theme is in effect. KeyboardPage and
 * KeyboardController call it; it touches no device or UI API, so the unit tests
 * exercise it directly.
 */
import { KeyboardMode, KeyDef, LayoutDef, RowDef } from '../../model/KeyModels';
import { FlorisDark, FlorisLight, Metrics, ThemeColors } from '../../model/Theme';

export class KeyboardSettingsLogic {
  // Rows in the characters layer: the usual visible rows, one more with the number row.
  static panelRows(numberRow: boolean): number {
    return numberRow ? Metrics.visibleRows + 1 : Metrics.visibleRows;
  }

  // Height in px of the key rows before the panel's padding, clamp and inset.
  static keyRowsHeightPx(rowPx: number, numberRow: boolean, heightPercent: number): number {
    return rowPx * KeyboardSettingsLogic.panelRows(numberRow) * (heightPercent / 100);
  }

  // The characters layer: the chosen layout's rows, with the first row of the
  // number_row layout on top when the number row is on.
  static withNumberRow(base: LayoutDef, numberRow: LayoutDef | undefined, on: boolean): LayoutDef {
    if (!on || numberRow === undefined || numberRow.rows.length === 0) {
      return base;
    }
    const rows: RowDef[] = [numberRow.rows[0]];
    for (const r of base.rows) {
      rows.push(r);
    }
    const combined: LayoutDef = { name: base.name, rows: rows };
    return combined;
  }

  // The corner hint a key shows: none when hinted symbols are off, and none on
  // the top letter row of the characters layer when the number row already
  // shows its digits (that row is index 1 then, under the number row).
  static hintFor(key: KeyDef, rowIndex: number, mode: string, hintedSymbols: boolean, numberRow: boolean): string {
    if (!hintedSymbols || key.hint === undefined || key.kind === 'spacer') {
      return '';
    }
    if (mode === KeyboardMode.CHARACTERS && numberRow && rowIndex === 1) {
      return '';
    }
    return key.hint;
  }

  static fontScale(fontSizePercent: number): number {
    return fontSizePercent / 100;
  }

  static keyFontSize(kind: string, fontSizePercent: number): number {
    const scale: number = KeyboardSettingsLogic.fontScale(fontSizePercent);
    if (kind === 'char') {
      return Metrics.keyFontSize * scale;
    }
    if (kind === 'space') {
      return Metrics.spaceFontSize * scale;
    }
    return Metrics.specialKeyFontSize * scale;
  }

  static hintFontSize(fontSizePercent: number): number {
    return Metrics.hintFontSize * KeyboardSettingsLogic.fontScale(fontSizePercent);
  }

  // The part after 'key_' / 'hint_': the key's lowercase letter or digit, or
  // 'code_<code>' when its output is not a plain letter or digit.
  static charBase(key: KeyDef): string {
    if (key.kind !== 'char') {
      return '';
    }
    const out: string = key.output !== undefined ? key.output : (key.label !== undefined ? key.label : '');
    const lower: string = out.toLowerCase();
    if (lower.length > 0 && /^[a-z0-9]+$/.test(lower)) {
      return lower;
    }
    return `code_${key.code !== undefined ? key.code : 0}`;
  }

  static keyId(key: KeyDef): string {
    switch (key.kind) {
      case 'char':
        return `key_${KeyboardSettingsLogic.charBase(key)}`;
      case 'shift':
        return 'key_shift';
      case 'delete':
        return 'key_delete';
      case 'enter':
        return 'key_enter';
      case 'space':
        return 'key_space';
      case 'lang':
        return 'key_lang';
      case 'view':
        if (key.target === KeyboardMode.SYMBOLS) {
          return 'key_symbols';
        }
        if (key.target === KeyboardMode.SYMBOLS2) {
          return 'key_symbols2';
        }
        if (key.target === KeyboardMode.CHARACTERS) {
          return 'key_characters';
        }
        if (key.target === KeyboardMode.NUMERIC) {
          return 'key_numeric';
        }
        return 'key_view';
      default:
        return '';
    }
  }

  static hintId(key: KeyDef): string {
    const base: string = KeyboardSettingsLogic.charBase(key);
    return base.length > 0 ? `hint_${base}` : '';
  }

  // Two spaces in a row after a word become '. ' only with double-space period on.
  static insertsPeriod(doubleSpacePeriod: boolean, consecutive: boolean, before: string): boolean {
    return doubleSpacePeriod && consecutive && /[^.!?‽\s]\s$/.test(before);
  }

  // Whether the next character starts capitalized: only with auto-capitalization
  // on, at the start of the field or after the end of a sentence.
  static autoCapitalizes(autoCapitalization: boolean, before: string): boolean {
    if (!autoCapitalization) {
      return false;
    }
    return before.length === 0 || /[.!?]\s$/.test(before);
  }

  static themeFor(themeMode: string, systemDark: boolean): ThemeColors {
    if (themeMode === 'always_day') {
      return FlorisLight;
    }
    if (themeMode === 'always_night') {
      return FlorisDark;
    }
    return systemDark ? FlorisDark : FlorisLight;
  }

  // The vibration a key press plays, in ms; 0 when haptic feedback is off.
  static vibrationMs(hapticEnabled: boolean, hapticDurationMs: number): number {
    if (!hapticEnabled) {
      return 0;
    }
    return Math.min(100, Math.max(1, Math.round(hapticDurationMs)));
  }
}

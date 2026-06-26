/*
 * Core keyboard data model for the FlorisBoard OpenHarmony port.
 * KeyCode values mirror FlorisBoard's ime/text/key/KeyCode.kt.
 */

// Special key codes (negative = internal actions), mirrored from FlorisBoard.
export class KeyCode {
  static readonly SPACE: number = 32;
  static readonly ENTER: number = 10;
  static readonly SHIFT: number = -11;
  static readonly CAPS_LOCK: number = -13;
  static readonly DELETE: number = -7;
  static readonly VIEW_CHARACTERS: number = -201;
  static readonly VIEW_SYMBOLS: number = -202;
  static readonly VIEW_SYMBOLS2: number = -203;
  static readonly VIEW_NUMERIC: number = -204;
  static readonly LANGUAGE_SWITCH: number = -227;
}

// Which on-screen layer is shown. Matches the rawfile layout file base names.
export enum KeyboardMode {
  CHARACTERS = 'characters',
  SYMBOLS = 'symbols',
  SYMBOLS2 = 'symbols2',
  NUMERIC = 'numeric',
}

// FlorisBoard's InputShiftState (ime/input/InputShiftState.kt).
export enum ShiftState {
  UNSHIFTED = 0,
  SHIFTED_MANUAL = 1,   // one-shot, resets after one character
  SHIFTED_AUTOMATIC = 2, // auto-capitalization one-shot
  CAPS_LOCK = 3,         // persists
}

// One key as produced by tools/convert-layouts.js.
export interface KeyDef {
  code?: number;
  label?: string;
  kind: string;        // 'char' | 'shift' | 'delete' | 'enter' | 'space' | 'view' | 'lang' | 'spacer'
  weight: number;
  target?: string;     // for kind === 'view': the KeyboardMode to switch to
  output?: string;     // text to commit for character keys (defaults to label)
  popups?: string[];   // long-press alternates
  hint?: string;       // small corner glyph (number row / symbol hints)
}

export interface RowDef {
  keys: KeyDef[];
}

export interface LayoutDef {
  name: string;
  rows: RowDef[];
}

// Helper predicates kept here so UI and engine agree on key semantics.
export class KeyUtils {
  static isUppercase(shift: ShiftState): boolean {
    return shift !== ShiftState.UNSHIFTED;
  }

  // Resolve the glyph a character key should commit / display given the shift state.
  static casedOutput(key: KeyDef, shift: ShiftState): string {
    const base: string = key.output !== undefined ? key.output : (key.label !== undefined ? key.label : '');
    if (KeyUtils.isUppercase(shift)) {
      return base.toUpperCase();
    }
    return base;
  }
}

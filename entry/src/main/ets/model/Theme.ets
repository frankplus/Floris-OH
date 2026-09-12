/*
 * Theme colors + metrics, ported from FlorisBoard's stock Snygg "Floris Day"
 * and "Floris Night" themes (org.florisboard.themes). Values copied verbatim
 * from each theme's `@defines` block (OHOS ArkUI uses the same #AARRGGBB /
 * #RRGGBB byte order as Android). In FlorisBoard's Day/Night themes EVERY key
 * uses `--surface` (white / dark-grey) — only the enter key is `--primary`
 * (green) — so special keys are NOT tinted; they read as plain keys. Caps-lock
 * only recolors the shift glyph to `--secondary` (orange).
 */

export interface ThemeColors {
  keyboardBackground: string;     // --background
  keyBackground: string;          // --surface  (all keys)
  keyForeground: string;          // --on-surface
  keyPressedBackground: string;   // --surface-variant
  specialKeyBackground: string;   // shift / delete / view switchers — same surface
  specialKeyForeground: string;   // --on-surface
  enterKeyBackground: string;     // --primary
  enterKeyPressed: string;        // --primary-variant
  enterKeyForeground: string;     // --on-primary
  secondary: string;              // --secondary (caps-lock shift glyph)
  popupBackground: string;        // --popup-surface
  popupForeground: string;        // --on-surface
  popupSelectedBackground: string;// --focused-popup-surface
  spaceForeground: string;        // --on-surface-variant (space label)
  hintForeground: string;         // --on-surface-variant (corner number/symbol hint)
}

// Floris Day (light).
export const FlorisLight: ThemeColors = {
  keyboardBackground: '#e0e0e0',
  keyBackground: '#ffffff',
  keyForeground: '#000000',
  keyPressedBackground: '#f5f5f5',
  specialKeyBackground: '#ffffff',
  specialKeyForeground: '#000000',
  enterKeyBackground: '#4caf50',
  enterKeyPressed: '#388e3c',
  enterKeyForeground: '#f0f0f0',
  secondary: '#ff9800',
  popupBackground: '#eeeeee',
  popupForeground: '#000000',
  popupSelectedBackground: '#bdbdbd',
  spaceForeground: '#5f5f5f',
  hintForeground: '#5f5f5f',
};

// Floris Night (dark).
export const FlorisDark: ThemeColors = {
  keyboardBackground: '#212121',
  keyBackground: '#424242',
  keyForeground: '#ffffff',
  keyPressedBackground: '#616161',
  specialKeyBackground: '#424242',
  specialKeyForeground: '#ffffff',
  enterKeyBackground: '#4caf50',
  enterKeyPressed: '#388e3c',
  enterKeyForeground: '#f0f0f0',
  secondary: '#f57c00',
  popupBackground: '#757575',
  popupForeground: '#ffffff',
  popupSelectedBackground: '#bdbdbd',
  spaceForeground: '#a0a0a0',
  hintForeground: '#a0a0a0',
};

// Geometry (FlorisBoard FlorisImeSizing / Snygg defines; dp→vp, sp→fp).
export class Metrics {
  static readonly keyCornerRadius: number = 8;     // --shape rounded-corner(8dp)
  static readonly keyFontSize: number = 22;        // key font-size 22sp
  static readonly specialKeyFontSize: number = 18; // view keys (?123/ABC) 18sp
  static readonly spaceFontSize: number = 12;      // space label 12sp
  static readonly hintFontSize: number = 11;       // corner hint ~12sp
  static readonly popupFontSize: number = 22;      // popup box 22sp
  // Key shape: each row is sized so a weight-1 key is ~square. The panel height
  // is derived in KeyboardController from the key width × this ratio, so keys
  // stay square regardless of screen aspect (the X23 is a tall 720×1560 panel).
  static readonly keyAspect: number = 1.3;         // row height / key width (incl. inter-row gap)
  static readonly visibleRows: number = 4;         // rows in every layer
  static readonly boardPadding: number = 4;        // keyboard outer padding (vp)
  // The gaps between keys are drawn by padding *inside* each key's touch target,
  // never by margins or Column spacing between them. A gap that sits outside the
  // components belongs to no key, and a tap landing there is silently swallowed:
  // with a 6 vp gap on both axes that was 27% of the keyboard's surface, which is
  // what made fast, less precise typing lose letters. So every key owns its full
  // pitch and merely paints a smaller tile inside it.
  static readonly keyMarginH: number = 3;          // half the inter-key (horizontal) gap
  static readonly rowGapHalf: number = 3;          // half the inter-row (vertical) gap
  // Bottom strip kept clear of keys for the system gesture-navigation bar.
  // The IME panel is bottom-anchored and the gesture bar (SCBGestureNavBar) is
  // drawn ON TOP of it, so without this the bottom key row sits under the dock
  // and loses its taps to the swipe-up gesture. Measured at 84 px on a
  // density-3.0 panel (`hidumper -s WindowManagerService -a -a`) => 28 vp.
  // The panel grows by this much and the keyboard content is padded by it, so
  // the keys keep their size and simply sit above the bar.
  static readonly gestureBarInset: number = 28;
}

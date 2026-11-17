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
  keyboardBackground: Resource;     // --background
  keyBackground: Resource;          // --surface  (all keys)
  keyForeground: Resource;          // --on-surface
  keyPressedBackground: Resource;   // --surface-variant
  specialKeyBackground: Resource;   // shift / delete / view switchers — same surface
  specialKeyForeground: Resource;   // --on-surface
  enterKeyBackground: Resource;     // --primary
  enterKeyPressed: Resource;        // --primary-variant
  enterKeyForeground: Resource;     // --on-primary
  secondary: Resource;              // --secondary (caps-lock shift glyph)
  popupBackground: Resource;        // --popup-surface
  popupForeground: Resource;        // --on-surface
  popupSelectedBackground: Resource;// --focused-popup-surface
  spaceForeground: Resource;        // --on-surface-variant (space label)
  hintForeground: Resource;         // --on-surface-variant (corner number/symbol hint)
}

// Floris Day (light). Explicit, not tied to the system's light/dark resource
// switching: the mode is chosen in KeyboardPage.theme() from the setting, so
// the same colours are defined once and used regardless of the device's mode.
export const FlorisLight: ThemeColors = {
  keyboardBackground: $r('app.color.floris_light_keyboard_background'),
  keyBackground: $r('app.color.floris_light_key_background'),
  keyForeground: $r('app.color.floris_light_key_foreground'),
  keyPressedBackground: $r('app.color.floris_light_key_pressed_background'),
  specialKeyBackground: $r('app.color.floris_light_special_key_background'),
  specialKeyForeground: $r('app.color.floris_light_special_key_foreground'),
  enterKeyBackground: $r('app.color.floris_light_enter_key_background'),
  enterKeyPressed: $r('app.color.floris_light_enter_key_pressed'),
  enterKeyForeground: $r('app.color.floris_light_enter_key_foreground'),
  secondary: $r('app.color.floris_light_secondary'),
  popupBackground: $r('app.color.floris_light_popup_background'),
  popupForeground: $r('app.color.floris_light_popup_foreground'),
  popupSelectedBackground: $r('app.color.floris_light_popup_selected_background'),
  spaceForeground: $r('app.color.floris_light_space_foreground'),
  hintForeground: $r('app.color.floris_light_hint_foreground'),
};

// Floris Night (dark).
export const FlorisDark: ThemeColors = {
  keyboardBackground: $r('app.color.floris_night_keyboard_background'),
  keyBackground: $r('app.color.floris_night_key_background'),
  keyForeground: $r('app.color.floris_night_key_foreground'),
  keyPressedBackground: $r('app.color.floris_night_key_pressed_background'),
  specialKeyBackground: $r('app.color.floris_night_special_key_background'),
  specialKeyForeground: $r('app.color.floris_night_special_key_foreground'),
  enterKeyBackground: $r('app.color.floris_night_enter_key_background'),
  enterKeyPressed: $r('app.color.floris_night_enter_key_pressed'),
  enterKeyForeground: $r('app.color.floris_night_enter_key_foreground'),
  secondary: $r('app.color.floris_night_secondary'),
  popupBackground: $r('app.color.floris_night_popup_background'),
  popupForeground: $r('app.color.floris_night_popup_foreground'),
  popupSelectedBackground: $r('app.color.floris_night_popup_selected_background'),
  spaceForeground: $r('app.color.floris_night_space_foreground'),
  hintForeground: $r('app.color.floris_night_hint_foreground'),
};

// Geometry (FlorisBoard FlorisImeSizing / Snygg defines; dp→vp, sp→fp).
export class Metrics {
  static readonly keyCornerRadius: number = 8;     // --shape rounded-corner(8dp)
  static readonly keyFontSize: number = 22;        // key font-size 22sp
  static readonly specialKeyFontSize: number = 18; // view keys (?123/ABC) 18sp
  static readonly spaceFontSize: number = 12;      // space label 12sp
  static readonly hintFontSize: number = 9;        // corner hint, small enough to clear the label
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

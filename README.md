# FlorisBoard for OpenHarmony

A port of [FlorisBoard](https://github.com/florisboard/florisboard) — the free,
open-source Android keyboard — to **OpenHarmony / HarmonyOS** as a native ArkTS
input method. Verified on a Volla X23 running OHOS 6.1.

FlorisBoard's UI is Kotlin/Jetpack-Compose and cannot run on OHOS, so the keyboard
**UI and input logic are re-implemented in ArkTS/ArkUI**, while the **keyboard data is
reused directly from upstream FlorisBoard**: the layouts, the long-press accent
mappings (`en.json`), the symbol popups, the currency set, and the Floris Day / Night
theme colors all come from the original project (see `tools/convert-layouts.js`).

## What works

- **QWERTY + symbols (`?123`) + symbols² (`=\<`) + numeric** layers, assembled from
  FlorisBoard's own layout JSON (the `characters` + `charactersMod` merge, etc.).
- **Shift state machine**: one-shot manual shift, double-tap → CAPS LOCK, auto-reset
  after a character.
- **Auto-capitalization** at sentence start (best-effort, from cursor context).
- **Text commit** via the OHOS `InputClient` (insert / backspace / cursor).
- **Action-aware Enter** — labels itself Go / Search / Send / Done / ⏎ from the focused
  field's `enterKeyType`, and performs the matching editor action (or inserts a newline).
- **Long-press accent popups** (e.g. `a → æ ã å ā à á â ä`) from FlorisBoard's `en.json`,
  case-aware, rendered as an in-panel overlay.
- **Backspace auto-repeat** (hold to repeat), **double-space → ". "**.
- **Floris Day / Night theme**, following the system light/dark setting.
- **Per-editor-session reset** (re-shows letters + re-evaluates auto-cap on a new field).
- **Gesture-dock clearance** — the panel is grown by `Metrics.gestureBarInset` (28 vp)
  and padded by the same amount at the bottom, so the last key row sits above the
  system gesture-navigation bar instead of under it.
- A **host setup screen** to enable/choose the keyboard and test typing.

## Architecture

One HAP, two parts (see `entry/src/main/ets/`):

| Part | Files |
|---|---|
| **IME extension** (`InputMethodExtensionAbility`) | `inputmethodability/InputMethodService.ets`, `model/KeyboardController.ets` (panel) |
| **Live text commit** (AppStorage singleton) | `inputmethodability/model/InputHandler.ets` |
| **Keyboard panel page** (`@Entry`, state machine) | `inputmethodability/pages/KeyboardPage.ets` |
| **Key component** (touch / long-press / repeat) | `components/KeyButton.ets` |
| **Data model / loader / theme** | `model/KeyModels.ets`, `model/LayoutStore.ets`, `model/Theme.ets` |
| **Host setup screen** | `pages/Index.ets` |

The keyboard registers in `module.json5` as an `extensionAbilities` entry of
`type: "inputMethod"` with the `ohos.extension.input_method` metadata pointing at
`resources/base/profile/input_method_config.json` (the subtype profile). The panel page
is also listed in the `pages` profile.

## Regenerate the layout data

The bundled layouts in `entry/src/main/resources/rawfile/layouts/` are produced from a
local FlorisBoard checkout:

```bash
# expects FlorisBoard at /home/mrfrank/Download/florisboard
node tools/convert-layouts.js
```

It merges each main layout with its `*Mod` row (reproducing FlorisBoard's
`LayoutManager.mergeLayouts`), resolves the `$`-discriminated selectors, attaches the
`en.json` accent popups, and substitutes the currency-slot placeholders.

## Build · deploy · use

```bash
oniro-app sign          # once, generates dev signing config
oniro-app build
oniro-app app apply      # install (auto-resolves the bundle from app.json5)
oniro-app app launch     # open the host setup screen
# In the app: tap "Enable / Choose Keyboard" → pick FlorisBoard → tap a field to type.
```

After re-installing, run `hdc shell "aa force-stop dev.patrickgold.florisboard"` so the
persistent IME process reloads the new code.

## Known limitations / future work

- No word suggestions / glide typing / spell-check (FlorisBoard's native NLP isn't ported).
- No clipboard manager, emoji panel, or theme editor.
- English (US) only so far — adding a layout is a `convert-layouts.js` entry plus a
  subtype in `input_method_config.json`.
- The system edge-back gesture can intercept taps on the very edge keys (a device-level
  behavior); a production build should request IMF exclusion of the panel region.

Upstream FlorisBoard is Apache-2.0; this port keeps the same license for the reused data.
# Floris-OH

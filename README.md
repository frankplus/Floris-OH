# FlorisBoard for OpenHarmony

A port of [FlorisBoard](https://github.com/florisboard/florisboard), the free,
open-source Android keyboard, to **OpenHarmony** as a native ArkTS input method,
with FlorisBoard's settings app.

FlorisBoard's UI is Kotlin/Jetpack Compose and cannot run on OpenHarmony, so the
keyboard and the settings app are re-implemented in ArkTS/ArkUI, while the
keyboard data comes directly from upstream FlorisBoard: the layouts, the
long-press accent mappings (`en.json`), the symbol popups, the currency set, the
Floris Day / Night theme colours and the launcher icon (see `tools/`).

## What works

The keyboard:

- **QWERTY, QWERTZ and AZERTY** character layers, plus **symbols (`?123`)**,
  **symbols² (`=\<`)** and **numeric**, assembled from FlorisBoard's own layout
  JSON. The space bar names the active layout, as FlorisBoard's does.
- **Shift**: one-shot shift, double-tap for caps lock, reset after a character.
- **Auto-capitalisation** at the start of a sentence, **double-space period**.
- **Action-aware Enter**: Go / Search / Send / Done / ⏎ from the focused field.
- **Long-press accent popups** (e.g. `a → æ ã å ā à á â ä`) from FlorisBoard's `en.json`.
- **Backspace auto-repeat**, **haptic feedback** per key.
- **Floris Day / Night** themes, following the system or forced.
- Clearance for the system's gesture-navigation bar.

The settings app (FlorisBoard's settings screens, limited to what the keyboard
can apply):

| Screen | Settings |
|---|---|
| Home | whether FlorisBoard is enabled, a button to the system's input-method picker, a field to try it |
| Keyboard | number row, hint symbols, font size, keyboard height |
| Input feedback | haptic feedback and its duration |
| Typing | auto-capitalisation, double-space period |
| Theme | follow the system, always Floris Day, always Floris Night |
| Languages & layouts | English: QWERTY, QWERTZ or AZERTY |
| About | version, licence, upstream project |

The settings live in one Preferences file. The input method runs in its own
process and reads the file again each time its panel shows.

## Not ported (yet)

Word suggestions and the smartbar, glide typing, spell checking, dictionaries,
clipboard history, the emoji panel, gestures (swipe on space/delete), one-handed
mode, the theme editor, backup and restore, languages other than English, sound
feedback and physical keyboards.

## Architecture

One HAP, two parts (`entry/src/main/ets/`):

| Part | Files |
|---|---|
| Input method (`InputMethodExtensionAbility`) | `inputmethodability/InputMethodService.ets`, `inputmethodability/model/KeyboardController.ets` |
| Keyboard panel | `inputmethodability/pages/KeyboardPage.ets`, `components/KeyButton.ets` |
| How the keyboard applies the settings | `inputmethodability/model/KeyboardSettingsLogic.ets`, `SettingsBridge.ets` |
| Text commit | `inputmethodability/model/InputHandler.ets` |
| Layouts, key model, keyboard themes | `model/LayoutStore.ets`, `model/KeyModels.ets`, `model/Theme.ets` |
| Settings store (both processes) | `model/SettingsStore.ets`, `model/KeyboardPrefs.ets` |
| Settings app | `pages/Index.ets` (navigation host), `screens/*.ets`, `kit/Kit.ets`, `theme/Theme.ets` |

## Build · install · use

The repository carries no signing material. Before the first build, run
`oniro-app sign --bootstrap` to generate development keys; it fills
`signingConfigs` in `build-profile.json5` and writes the keys to `signatures/`
(git-ignored). Keep that local change to `build-profile.json5` out of commits.

```bash
oniro-app build
oniro-app app install    # on the connected device or emulator
oniro-app app launch     # opens the settings app
```

In the app, tap the button that opens the input-method picker and choose
FlorisBoard. After reinstalling, run `hdc shell aa force-stop dev.patrickgold.florisboard`
so the input method's process loads the new code.

The unit tests are under `entry/src/ohosTest`.

## Regenerate the data

- Layouts: `node tools/convert-layouts.js` with a FlorisBoard checkout. It merges
  each layout with its `*Mod` row (FlorisBoard's `LayoutManager.mergeLayouts`),
  resolves the `$`-selectors, attaches the `en.json` accent popups and fills the
  currency slots.
- Icon: `tools/icon/make-icon.js` renders FlorisBoard's adaptive-icon vector
  drawable into the layered-icon PNGs (see its header).

## Releasing

Releases go to the [Oniro App Store](https://store.iparo.app) from GitHub Actions
([`.github/workflows/oniro-store.yml`](.github/workflows/oniro-store.yml)). The
shared [`oniro-app-store-actions`](https://github.com/eclipse-oniro4openharmony/oniro-app-store-actions)
workflow builds the HAP from the tagged commit, attaches it to a GitHub release
and registers it with the store, which marks it *Built from source*.

1. Raise `versionCode` (and `versionName`) in `AppScope/app.json5`; the store
   accepts only a higher `versionCode` than the last published one.
2. Commit and push to `main`.
3. Tag and push: `git tag v1.1.1 && git push origin v1.1.1`.

## How it was made

The keyboard was ported by hand. The settings app was then added by an
automated app factory, continuing this repository: it read FlorisBoard's
settings screens, wrote a specification (`.factory/appspec.json`), had coding
agents implement it, and checked the result on devices with the keyboard as the
current input method (typing, the number row, the layout switch, settings
surviving a restart).

## Licence

Apache-2.0, like upstream FlorisBoard, whose data and icon this port reuses.

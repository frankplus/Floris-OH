import { describe, expect, it } from '@ohos/hypium';
import { KeyboardSettingsLogic } from '../../../../main/ets/inputmethodability/model/KeyboardSettingsLogic';
import { KeyboardMode, KeyDef, LayoutDef } from '../../../../main/ets/model/KeyModels';
import { FlorisDark, FlorisLight } from '../../../../main/ets/model/Theme';

function charKey(label: string, code: number, hint?: string): KeyDef {
  const k: KeyDef = { kind: 'char', label: label, code: code, weight: 1, hint: hint };
  return k;
}

function key(kind: string, target?: string): KeyDef {
  const k: KeyDef = { kind: kind, weight: 1, target: target };
  return k;
}

export default function keyboardSettingsLogicTest() {
  describe('KeyboardSettingsLogic', () => {
    it('key_ids_name_letters_codes_and_special_keys', 0, () => {
      expect(KeyboardSettingsLogic.keyId(charKey('h', 104))).assertEqual('key_h');
      expect(KeyboardSettingsLogic.keyId(charKey('H', 72))).assertEqual('key_h');
      expect(KeyboardSettingsLogic.keyId(charKey(',', 44))).assertEqual('key_code_44');
      expect(KeyboardSettingsLogic.keyId(key('shift'))).assertEqual('key_shift');
      expect(KeyboardSettingsLogic.keyId(key('space'))).assertEqual('key_space');
      expect(KeyboardSettingsLogic.keyId(key('view', KeyboardMode.SYMBOLS))).assertEqual('key_symbols');
    });

    it('hints_follow_the_settings', 0, () => {
      const q = charKey('q', 113, '1');
      expect(KeyboardSettingsLogic.hintFor(q, 0, KeyboardMode.CHARACTERS, true, false)).assertEqual('1');
      expect(KeyboardSettingsLogic.hintFor(q, 0, KeyboardMode.CHARACTERS, false, false)).assertEqual('');
      expect(KeyboardSettingsLogic.hintFor(q, 1, KeyboardMode.CHARACTERS, true, true)).assertEqual('');
    });

    it('number_row_adds_one_row_on_top', 0, () => {
      const base: LayoutDef = { name: 'characters', rows: [{ keys: [charKey('q', 113)] }, { keys: [charKey('a', 97)] }] };
      const digits: LayoutDef = { name: 'number_row', rows: [{ keys: [charKey('1', 49)] }] };
      const on = KeyboardSettingsLogic.withNumberRow(base, digits, true);
      expect(on.rows.length).assertEqual(3);
      expect(on.rows[0].keys[0].label).assertEqual('1');
      expect(KeyboardSettingsLogic.withNumberRow(base, digits, false).rows.length).assertEqual(2);
      expect(KeyboardSettingsLogic.panelRows(true)).assertEqual(KeyboardSettingsLogic.panelRows(false) + 1);
    });

    it('double_space_period_obeys_the_setting', 0, () => {
      expect(KeyboardSettingsLogic.insertsPeriod(true, true, 'hello ')).assertTrue();
      expect(KeyboardSettingsLogic.insertsPeriod(false, true, 'hello ')).assertFalse();
      expect(KeyboardSettingsLogic.insertsPeriod(true, false, 'hello ')).assertFalse();
      expect(KeyboardSettingsLogic.insertsPeriod(true, true, 'hello. ')).assertFalse();
    });

    it('auto_capitalization_obeys_the_setting', 0, () => {
      expect(KeyboardSettingsLogic.autoCapitalizes(true, '')).assertTrue();
      expect(KeyboardSettingsLogic.autoCapitalizes(true, 'Done. ')).assertTrue();
      expect(KeyboardSettingsLogic.autoCapitalizes(true, 'hello ')).assertFalse();
      expect(KeyboardSettingsLogic.autoCapitalizes(false, '')).assertFalse();
    });

    it('theme_mode_picks_day_or_night', 0, () => {
      expect(KeyboardSettingsLogic.themeFor('always_day', true)).assertEqual(FlorisLight);
      expect(KeyboardSettingsLogic.themeFor('always_night', false)).assertEqual(FlorisDark);
      expect(KeyboardSettingsLogic.themeFor('follow_system', true)).assertEqual(FlorisDark);
      expect(KeyboardSettingsLogic.themeFor('follow_system', false)).assertEqual(FlorisLight);
    });

    it('vibration_is_off_or_clamped', 0, () => {
      expect(KeyboardSettingsLogic.vibrationMs(false, 50)).assertEqual(0);
      expect(KeyboardSettingsLogic.vibrationMs(true, 50)).assertEqual(50);
      expect(KeyboardSettingsLogic.vibrationMs(true, 500)).assertEqual(100);
      expect(KeyboardSettingsLogic.vibrationMs(true, 0)).assertEqual(1);
    });
  });
}

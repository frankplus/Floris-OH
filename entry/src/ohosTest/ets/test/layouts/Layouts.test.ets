import { describe, expect, it, beforeAll } from '@ohos/hypium';
import { abilityDelegatorRegistry } from '@kit.TestKit';
import type { resourceManager } from '@kit.LocalizationKit';
import { LayoutStore } from '../../../../main/ets/model/LayoutStore';
import { KeyDef, LayoutDef } from '../../../../main/ets/model/KeyModels';

function labels(layout: LayoutDef, row: number): string[] {
  return layout.rows[row].keys.filter((k: KeyDef) => k.kind === 'char').map((k: KeyDef) => k.label ?? '');
}

export default function layoutsTest() {
  describe('Layouts', () => {
    let rm: resourceManager.ResourceManager;

    beforeAll(() => {
      rm = abilityDelegatorRegistry.getAbilityDelegator().getAppContext().resourceManager;
    });

    it('qwertz_rows_follow_florisboard', 0, () => {
      const l = LayoutStore.load(rm, 'characters_qwertz');
      expect(labels(l, 0).join('')).assertEqual('qwertzuiop');
      expect(l.rows[2].keys[0].kind).assertEqual('shift');
      expect(l.rows[2].keys[1].label).assertEqual('y');
    });

    it('azerty_rows_follow_florisboard', 0, () => {
      const l = LayoutStore.load(rm, 'characters_azerty');
      expect(labels(l, 0).slice(0, 3).join('')).assertEqual('aze');
      const home = labels(l, 1);
      expect(home[home.length - 1]).assertEqual('m');
    });

    it('number_row_is_one_row_of_ten_digits', 0, () => {
      const l = LayoutStore.load(rm, 'number_row');
      expect(l.rows.length).assertEqual(1);
      expect(l.rows[0].keys.length).assertEqual(10);
      expect(labels(l, 0).join('')).assertEqual('1234567890');
    });

    it('every_char_key_has_a_code_and_a_label', 0, () => {
      for (const name of ['characters', 'characters_qwertz', 'characters_azerty', 'number_row']) {
        const l = LayoutStore.load(rm, name);
        for (const row of l.rows) {
          for (const k of row.keys) {
            if (k.kind === 'char') {
              expect(k.code !== undefined).assertTrue();
              expect((k.label ?? '').length > 0).assertTrue();
            }
          }
        }
      }
    });
  });
}

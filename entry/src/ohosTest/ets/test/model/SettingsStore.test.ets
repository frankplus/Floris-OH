import { afterEach, beforeAll, describe, expect, it } from '@ohos/hypium';
import { abilityDelegatorRegistry } from '@kit.TestKit';
import type { common } from '@kit.AbilityKit';
import { SettingsStore } from '../../../../main/ets/model/SettingsStore';

export default function settingsStoreTest() {
  describe('SettingsStore', () => {
    let context: common.Context;

    beforeAll(async () => {
      context = abilityDelegatorRegistry.getAbilityDelegator().getAppContext().getApplicationContext();
      await SettingsStore.getInstance().init(context);
    });

    afterEach(async () => {
      const store = SettingsStore.getInstance();
      await store.setNumberRow(false);
      await store.setHintedSymbols(true);
      await store.setFontSizePercent(100);
      await store.setHeightPercent(100);
      await store.setHapticEnabled(true);
      await store.setHapticDurationMs(50);
      await store.setAutoCapitalization(true);
      await store.setDoubleSpacePeriod(true);
      await store.setThemeMode('follow_system');
      await store.setLayout('qwerty');
    });

    it('defaults_match_the_spec', 0, () => {
      const store = SettingsStore.getInstance();
      const prefs = store.prefs();
      expect(prefs.numberRow).assertFalse();
      expect(prefs.hintedSymbols).assertTrue();
      expect(prefs.fontSizePercent).assertEqual(100);
      expect(prefs.heightPercent).assertEqual(100);
      expect(prefs.hapticEnabled).assertTrue();
      expect(prefs.hapticDurationMs).assertEqual(50);
      expect(prefs.autoCapitalization).assertTrue();
      expect(prefs.doubleSpacePeriod).assertTrue();
      expect(prefs.themeMode).assertEqual('follow_system');
      expect(prefs.layout).assertEqual('qwerty');
    });

    it('setNumberRow_updates_the_in_memory_prefs', 0, async () => {
      const store = SettingsStore.getInstance();
      await store.setNumberRow(true);
      expect(store.prefs().numberRow).assertTrue();
    });

    it('setFontSizePercent_rounds_to_the_nearest_multiple_of_5', 0, async () => {
      const store = SettingsStore.getInstance();
      await store.setFontSizePercent(103);
      expect(store.prefs().fontSizePercent).assertEqual(105);
      await store.setFontSizePercent(52);
      expect(store.prefs().fontSizePercent).assertEqual(50);
    });

    it('setFontSizePercent_clamps_to_50_150', 0, async () => {
      const store = SettingsStore.getInstance();
      await store.setFontSizePercent(500);
      expect(store.prefs().fontSizePercent).assertEqual(150);
      await store.setFontSizePercent(-20);
      expect(store.prefs().fontSizePercent).assertEqual(50);
    });

    it('setHeightPercent_rounds_and_clamps', 0, async () => {
      const store = SettingsStore.getInstance();
      await store.setHeightPercent(147);
      expect(store.prefs().heightPercent).assertEqual(145);
      await store.setHeightPercent(1000);
      expect(store.prefs().heightPercent).assertEqual(150);
    });

    it('setHapticDurationMs_rounds_to_an_integer_and_clamps_1_100', 0, async () => {
      const store = SettingsStore.getInstance();
      await store.setHapticDurationMs(12.6);
      expect(store.prefs().hapticDurationMs).assertEqual(13);
      await store.setHapticDurationMs(500);
      expect(store.prefs().hapticDurationMs).assertEqual(100);
      await store.setHapticDurationMs(-5);
      expect(store.prefs().hapticDurationMs).assertEqual(1);
    });

    it('setThemeMode_ignores_an_unknown_mode', 0, async () => {
      const store = SettingsStore.getInstance();
      await store.setThemeMode('always_day');
      expect(store.prefs().themeMode).assertEqual('always_day');
      await store.setThemeMode('bogus_mode');
      expect(store.prefs().themeMode).assertEqual('always_day');
    });

    it('setLayout_ignores_an_unknown_layout', 0, async () => {
      const store = SettingsStore.getInstance();
      await store.setLayout('qwertz');
      expect(store.prefs().layout).assertEqual('qwertz');
      await store.setLayout('bogus_layout');
      expect(store.prefs().layout).assertEqual('qwertz');
    });

    it('themeModes_and_layouts_list_the_spec_order', 0, () => {
      const store = SettingsStore.getInstance();
      expect(store.themeModes()).assertDeepEquals(['follow_system', 'always_day', 'always_night']);
      expect(store.layouts()).assertDeepEquals(['qwerty', 'qwertz', 'azerty']);
    });

    it('themeModeName_falls_back_to_follow_system_for_an_unknown_mode', 0, () => {
      const store = SettingsStore.getInstance();
      expect(JSON.stringify(store.themeModeName('bogus_mode'))).assertEqual(JSON.stringify(store.themeModeName('follow_system')));
    });

    it('layoutName_falls_back_to_qwerty_for_an_unknown_layout', 0, () => {
      const store = SettingsStore.getInstance();
      expect(JSON.stringify(store.layoutName('bogus_layout'))).assertEqual(JSON.stringify(store.layoutName('qwerty')));
    });

    it('spaceBarLabel_falls_back_to_qwerty_for_an_unknown_layout', 0, () => {
      const store = SettingsStore.getInstance();
      expect(JSON.stringify(store.spaceBarLabel('bogus_layout'))).assertEqual(JSON.stringify(store.spaceBarLabel('qwerty')));
    });

    it('layoutFile_names_the_rawfile_for_each_layout', 0, () => {
      const store = SettingsStore.getInstance();
      expect(store.layoutFile('qwerty')).assertEqual('characters');
      expect(store.layoutFile('qwertz')).assertEqual('characters_qwertz');
      expect(store.layoutFile('azerty')).assertEqual('characters_azerty');
      expect(store.layoutFile('bogus_layout')).assertEqual('characters');
    });

    it('percentText_and_durationText_format_their_values', 0, () => {
      const store = SettingsStore.getInstance();
      expect(store.percentText(100)).assertEqual('100%');
      expect(store.durationText(50)).assertEqual('50 ms');
    });

    it('a_setting_saved_through_one_instance_is_read_by_a_fresh_one', 0, async () => {
      const store = SettingsStore.getInstance();
      await store.setLayout('azerty');
      const fresh = new SettingsStore();
      await fresh.init(context);
      expect(fresh.prefs().layout).assertEqual('azerty');
    });

    it('reload_rereads_every_value_from_storage', 0, async () => {
      const store = SettingsStore.getInstance();
      await store.setNumberRow(true);
      await store.setThemeMode('always_night');
      const fresh = new SettingsStore();
      await fresh.init(context);
      const reloaded = await fresh.reload();
      expect(reloaded.numberRow).assertTrue();
      expect(reloaded.themeMode).assertEqual('always_night');
    });
  });
}

/*
 * Loads the assembled FlorisBoard layout JSON from resources/rawfile/layouts/
 * and caches the parsed LayoutDef objects. Used by the keyboard panel page.
 */
import util from '@ohos.util';
import resmgr from '@ohos.resourceManager';
import { LayoutDef } from './KeyModels';

export class LayoutStore {
  private static cache: Map<string, LayoutDef> = new Map<string, LayoutDef>();

  static load(rm: resmgr.ResourceManager, name: string): LayoutDef {
    const cached: LayoutDef | undefined = LayoutStore.cache.get(name);
    if (cached !== undefined) {
      return cached;
    }
    let def: LayoutDef;
    try {
      const bytes: Uint8Array = rm.getRawFileContentSync(`layouts/${name}.json`);
      const text: string = util.TextDecoder.create('utf-8').decodeToString(bytes);
      def = JSON.parse(text) as LayoutDef;
    } catch (e) {
      console.error(`FlorisIME layout '${name}' missing, falling back to characters`);
      if (name === 'characters') {
        throw e as Error;
      }
      def = LayoutStore.load(rm, 'characters');
    }
    LayoutStore.cache.set(name, def);
    return def;
  }
}

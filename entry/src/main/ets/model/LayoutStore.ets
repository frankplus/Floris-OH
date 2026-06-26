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
    const bytes: Uint8Array = rm.getRawFileContentSync(`layouts/${name}.json`);
    const text: string = util.TextDecoder.create('utf-8').decodeToString(bytes);
    const def: LayoutDef = JSON.parse(text) as LayoutDef;
    LayoutStore.cache.set(name, def);
    return def;
  }
}

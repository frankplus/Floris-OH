#!/usr/bin/env node
/*
 * convert-layouts.js — FlorisBoard → FlorisBoard-OHOS layout converter.
 *
 * Reads FlorisBoard's own keyboard layout JSON (the org.florisboard.layouts and
 * org.florisboard.localization extensions) and assembles flat, ArkTS-friendly
 * layout files for the OpenHarmony port. This is a genuine reuse of FlorisBoard's
 * data: key codes, labels, inline symbol popups, the main↔mod row merge, the
 * English accent popups (en.json) and the currency set all come from upstream.
 *
 * Usage: node tools/convert-layouts.js
 */
'use strict';
const fs = require('fs');
const path = require('path');

const FB = '/home/mrfrank/Download/florisboard/app/src/main/assets/ime/keyboard';
const LAYOUTS = path.join(FB, 'org.florisboard.layouts/layouts');
const POPUPS = path.join(FB, 'org.florisboard.localization/popupMappings');
const OUT = path.join(__dirname, '../entry/src/main/resources/rawfile/layouts');

// --- KeyCode constants (mirror FlorisBoard ime/text/key/KeyCode.kt) ---
const KC = {
  SPACE: 32, ENTER: 10, SHIFT: -11, CAPS_LOCK: -13, DELETE: -7,
  VIEW_CHARACTERS: -201, VIEW_SYMBOLS: -202, VIEW_SYMBOLS2: -203,
  VIEW_NUMERIC: -204, VIEW_NUMERIC_ADVANCED: -205,
  LANGUAGE_SWITCH: -227,
  CURRENCY_SLOT_1: -801, CURRENCY_SLOT_6: -806,
  MULTIPLE_CODE_POINTS: -902,
  URI_COMPONENT_TLD: -255,
  IME_UI_MODE_MEDIA: -212, IME_UI_MODE_CLIPBOARD: -213, IME_UI_MODE_TEXT: -211,
};

// Western currency set (FlorisBoard default-style slots: $ primary, then € £ ¥ ¢ ₩).
const CURRENCY = { '-801': '$', '-802': '€', '-803': '£', '-804': '¥', '-805': '¢', '-806': '₩' };

const readJson = (p) => JSON.parse(fs.readFileSync(p, 'utf8'));

// Resolve FlorisBoard's polymorphic "$"-discriminated key objects down to a plain key.
// We always pick the western / ltr / unshifted / lower / half default branch.
function resolveKey(k) {
  if (k === null || k === undefined) return null;
  const disc = k['$'];
  if (!disc) return k; // plain text_key (no discriminator)
  switch (disc) {
    case 'variation_selector':
      return resolveKey(k.default || k.normal || k.email || k.uri);
    case 'layout_direction_selector':
      return resolveKey(k.ltr);
    case 'case_selector':
      return resolveKey(k.lower || k.default);
    case 'shift_state_selector':
      return resolveKey(k.unshifted || k.default || k.shifted);
    case 'char_width_selector':
      return resolveKey(k.half || k.default || k.full);
    case 'kana_selector':
      return resolveKey(k.hira || k.default);
    case 'multi_text_key': {
      const cps = k.codePoints || [];
      return { code: KC.MULTIPLE_CODE_POINTS, label: k.label || cps.map((c) => String.fromCodePoint(c)).join(''),
               _output: cps.map((c) => String.fromCodePoint(c)).join('') };
    }
    case 'auto_text_key':
    case 'text_key':
      return k;
    default:
      return k.code !== undefined ? k : null;
  }
}

// Flatten an inline popup object {main, relevant:[...]} into an array of label strings.
function popupLabels(popup) {
  if (!popup) return [];
  const out = [];
  const push = (entry) => {
    const r = resolveKey(entry);
    if (r && typeof r.label === 'string' && r.label.length > 0) out.push(r.label);
  };
  if (popup.main) push(popup.main);
  if (Array.isArray(popup.relevant)) popup.relevant.forEach(push);
  return out;
}

// Load the English accent map (en.json): label -> [accent labels].
const enMap = (() => {
  const j = readJson(path.join(POPUPS, 'en.json'));
  const all = j.all || {};
  const m = {};
  for (const key of Object.keys(all)) {
    m[key] = popupLabels(all[key]);
  }
  return m;
})();

// Map a resolved key + its source row context to our flat schema.
function mapKey(k) {
  const r = resolveKey(k);
  if (!r) return null;
  if (r.type === 'placeholder') return { _placeholder: true };
  let code = r.code === undefined ? 0 : r.code;
  let label = r.label || '';
  let output = r._output !== undefined ? r._output : null;
  let kind = 'char';
  let target;
  let weight = 1;

  // Currency slots resolve to a literal western glyph; the primary slot ($)
  // long-presses to the other currencies (FlorisBoard's currency popup).
  if (code <= KC.CURRENCY_SLOT_1 && code >= KC.CURRENCY_SLOT_6) {
    const glyph = CURRENCY[String(code)] || '$';
    const others = Object.keys(CURRENCY)
      .map((k) => CURRENCY[k])
      .filter((g) => g !== glyph);
    return { code: glyph.codePointAt(0), label: glyph, output: glyph, kind: 'char', weight: 1, popups: others };
  }

  switch (code) {
    case KC.SHIFT: case KC.CAPS_LOCK: kind = 'shift'; weight = 1.5; label = 'shift'; break;
    case KC.DELETE: kind = 'delete'; weight = 1.5; label = 'delete'; break;
    case KC.ENTER: kind = 'enter'; weight = 1.5; label = 'enter'; break;
    case KC.SPACE: kind = 'space'; label = 'space'; break;
    case KC.LANGUAGE_SWITCH: kind = 'lang'; weight = 1; label = 'globe'; break;
    case KC.VIEW_CHARACTERS: case KC.IME_UI_MODE_TEXT: kind = 'view'; target = 'characters'; weight = 1.5; label = 'ABC'; break;
    case KC.VIEW_SYMBOLS: kind = 'view'; target = 'symbols'; weight = 1.5; label = '?123'; break;
    case KC.VIEW_SYMBOLS2: kind = 'view'; target = 'symbols2'; weight = 1.5; label = '=\\<'; break;
    case KC.VIEW_NUMERIC: case KC.VIEW_NUMERIC_ADVANCED: kind = 'view'; target = 'numeric'; weight = 1.5; label = '123'; break;
    case KC.IME_UI_MODE_MEDIA: case KC.IME_UI_MODE_CLIPBOARD: return null; // no media/clipboard panels in MVP
    case KC.URI_COMPONENT_TLD: kind = 'char'; output = label; break;
    default:
      kind = 'char';
      if (output === null) output = label;
      break;
  }

  // Popups: inline first, then English accent map for letters, then ~right symbol shortcuts on period.
  const popups = [];
  for (const p of popupLabels(r.popup)) if (!popups.includes(p)) popups.push(p);
  if (kind === 'char' && /^[a-z]$/.test(label) && enMap[label]) {
    for (const p of enMap[label]) if (!popups.includes(p)) popups.push(p);
  }
  if (r.groupId === 2 && enMap['~right']) { // period / ~right group → symbol shortcuts
    for (const p of enMap['~right']) if (!popups.includes(p)) popups.push(p);
  }

  const out = { code, label, kind, weight };
  if (target) out.target = target;
  if (output !== null && output !== label) out.output = output;
  if (kind === 'char' && output === null) out.output = label;
  if (popups.length) out.popups = popups;
  return out;
}

// Merge main layout rows with a mod layout (FlorisBoard LayoutManager.mergeLayouts):
// last main row fuses with mod row 0 at the placeholder; remaining mod rows append verbatim.
function merge(mainRows, modRows) {
  const result = [];
  for (let i = 0; i < mainRows.length - 1; i++) result.push(mainRows[i]);
  const lastMain = mainRows[mainRows.length - 1];
  const fused = [];
  for (const modKey of modRows[0]) {
    const mk = mapKey(modKey);
    if (mk && mk._placeholder) { for (const k of lastMain) fused.push(k); }
    else if (mk) fused.push(mk);
  }
  result.push(fused);
  for (let i = 1; i < modRows.length; i++) {
    const row = [];
    for (const k of modRows[i]) { const mk = mapKey(k); if (mk && !mk._placeholder) row.push(mk); }
    result.push(row);
  }
  return result;
}

// Distribute leftover width as edge spacers so short rows (e.g. a–l) stay centered.
function balanceRow(keys) {
  const total = keys.reduce((s, k) => s + (k.weight || 1), 0);
  const hasSpace = keys.some((k) => k.kind === 'space');
  if (hasSpace) {
    const others = total - keys.filter((k) => k.kind === 'space').reduce((s, k) => s + k.weight, 0);
    const space = keys.find((k) => k.kind === 'space');
    space.weight = Math.max(2, 10 - others);
    return keys;
  }
  if (total < 9.99) {
    const pad = (10 - total) / 2;
    return [{ kind: 'spacer', weight: pad }, ...keys, { kind: 'spacer', weight: pad }];
  }
  return keys;
}

function digitRow() {
  const digits = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0'];
  return digits.map((d) => ({ code: d.codePointAt(0), label: d, kind: 'char', weight: 1, output: d }));
}

// FlorisBoard renders a small corner "hint" on the characters layer: the number
// row (1-0) on the top row, and secondary symbols on the next two rows. The hint
// is also the first long-press popup, so it stays reachable. Applied per char
// key, in order, before edge spacers are inserted.
const HINT_ROWS = [
  ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0'],
  ['@', '#', '$', '%', '&', '-', '+', '(', ')'],
  ['*', '"', "'", ':', ';', '!', '?'],
];

function applyHints(rows) {
  for (let r = 0; r < HINT_ROWS.length && r < rows.length; r++) {
    const hints = HINT_ROWS[r];
    let hi = 0;
    for (const k of rows[r]) {
      if (k.kind !== 'char' || hi >= hints.length) continue;
      const h = hints[hi++];
      k.hint = h;
      const pops = Array.isArray(k.popups) ? k.popups.slice() : [];
      if (!pops.includes(h)) pops.unshift(h);
      k.popups = pops;
    }
  }
}

function assemble(name, mainPath, modPath, prependDigits) {
  const mainRaw = readJson(mainPath);
  const mainRows = mainRaw.map((row) => row.map(mapKey).filter((k) => k && !k._placeholder));
  const modRaw = readJson(modPath);
  const merged = merge(mainRows, modRaw);
  if (prependDigits) {
    merged.unshift(digitRow()); // FlorisBoard shows a 1234567890 row atop the symbol pages
  }
  if (name === 'characters') {
    applyHints(merged); // number-row + symbol corner hints, only on the letters layer
  }
  const rows = merged.map((keys) => ({ keys: balanceRow(keys) }));
  const layout = { name, rows };
  fs.writeFileSync(path.join(OUT, name + '.json'), JSON.stringify(layout, null, 2));
  const keyCount = rows.reduce((s, r) => s + r.keys.length, 0);
  console.log(`  ${name}.json: ${rows.length} rows, ${keyCount} keys`);
}

function assembleNumeric() {
  // Simple 4x3-ish numeric pad assembled by hand from the digit set + basic ops.
  const mk = (label, output) => ({ code: label.codePointAt(0), label, kind: 'char', weight: 1, output: output || label });
  const rows = [
    { keys: [mk('1'), mk('2'), mk('3'), mk('-'), { code: KC.DELETE, label: 'delete', kind: 'delete', weight: 1 }] },
    { keys: [mk('4'), mk('5'), mk('6'), mk('/'), mk('(')] },
    { keys: [mk('7'), mk('8'), mk('9'), mk(')'), mk(':')] },
    { keys: [
      { code: KC.VIEW_CHARACTERS, label: 'ABC', kind: 'view', target: 'characters', weight: 1 },
      mk(','), mk('0'), mk('.'),
      { code: KC.ENTER, label: 'enter', kind: 'enter', weight: 1 },
    ] },
  ];
  fs.writeFileSync(path.join(OUT, 'numeric.json'), JSON.stringify({ name: 'numeric', rows }, null, 2));
  console.log('  numeric.json: 4 rows (hand-built)');
}

fs.mkdirSync(OUT, { recursive: true });
console.log('Converting FlorisBoard layouts → ' + OUT);
assemble('characters', path.join(LAYOUTS, 'characters/qwerty.json'), path.join(LAYOUTS, 'charactersMod/default.json'), false);
assemble('symbols', path.join(LAYOUTS, 'symbols/western.json'), path.join(LAYOUTS, 'symbolsMod/default.json'), true);
assemble('symbols2', path.join(LAYOUTS, 'symbols2/western.json'), path.join(LAYOUTS, 'symbols2Mod/default.json'), true);
assembleNumeric();
console.log('Done.');

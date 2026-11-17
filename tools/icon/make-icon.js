// Render FlorisBoard's adaptive-icon vector drawable as the OpenHarmony icon layers.
// usage: npm i @resvg/resvg-js@2.6.2 && node tools/icon/make-icon.js \
//   <florisboard>/app/src/main/res/drawable/ic_app_icon_stable_foreground.xml <outdir>
// then copy foreground.png and background.png to AppScope/ and entry/ base/media, and
// startIcon.png to entry/; preview.png is only for looking at.
const fs = require('fs');
const path = require('path');
const { Resvg } = require('@resvg/resvg-js');

const [, , xmlPath, outDir] = process.argv;
const xml = fs.readFileSync(xmlPath, 'utf8');
const BG = '#3D3E42'; // @color/ic_app_icon_background

let defs = '';
let body = '';
let gi = 0;
const pathRe = /<path([\s\S]*?)(\/>|>([\s\S]*?)<\/path>)/g;
let m;
while ((m = pathRe.exec(xml))) {
  const attrs = m[1];
  const inner = m[3] || '';
  const a = (n) => (attrs.match(new RegExp(`android:${n}="([^"]*)"`)) || [])[1];
  const d = a('pathData');
  const rule = a('fillType') === 'evenOdd' ? 'evenodd' : 'nonzero';
  let fill = a('fillColor');
  const g = inner.match(/<gradient([\s\S]*?)>([\s\S]*?)<\/gradient>/);
  if (g) {
    const ga = (n) => (g[1].match(new RegExp(`android:${n}="([^"]*)"`)) || [])[1];
    const stops = [...g[2].matchAll(/android:offset="([^"]*)"\s+android:color="#(?:FF)?([0-9A-Fa-f]{6})"/g)]
      .map((s) => `<stop offset="${s[1]}" stop-color="#${s[2]}"/>`).join('');
    const id = `g${gi++}`;
    defs += `<radialGradient id="${id}" gradientUnits="userSpaceOnUse" cx="${ga('centerX')}" cy="${ga('centerY')}" r="${ga('gradientRadius')}">${stops}</radialGradient>`;
    fill = `url(#${id})`;
  }
  body += `<path d="${d}" fill="${fill}" fill-rule="${rule}"/>`;
}

// Android shows the middle 72dp of the 108dp adaptive canvas; OpenHarmony 7.0's launcher
// shows the whole layer in a circle, so the layers cover exactly that 72dp window.
const VB = '18 18 72 72';
const svg = (content, extraDefs = '') =>
  `<svg xmlns="http://www.w3.org/2000/svg" viewBox="${VB}"><defs>${defs}${extraDefs}</defs>${content}</svg>`;
const render = (s, size, file) => {
  const png = new Resvg(s, { fitTo: { mode: 'width', value: size } }).render().asPng();
  fs.writeFileSync(path.join(outDir, file), png);
};

fs.mkdirSync(outDir, { recursive: true });
render(svg(body), 1024, 'foreground.png');
render(svg(`<rect x="18" y="18" width="72" height="72" fill="${BG}"/>`), 1024, 'background.png');
// Splash / About icon: the composed icon in a circle.
render(svg(`<g clip-path="url(#c)"><rect x="18" y="18" width="72" height="72" fill="${BG}"/>${body}</g>`,
  `<clipPath id="c"><circle cx="54" cy="54" r="36"/></clipPath>`), 288, 'startIcon.png');
render(svg(`<g clip-path="url(#c)"><rect x="18" y="18" width="72" height="72" fill="${BG}"/>${body}</g>`,
  `<clipPath id="c"><circle cx="54" cy="54" r="36"/></clipPath>`), 512, 'preview.png');
console.log('ok', gi, 'gradients');

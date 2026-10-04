// Renders assets/branding/icon.svg to the PNGs used by flutter_launcher_icons,
// flutter_native_splash and the store listings. Needs Playwright + Chromium:
//   node tool/render_branding.js
const fs = require('fs');
const path = require('path');
let chromium;
try {
  ({ chromium } = require('playwright'));
} catch {
  ({ chromium } = require('/opt/node22/lib/node_modules/playwright'));
}

const dir = path.join(__dirname, '..', 'assets', 'branding');
const svg = fs.readFileSync(path.join(dir, 'icon.svg'), 'utf8');
// Foreground only (no background), scaled into the adaptive-icon safe zone.
const fg = svg
  .replace(/<g id="background">[\s\S]*?<\/g>\n/, '')
  .replace('<use href="#masks"/>', '<g transform="translate(512 512) scale(0.62) translate(-512 -512)"><use href="#masks"/></g>');

const font = fs
  .readFileSync(path.join(__dirname, '..', 'assets', 'fonts', 'Vazirmatn-Black.ttf'))
  .toString('base64');
const html = (body, w, h, bg = 'transparent') =>
  `<html><head><style>@font-face{font-family:Vazirmatn;src:url(data:font/ttf;base64,${font})}</style></head>` +
  `<body style="margin:0;background:${bg};width:${w}px;height:${h}px;overflow:hidden">${body}</body></html>`;
// Masks only, without the safe-zone shrink (for wide banners).
const bigMasks = svg
  .replace(/<g id="background">[\s\S]*?<\/g>\n/, '');

(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage({ deviceScaleFactor: 1 });
  const shot = async (body, w, h, file, bg) => {
    await page.setViewportSize({ width: w, height: h });
    await page.setContent(html(body, w, h, bg));
    await page.screenshot({ path: path.join(dir, file), omitBackground: !bg });
    console.log('wrote', file);
  };
  const sized = (s, w, h) => s.replace('width="1024" height="1024"', `width="${w}" height="${h}"`);
  await shot(sized(svg, 1024, 1024), 1024, 1024, 'icon_1024.png');
  await shot(sized(svg, 512, 512), 512, 512, 'icon_512.png');
  await shot(sized(fg, 1024, 1024), 1024, 1024, 'icon_foreground.png');
  // Splash logo: masks only, transparent.
  await shot(sized(fg, 768, 768), 768, 768, 'splash_logo.png');
  // Google Play feature graphic 1024×500 (also usable as a Bazaar banner).
  await shot(
    `<div style="width:1024px;height:500px;display:flex;align-items:center;justify-content:center;gap:28px;
      background:radial-gradient(circle at 30% 40%,#5A36C9,#2A1B5C 60%,#1A0F3D);font-family:Vazirmatn,Tahoma,sans-serif">
      ${sized(bigMasks, 440, 440)}
      <div dir="rtl" style="color:#FFD23F;font-size:96px;font-weight:900;line-height:1.25;text-shadow:0 6px 0 #120A2B">پانتومیم<br>دورهمی</div>
     </div>`,
    1024, 500, 'feature_graphic_1024x500.png', '#1A0F3D');
  // Web / PWA (web/) and the landing page assets (assets/branding/landing/).
  const web = path.join(__dirname, '..', 'web');
  // Landing page assets: copy them to espadna-site/public/pantomime-app/.
const site = path.join(__dirname, '..', 'assets', 'branding', 'landing');
  const maskable = svg.replace('<use href="#masks"/>',
    '<g transform="translate(512 512) scale(0.62) translate(-512 -512)"><use href="#masks"/></g>');
  const shotTo = async (body, w, h, file, bg) => {
    await page.setViewportSize({ width: w, height: h });
    await page.setContent(html(body, w, h, bg));
    await page.screenshot({ path: file, omitBackground: !bg });
    console.log('wrote', path.relative(path.join(__dirname, '..'), file));
  };
  for (const n of [192, 512]) {
    await shotTo(sized(svg, n, n), n, n, path.join(web, 'icons', `Icon-${n}.png`));
    await shotTo(sized(maskable, n, n), n, n, path.join(web, 'icons', `Icon-maskable-${n}.png`));
  }
  await shotTo(sized(svg, 64, 64), 64, 64, path.join(web, 'favicon.png'));
  await shotTo(sized(svg, 180, 180), 180, 180, path.join(site, 'icon.png'));
  await shotTo(sized(svg, 64, 64), 64, 64, path.join(site, 'favicon.png'));
  // Link preview (Telegram / WhatsApp / X): 1200×630.
  await shotTo(
    `<div style="width:1200px;height:630px;display:flex;align-items:center;justify-content:center;gap:40px;
      background:radial-gradient(circle at 30% 40%,#5A36C9,#2A1B5C 60%,#1A0F3D);font-family:Vazirmatn,Tahoma,sans-serif">
      ${sized(bigMasks, 500, 500)}
      <div dir="rtl" style="color:#FFD23F;font-size:110px;font-weight:900;line-height:1.25;text-shadow:0 6px 0 #120A2B">پانتومیم<br>دورهمی
        <div style="color:#fff;font-size:44px;font-weight:900;text-shadow:none;margin-top:10px">بی‌صدا بازی کن، بلند بخند!</div></div>
     </div>`,
    1200, 630, path.join(site, 'og.png'), '#1A0F3D');
  const enBanner = (w, h, mask, title, sub, file) => shotTo(
    `<div style="width:${w}px;height:${h}px;display:flex;align-items:center;justify-content:center;gap:40px;
      background:radial-gradient(circle at 30% 40%,#5A36C9,#2A1B5C 60%,#1A0F3D);font-family:Vazirmatn,Tahoma,sans-serif">
      ${sized(bigMasks, mask, mask)}
      <div style="color:#FFD23F;font-size:${title}px;font-weight:900;line-height:1.1;text-shadow:0 6px 0 #120A2B">Pantomime<br>Party
        <div style="color:#fff;font-size:${sub}px;font-weight:900;text-shadow:none;margin-top:16px">Act it out, laugh out loud!</div></div>
     </div>`, w, h, file, '#1A0F3D');
  await enBanner(1200, 630, 480, 120, 44, path.join(site, 'og_en.png'));
  await enBanner(1024, 500, 400, 100, 36, path.join(dir, 'feature_graphic_en_1024x500.png'));
  await browser.close();
})();

import { chromium } from '/opt/node22/lib/node_modules/playwright/index.mjs';
const b = await chromium.launch(); const p = await b.newPage({ viewport: { width: 1290, height: 2796 } });
await p.goto('file://'+process.cwd()+'/p3.html'); await p.waitForTimeout(500);
await p.screenshot({ path: 'heads_up_poster.png' });
await p.screenshot({ path: 'crop.png', clip: { x: 430, y: 980, width: 430, height: 270 } });
await b.close();

import { chromium } from '/opt/node22/lib/node_modules/playwright/index.mjs';
const b = await chromium.launch({args:['--allow-file-access-from-files']}); const p = await b.newPage({ viewport: { width: 1290, height: 2796 } });
for (const n of ['p2','p3','p4','p5']) { await p.goto('file://'+process.cwd()+'/'+n+'.html'); await p.waitForTimeout(800); await p.screenshot({ path: 'out_'+n+'.png' }); }
await b.close();

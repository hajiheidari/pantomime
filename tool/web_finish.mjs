// Post-processes `flutter build web` into build/site:
//   build/site/            landing page (web_site/)
//   build/site/play/       the game, relative base href, offline service worker
//   build/site/_headers    cache rules for Cloudflare static assets
//   build/pantomime-web.zip  the same folder for a mirror host (upload + unzip)
import { createHash } from 'node:crypto';
import { cpSync, existsSync, readdirSync, readFileSync, rmSync, statSync, writeFileSync } from 'node:fs';
import { execFileSync } from 'node:child_process';
import { join, relative } from 'node:path';

const root = new URL('..', import.meta.url).pathname;
const web = join(root, 'build/web');
const site = join(root, 'build/site');
const play = join(site, 'play');
const siteUrl = (process.env.SITE_URL || 'https://pantomime.sepanta-hesaban.workers.dev').replace(/\/$/, '');
const configUrl = (() => {
  try {
    return JSON.parse(readFileSync(join(root, 'ad_keys.json'), 'utf8')).CONFIG_URL;
  } catch {
    return 'https://pantomime-config.sepanta-hesaban.workers.dev/config.json';
  }
})();

rmSync(site, { recursive: true, force: true });
cpSync(join(root, 'web_site'), site, { recursive: true });
cpSync(join(root, 'assets/fonts/Vazirmatn-Bold.ttf'), join(site, 'Vazirmatn-Bold.ttf'));
cpSync(web, play, { recursive: true });

const walk = (dir) => readdirSync(dir).flatMap((f) => {
  const p = join(dir, f);
  return statSync(p).isDirectory() ? walk(p) : [p];
});

// Not needed at runtime: debug symbols, Flutter's deprecated worker, template.
for (const f of walk(play)) {
  if (f.endsWith('.symbols') || /flutter_service_worker\.js$|sw\.template\.js$/.test(f)) rmSync(f);
}

// Relative base href: works at /play/ and at /<any>/play/ on a mirror.
const indexPath = join(play, 'index.html');
writeFileSync(indexPath, readFileSync(indexPath, 'utf8').replace(/<base href="[^"]*">/, '<base href="./">'));

// Landing page placeholders.
const landing = join(site, 'index.html');
writeFileSync(landing, readFileSync(landing, 'utf8')
  .replaceAll('__SITE_URL__', siteUrl)
  .replaceAll('__CONFIG_ORIGIN__', new URL(configUrl).origin));

// Service worker: precache the shell, not the big CanvasKit variants.
const files = walk(play)
  .map((f) => relative(play, f).split('\\').join('/'))
  .filter((f) => !f.startsWith('canvaskit/') && f !== 'sw.js')
  .sort();
const hash = createHash('sha256');
for (const f of files) hash.update(f).update(readFileSync(join(play, f)));
const version = hash.digest('hex').slice(0, 12);
const sw = readFileSync(join(root, 'web/sw.template.js'), 'utf8')
  .replace('__VERSION__', version)
  .replace('__PRECACHE__', JSON.stringify(['./', ...files.filter((f) => f !== 'index.html')], null, 2));
writeFileSync(join(play, 'sw.js'), sw);

// Cloudflare static-asset headers.
writeFileSync(join(site, '_headers'), `/*
  X-Content-Type-Options: nosniff
  Referrer-Policy: strict-origin-when-cross-origin
/play/sw.js
  Cache-Control: no-cache
/play/index.html
  Cache-Control: no-cache
/play/main.dart.js
  Cache-Control: no-cache
/play/flutter_bootstrap.js
  Cache-Control: no-cache
/play/canvaskit/*
  Cache-Control: public, max-age=604800
/play/assets/*
  Cache-Control: public, max-age=3600
`);

// Zip for a mirror host.
const zip = join(root, 'build/pantomime-web.zip');
rmSync(zip, { force: true });
if (existsSync('/usr/bin/zip')) {
  execFileSync('zip', ['-qr', zip, '.', '-x', '_headers'], { cwd: site });
}
const size = walk(site).reduce((n, f) => n + statSync(f).size, 0);
console.log(`build/site: ${files.length} precached files, sw ${version}, ${(size / 1e6).toFixed(1)} MB total`);

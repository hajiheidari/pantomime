// Post-processes `flutter build web`:
//   build/game/            the game (→ pantomime.espadna.com), relative base
//                          href, offline service worker, _headers/_redirects
//   build/pantomime-web.zip  build/game for a mirror host (upload + unzip)
// The landing pages on espadna.com live in hajiheidari/espadna-site.
import { createHash } from 'node:crypto';
import { cpSync, existsSync, readdirSync, readFileSync, rmSync, statSync, writeFileSync } from 'node:fs';
import { execFileSync } from 'node:child_process';
import { join, relative } from 'node:path';

const root = new URL('..', import.meta.url).pathname;
const web = join(root, 'build/web');
const play = join(root, 'build/game');

rmSync(play, { recursive: true, force: true });
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

// Service worker: precache the shell, not the big CanvasKit variants.
const files = walk(play)
  .map((f) => relative(play, f).split('\\').join('/'))
  .filter((f) => !f.startsWith('canvaskit/') && f !== 'sw.js' && f !== 'speed.html')
  .sort();
const hash = createHash('sha256');
for (const f of files) hash.update(f).update(readFileSync(join(play, f)));
const version = hash.digest('hex').slice(0, 12);
const sw = readFileSync(join(root, 'web/sw.template.js'), 'utf8')
  .replace('__VERSION__', version)
  .replace('__PRECACHE__', JSON.stringify(['./', ...files.filter((f) => f !== 'index.html')], null, 2));
writeFileSync(join(play, 'sw.js'), sw);

// Cloudflare static-asset headers and redirects for the game.
writeFileSync(join(play, '_headers'), `/*
  X-Content-Type-Options: nosniff
  Access-Control-Allow-Origin: *
  Referrer-Policy: strict-origin-when-cross-origin
/sw.js
  Cache-Control: no-cache
/index.html
  Cache-Control: no-cache
/main.dart.js
  Cache-Control: no-cache
/flutter_bootstrap.js
  Cache-Control: no-cache
/canvaskit/*
  Cache-Control: public, max-age=604800
/assets/*
  Cache-Control: public, max-age=3600
`);
// Old links (the first web release had the game at /play/ and the landing
// pages on the same host).
writeFileSync(join(play, '_redirects'), `/play/* /:splat 301
/en/ https://espadna.com/pantomime-app/en/ 301
`);

// Zip for a mirror host.
const zip = join(root, 'build/pantomime-web.zip');
rmSync(zip, { force: true });
if (existsSync('/usr/bin/zip')) {
  execFileSync('zip', ['-qr', zip, '.', '-x', '_headers', '_redirects'], { cwd: play });
}
const size = walk(play).reduce((n, f) => n + statSync(f).size, 0);
console.log(`build/game: ${files.length} precached files, sw ${version}, ${(size / 1e6).toFixed(1)} MB`);

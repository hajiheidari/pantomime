// Runs server/mirror/pantomime-config.php under `php -S` against a fake
// source. Skipped when PHP is not installed.
import assert from 'node:assert/strict';
import { spawn, spawnSync } from 'node:child_process';
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { createServer } from 'node:http';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { after, before, test } from 'node:test';

const hasPhp = spawnSync('php', ['-v']).status === 0;
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

let source = { status: 503, body: "down" }; // what the fake source returns
let sourceServer;
let php;
let dir;
let base;

before(async () => {
  if (!hasPhp) return;
  sourceServer = createServer((req, res) => {
    res.writeHead(source.status, { 'content-type': 'application/json' });
    res.end(source.body);
  });
  await new Promise((r) => sourceServer.listen(0, '127.0.0.1', r));
  const srcUrl = `http://127.0.0.1:${sourceServer.address().port}/config.json`;
  dir = mkdtempSync(join(tmpdir(), 'mirror-'));
  const code = readFileSync(new URL('../mirror/pantomime-config.php', import.meta.url), 'utf8')
    .replace(/const SOURCE_URL = '[^']*';/, `const SOURCE_URL = '${srcUrl}';`)
    .replace('const TTL_SECONDS = 300;', 'const TTL_SECONDS = 0;');
  writeFileSync(join(dir, 'm.php'), code);
  const port = 18000 + Math.floor(Math.random() * 1000);
  php = spawn('php', ['-S', `127.0.0.1:${port}`, '-t', dir], { stdio: 'ignore' });
  base = `http://127.0.0.1:${port}/m.php`;
  for (let i = 0; i < 50; i++) {
    try {
      await fetch(base, { method: 'HEAD' });
      break;
    } catch {
      await sleep(100);
    }
  }
});

after(() => {
  php?.kill();
  sourceServer?.close();
  if (dir) rmSync(dir, { recursive: true, force: true });
});

const cfg = (v, extra = {}) => JSON.stringify({ config_version: v, ads: { enabled: true }, ...extra });
const get = async () => {
  const res = await fetch(base);
  return { res, body: await res.json() };
};

test('PHP mirror: default, fetch, keep last good, never downgrade', { skip: !hasPhp }, async () => {
  // Source down and nothing cached → bundled default (valid config).
  source = { status: 503, body: 'down' };
  let { res, body } = await get();
  assert.equal(res.status, 200);
  assert.equal(res.headers.get('content-type'), 'application/json; charset=utf-8');
  assert.equal(res.headers.get('cache-control'), 'public, max-age=300');
  assert.equal(body.config_version, 0);

  // Source up → mirrored.
  source = { status: 200, body: cfg(7, { message: 'سلام' }) };
  ({ body } = await get());
  assert.equal(body.config_version, 7);
  assert.equal(body.message, 'سلام');

  // Source down again → last good copy.
  source = { status: 500, body: '' };
  await sleep(1100);
  ({ body } = await get());
  assert.equal(body.config_version, 7);

  // Older version (stale source) or garbage → ignored.
  source = { status: 200, body: cfg(3) };
  await sleep(1100);
  ({ body } = await get());
  assert.equal(body.config_version, 7);
  source = { status: 200, body: '<html>blocked</html>' };
  await sleep(1100);
  ({ body } = await get());
  assert.equal(body.config_version, 7);

  // Newer → applied.
  source = { status: 200, body: cfg(8) };
  await sleep(1100);
  ({ body } = await get());
  assert.equal(body.config_version, 8);

  // Only GET/HEAD.
  assert.equal((await fetch(base, { method: 'POST', body: 'x' })).status, 405);
});

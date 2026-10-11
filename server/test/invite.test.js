import assert from 'node:assert/strict';
import { test } from 'node:test';

import worker from '../src/index.js';
import { FakeKV } from './helpers.js';

const ctx = { waitUntil() {} };
const call = (env, method, ip, code = 'K7Q2ABCD') =>
  worker.fetch(
    new Request(`https://w.example/invite/${code}`, { method, headers: { 'cf-connecting-ip': ip } }),
    env,
    ctx,
  );
const visits = async (env, ip) => (await (await call(env, 'GET', ip)).json()).visits;

test('a friend opening the link counts once; the owner never counts', async () => {
  const env = { CONFIG: new FakeKV() };
  assert.equal(await visits(env, '1.1.1.1'), 0); // owner checks first
  assert.equal((await call(env, 'POST', '1.1.1.1')).status, 204); // owner opens own link
  assert.equal(await visits(env, '1.1.1.1'), 0);
  await call(env, 'POST', '2.2.2.2');
  await call(env, 'POST', '2.2.2.2');
  assert.equal(await visits(env, '1.1.1.1'), 1);
  await call(env, 'POST', '3.3.3.3');
  assert.equal(await visits(env, '1.1.1.1'), 2);
});

test('no raw IP is stored', async () => {
  const kv = new FakeKV();
  await call({ CONFIG: kv }, 'POST', '9.8.7.6');
  assert.ok(![...kv.map.values()].some((v) => v.includes('9.8.7.6')));
});

test('bad codes are rejected', async () => {
  const res = await call({ CONFIG: new FakeKV() }, 'POST', '1.1.1.1', 'bad<code>');
  assert.equal(res.status, 400);
});

test('GET without changes does not write again', async () => {
  const kv = new FakeKV();
  await visits({ CONFIG: kv }, '1.1.1.1');
  await visits({ CONFIG: kv }, '1.1.1.1');
  assert.equal(kv.puts.length, 1);
});

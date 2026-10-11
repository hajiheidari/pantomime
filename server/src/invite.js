// Invite links: the app shares its landing page with ?i=<code>; the page's
// script reports the visit here, and the app asks how many people opened it
// (one real visit unlocks the special word categories for good).
//
//   GET  /invite/<code>  → {"visits": n}; remembers the caller as the owner
//   POST /invite/<code>  → counts one visit (once per visitor, never the owner)
//
// Visitors are told apart by a hash of their IP mixed with the code: no raw
// IP is stored, and the same person can't be linked across codes.
// The Iranian copy of this lives in espadna-site/mirror-ir/invite.php.

export const CODE = /^[A-Z2-9]{6,12}$/;
const MAX_VISITORS = 50;
const TTL = 400 * 24 * 3600;

const HEADERS = {
  'content-type': 'application/json; charset=utf-8',
  'cache-control': 'no-store',
  'access-control-allow-origin': '*',
};

async function visitorHash(request, code) {
  const ip = request.headers.get('cf-connecting-ip') ?? '';
  const data = new TextEncoder().encode(`${code}|${ip}`);
  const digest = new Uint8Array(await crypto.subtle.digest('SHA-256', data));
  return [...digest.slice(0, 8)].map((b) => b.toString(16).padStart(2, '0')).join('');
}

export async function handleInvite(request, env, code) {
  if (!CODE.test(code)) return new Response('bad code', { status: 400, headers: HEADERS });
  const key = `invite:${code}`;
  const record = (await env.CONFIG.get(key, 'json')) ?? { n: 0, h: [], o: null };
  const me = await visitorHash(request, code);
  const save = () => env.CONFIG.put(key, JSON.stringify(record), { expirationTtl: TTL });

  if (request.method === 'POST') {
    if (me !== record.o && !record.h.includes(me)) {
      record.n += 1;
      record.h = [...record.h, me].slice(-MAX_VISITORS);
      await save();
    }
    return new Response(null, { status: 204, headers: HEADERS });
  }
  if (request.method === 'GET' || request.method === 'HEAD') {
    if (record.o !== me) {
      record.o = me;
      await save();
    }
    return new Response(JSON.stringify({ visits: record.n }), { headers: HEADERS });
  }
  return new Response('method not allowed', { status: 405, headers: HEADERS });
}

// Optional: copy config.json to an S3-compatible bucket after every change,
// so a second host (e.g. ArvanCloud Object Storage, reachable inside Iran)
// always serves the same file. Enabled when the MIRROR_* secrets are set.
//
// Minimal AWS Signature V4 for a single PUT, using Web Crypto.

const enc = new TextEncoder();

const hex = (buf) =>
  [...new Uint8Array(buf)].map((b) => b.toString(16).padStart(2, '0')).join('');

export async function sha256Hex(data) {
  return hex(await crypto.subtle.digest('SHA-256', typeof data === 'string' ? enc.encode(data) : data));
}

async function hmac(key, data) {
  const k = await crypto.subtle.importKey(
    'raw',
    typeof key === 'string' ? enc.encode(key) : key,
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign'],
  );
  return crypto.subtle.sign('HMAC', k, enc.encode(data));
}

/** SigV4 signing key: HMAC chain over date, region, service. */
export async function signingKey(secret, date, region, service) {
  const kDate = await hmac(`AWS4${secret}`, date);
  const kRegion = await hmac(kDate, region);
  const kService = await hmac(kRegion, service);
  return hmac(kService, 'aws4_request');
}

/** Returns signed headers for a PUT of `body` to `url`. */
export async function signPut({
  url,
  body,
  contentType,
  accessKeyId,
  secretAccessKey,
  region,
  extraHeaders = {},
  now = new Date(),
}) {
  const u = new URL(url);
  const amzDate = now.toISOString().replace(/[:-]|\.\d{3}/g, ''); // 20260101T120000Z
  const date = amzDate.slice(0, 8);
  const payloadHash = await sha256Hex(body);
  const headers = {
    'content-type': contentType,
    host: u.host,
    'x-amz-content-sha256': payloadHash,
    'x-amz-date': amzDate,
    ...Object.fromEntries(Object.entries(extraHeaders).map(([k, v]) => [k.toLowerCase(), v])),
  };
  const signedHeaders = Object.keys(headers).sort().join(';');
  const canonicalHeaders = Object.keys(headers)
    .sort()
    .map((k) => `${k}:${headers[k]}\n`)
    .join('');
  const canonicalRequest = [
    'PUT',
    u.pathname.split('/').map(encodeURIComponent).join('/'),
    '',
    canonicalHeaders,
    signedHeaders,
    payloadHash,
  ].join('\n');
  const scope = `${date}/${region}/s3/aws4_request`;
  const stringToSign = ['AWS4-HMAC-SHA256', amzDate, scope, await sha256Hex(canonicalRequest)].join('\n');
  const signature = hex(await hmac(await signingKey(secretAccessKey, date, region, 's3'), stringToSign));
  return {
    ...headers,
    authorization: `AWS4-HMAC-SHA256 Credential=${accessKeyId}/${scope}, SignedHeaders=${signedHeaders}, Signature=${signature}`,
  };
}

export function mirrorEnabled(env) {
  return Boolean(env.MIRROR_ENDPOINT && env.MIRROR_BUCKET && env.MIRROR_ACCESS_KEY_ID && env.MIRROR_SECRET_ACCESS_KEY);
}

/**
 * Uploads the config JSON to `<endpoint>/<bucket>/<key>` (path-style).
 * Returns true on success. Never throws.
 */
export async function pushToMirror(env, json, fetchFn = fetch) {
  if (!mirrorEnabled(env)) return false;
  try {
    const url = `${env.MIRROR_ENDPOINT.replace(/\/$/, '')}/${env.MIRROR_BUCKET}/${env.MIRROR_KEY ?? 'config.json'}`;
    const headers = await signPut({
      url,
      body: json,
      contentType: 'application/json',
      accessKeyId: env.MIRROR_ACCESS_KEY_ID,
      secretAccessKey: env.MIRROR_SECRET_ACCESS_KEY,
      region: env.MIRROR_REGION ?? 'default',
      extraHeaders: { 'x-amz-acl': 'public-read', 'cache-control': 'max-age=300' },
    });
    const res = await fetchFn(url, { method: 'PUT', headers, body: json });
    return res.ok;
  } catch {
    return false;
  }
}

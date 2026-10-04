// Config schema shared with the app (lib/features/ads/config/remote_config.dart).
// The bot validates every change with the same rules the app applies, so the
// bot can never publish a config the app would reject.

export const PROVIDERS = ['adivery', 'tapsell', 'admob'];
export const STORES = ['play', 'bazaar', 'myket', 'ios'];
export const SPLIT_STORES = ['play', 'bazaar', 'myket'];

/** AdMob (Google Play Services) is not allowed in Bazaar / Myket builds. */
export const storeAllows = (store, provider) =>
  !(provider === 'admob' && (store === 'bazaar' || store === 'myket'));

/** Editable id fields per provider (as in the JSON). */
export const ID_FIELDS = {
  adivery: ['app_id', 'interstitial_placement', 'rewarded_placement', 'banner_placement'],
  tapsell: ['app_key', 'interstitial_zone', 'rewarded_zone', 'banner_zone'],
  admob_android: ['interstitial', 'rewarded', 'banner'],
  admob_ios: ['interstitial', 'rewarded', 'banner'],
};

/** Characters a pasted id can carry by accident: quotes of every kind and
 * invisible direction marks / zero-width characters. */
const ID_JUNK = /^[\s"'`«»“”„‘’‹›<>\u200b-\u200f\u202a-\u202e\u2066-\u2069\ufeff]+|[\s"'`«»“”„‘’‹›<>\u200b-\u200f\u202a-\u202e\u2066-\u2069\ufeff]+$/g;

/** Cleans a pasted ad id: trims whitespace, wrapping quotes and invisible
 * characters (same rule as `cleanAdId` in the app). */
export const cleanId = (value) => String(value ?? '').replace(ID_JUNK, '');

/** Ad ids are plain tokens: letters, digits and `-_.:~/`. */
export const isValidId = (value) => /^[A-Za-z0-9._:~\/-]{1,200}$/.test(value);

export class ConfigError extends Error {}

const fail = (msg) => {
  throw new ConfigError(msg);
};
const isObj = (v) => v !== null && typeof v === 'object' && !Array.isArray(v);
const isInt = (v) => Number.isInteger(v);

function provider(v, where) {
  if (!PROVIDERS.includes(v)) fail(`${where}: unknown provider "${v}"`);
  return v;
}
function store(k, where) {
  if (!STORES.includes(k)) fail(`${where}: unknown store "${k}"`);
  return k;
}
function allowed(s, p, where) {
  if (!storeAllows(s, p)) fail(`${where}: admob is not allowed on ${s}`);
}

/** Throws ConfigError unless `c` is a config the app accepts. */
export function validateConfig(c) {
  if (!isObj(c)) fail('config must be an object');
  if (!isInt(c.config_version) || c.config_version < 0) fail('config_version');
  const ads = c.ads;
  if (!isObj(ads)) fail('ads');
  if (typeof ads.enabled !== 'boolean') fail('ads.enabled');

  if (!isObj(ads.active_provider)) fail('active_provider');
  for (const [s, p] of Object.entries(ads.active_provider)) {
    store(s, 'active_provider');
    provider(p, 'active_provider');
    allowed(s, p, 'active_provider');
  }

  if (ads.ab_split != null) {
    if (!isObj(ads.ab_split)) fail('ab_split');
    for (const [s, parts] of Object.entries(ads.ab_split)) {
      store(s, 'ab_split');
      if (parts == null) continue;
      if (!isObj(parts)) fail('ab_split');
      let sum = 0;
      let n = 0;
      for (const [p, pct] of Object.entries(parts)) {
        provider(p, 'ab_split');
        allowed(s, p, 'ab_split');
        if (!isInt(pct) || pct < 0 || pct > 100) fail('ab_split percent');
        sum += pct;
        n++;
      }
      if (n > 0 && sum !== 100) fail(`ab_split for ${s} must sum to 100 (got ${sum})`);
    }
  }

  if (ads.fallback_chain != null) {
    if (!isObj(ads.fallback_chain)) fail('fallback_chain');
    for (const [s, list] of Object.entries(ads.fallback_chain)) {
      store(s, 'fallback_chain');
      if (!Array.isArray(list)) fail('fallback_chain');
      for (const p of list) {
        provider(p, 'fallback_chain');
        allowed(s, p, 'fallback_chain');
      }
    }
  }

  if (ads.providers != null) {
    if (!isObj(ads.providers)) fail('providers');
    for (const [p, fields] of Object.entries(ads.providers)) {
      provider(p, 'providers');
      if (!isObj(fields)) fail(`providers.${p}`);
      const check = (obj, keys, where) => {
        for (const k of keys) {
          const v = obj[k];
          if (v == null) continue;
          if (typeof v !== 'string' || v.length > 200) fail(`${where}.${k}`);
        }
      };
      if (p === 'admob') {
        for (const plat of ['android', 'ios']) {
          if (fields[plat] == null) continue;
          if (!isObj(fields[plat])) fail(`providers.admob.${plat}`);
          check(fields[plat], ID_FIELDS.admob_android, `providers.admob.${plat}`);
        }
      } else {
        check(fields, ID_FIELDS[p], `providers.${p}`);
      }
    }
  }

  const every = ads.interstitial_every_n_rounds ?? 3;
  if (!isInt(every) || every < 1 || every > 10) fail('interstitial_every_n_rounds');
  for (const k of ['banner_on_home', 'rewarded_enabled']) {
    if (ads[k] != null && typeof ads[k] !== 'boolean') fail(k);
  }

  const mv = c.min_supported_version ?? '0.0.0';
  if (typeof mv !== 'string' || !/^\d+\.\d+\.\d+$/.test(mv)) fail('min_supported_version');
  if (c.message != null && (typeof c.message !== 'string' || c.message.length > 500)) {
    fail('message');
  }
  return c;
}

export const clone = (c) => JSON.parse(JSON.stringify(c));

/** Shows the first and last 3 characters only. */
export function mask(value) {
  if (typeof value !== 'string' || value.length === 0) return '∅';
  if (value.length <= 8) return '•'.repeat(value.length);
  return `${value.slice(0, 3)}…${value.slice(-3)}`;
}

/** Copy of the config with every ad id masked (for /show). */
export function maskedConfig(c) {
  const out = clone(c);
  const providers = out.ads?.providers ?? {};
  for (const [p, fields] of Object.entries(providers)) {
    if (p === 'admob') {
      for (const plat of Object.values(fields)) {
        for (const k of Object.keys(plat)) plat[k] = mask(plat[k]);
      }
    } else {
      for (const k of Object.keys(fields)) fields[k] = mask(fields[k]);
    }
  }
  return out;
}

/** Short human summary for bot replies. */
export function summary(c) {
  const a = c.ads;
  const lines = [
    `📦 config v${c.config_version}`,
    `Ads: ${a.enabled ? 'ON ✅' : 'OFF ⛔'} · interstitial every ${a.interstitial_every_n_rounds ?? 3} turns`,
    `Banner: ${a.banner_on_home === false ? 'off' : 'on'} · Rewarded: ${a.rewarded_enabled === false ? 'off' : 'on'}`,
    '',
  ];
  for (const s of STORES) {
    const split = a.ab_split?.[s];
    const splitText = split
      ? ` · A/B ${Object.entries(split).map(([p, n]) => `${p}:${n}`).join(',')}`
      : '';
    const chain = a.fallback_chain?.[s]?.join('→') ?? '-';
    lines.push(`${s}: ${a.active_provider?.[s] ?? '-'}${splitText} · fallback ${chain}`);
  }
  if (c.message) lines.push('', `📣 notice: ${c.message}`);
  lines.push(`min version: ${c.min_supported_version ?? '0.0.0'}`);
  return lines.join('\n');
}

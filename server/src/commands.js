// Telegram bot commands as pure functions: (text, config, session) → result.
// No I/O here, so every command is unit-tested.
import {
  ConfigError,
  ID_FIELDS,
  cleanId,
  isValidId,
  PROVIDERS,
  SPLIT_STORES,
  STORES,
  clone,
  mask,
  maskedConfig,
  storeAllows,
  summary,
  validateConfig,
} from './config.js';

export const HELP = `🎭 Pantomime ads bot

/status – summary
/show – full JSON (ids masked)
/provider <play|bazaar|myket|ios> <adivery|tapsell|admob>
/split <play|bazaar|myket> adivery:50,tapsell:50
/split <store> off
/fallback <store> adivery,tapsell
/ads on|off
/every N  (1–10, interstitial every N turns)
/rewarded on|off
/banner on|off
/notice <text>   ·   /notice off
/minversion 1.2.0
/keys – set ad ids step by step
/rollback – back to the previous version
/cancel – stop /keys`;

/**
 * Result of a command.
 * @typedef {{
 *   reply: string,
 *   config?: object,      // new config to publish (version bumped by caller)
 *   rollback?: boolean,   // caller restores the previous version
 *   session?: object|null,// /keys conversation state (null clears it)
 *   deleteMessage?: boolean, // the user's message contained a secret
 * }} CommandResult
 */

const err = (reply) => ({ reply: `⚠️ ${reply}` });

function onOff(arg) {
  if (arg === 'on') return true;
  if (arg === 'off') return false;
  return null;
}

/** Applies `mutate` to a copy, validates it with the app's rules. */
function change(config, mutate, okText) {
  const next = clone(config);
  mutate(next);
  try {
    validateConfig(next);
  } catch (e) {
    if (e instanceof ConfigError) return err(`rejected: ${e.message}`);
    throw e;
  }
  return { config: next, reply: okText };
}

const ID_HINT =
  '⚠️ An id is one word of letters, digits and - _ . : ~ / (no spaces, no quotes needed). Try again or /cancel.';

const KEY_TARGETS = Object.keys(ID_FIELDS); // adivery, tapsell, admob_android, admob_ios

function setId(cfg, target, field, value) {
  cfg.ads.providers ??= {};
  if (target.startsWith('admob_')) {
    const plat = target.slice('admob_'.length);
    cfg.ads.providers.admob ??= {};
    cfg.ads.providers.admob[plat] ??= {};
    cfg.ads.providers.admob[plat][field] = value;
  } else {
    cfg.ads.providers[target] ??= {};
    cfg.ads.providers[target][field] = value;
  }
}

/** Continues a /keys conversation with a plain (non-command) message. */
function continueKeys(text, config, session) {
  const value = text.trim();
  if (session.step === 'target') {
    if (!KEY_TARGETS.includes(value)) {
      return { reply: `Choose one of: ${KEY_TARGETS.join(', ')}`, session };
    }
    return {
      reply: `Field for ${value}? ${ID_FIELDS[value].join(', ')}`,
      session: { step: 'field', target: value },
    };
  }
  if (session.step === 'field') {
    if (!ID_FIELDS[session.target].includes(value)) {
      return { reply: `Choose one of: ${ID_FIELDS[session.target].join(', ')}`, session };
    }
    return {
      reply: `Send the value for ${session.target}.${value} ("-" to clear). I'll delete your message after saving.`,
      session: { ...session, step: 'value', field: value },
    };
  }
  if (session.step === 'value') {
    const v = value === '-' ? '' : cleanId(value);
    if (v !== '' && !isValidId(v)) {
      return { reply: ID_HINT, session };
    }
    const r = change(
      config,
      (c) => setId(c, session.target, session.field, v),
      `✅ ${session.target}.${session.field} = ${mask(v)}`,
    );
    return { ...r, session: null, deleteMessage: true };
  }
  return { reply: 'Unknown state. /keys to start again.', session: null };
}

/**
 * Runs one admin message.
 * @param {string} text
 * @param {object} config current config
 * @param {object|null} session /keys conversation state
 * @returns {CommandResult}
 */
export function runCommand(text, config, session = null) {
  const trimmed = (text ?? '').trim();
  if (!trimmed.startsWith('/')) {
    if (session) return continueKeys(trimmed, config, session);
    return { reply: HELP };
  }
  // "/cmd@BotName arg1 arg2"
  const [head, ...rest] = trimmed.split(/\s+/);
  const cmd = head.split('@')[0].toLowerCase();
  const args = rest;
  const restText = trimmed.slice(head.length).trim();

  switch (cmd) {
    case '/start':
    case '/help':
      return { reply: HELP, session: null };

    case '/cancel':
      return { reply: 'Cancelled.', session: null };

    case '/status':
      return { reply: summary(config) };

    case '/show':
      return { reply: JSON.stringify(maskedConfig(config), null, 2) };

    case '/provider': {
      const [s, p] = args;
      if (!STORES.includes(s) || !PROVIDERS.includes(p)) {
        return err(`usage: /provider <${STORES.join('|')}> <${PROVIDERS.join('|')}>`);
      }
      if (!storeAllows(s, p)) return err(`${p} is not allowed on ${s} (no Google Play Services).`);
      return change(config, (c) => (c.ads.active_provider[s] = p), `✅ ${s} → ${p}`);
    }

    case '/split': {
      const [s, spec] = args;
      if (!SPLIT_STORES.includes(s) || !spec) {
        return err(`usage: /split <${SPLIT_STORES.join('|')}> adivery:50,tapsell:50  or  /split <store> off`);
      }
      if (spec === 'off') {
        return change(
          config,
          (c) => {
            if (c.ads.ab_split) delete c.ads.ab_split[s];
          },
          `✅ A/B test off for ${s}`,
        );
      }
      const parts = {};
      for (const item of spec.split(',')) {
        const m = /^([a-z]+):(\d{1,3})$/.exec(item.trim());
        if (!m) return err(`bad split item "${item}" (want provider:percent)`);
        parts[m[1]] = Number(m[2]);
      }
      return change(
        config,
        (c) => {
          c.ads.ab_split ??= {};
          c.ads.ab_split[s] = parts;
        },
        `✅ A/B on ${s}: ${spec}`,
      );
    }

    case '/fallback': {
      const [s, list] = args;
      if (!STORES.includes(s) || !list) {
        return err(`usage: /fallback <${STORES.join('|')}> adivery,tapsell`);
      }
      const chain = list.split(',').map((x) => x.trim()).filter(Boolean);
      if (new Set(chain).size !== chain.length) return err('duplicate provider in chain');
      return change(
        config,
        (c) => {
          c.ads.fallback_chain ??= {};
          c.ads.fallback_chain[s] = chain;
        },
        `✅ ${s} fallback: ${chain.join(' → ')}`,
      );
    }

    case '/ads':
    case '/rewarded':
    case '/banner': {
      const v = onOff(args[0]);
      if (v === null) return err(`usage: ${cmd} on|off`);
      const key = { '/ads': 'enabled', '/rewarded': 'rewarded_enabled', '/banner': 'banner_on_home' }[cmd];
      return change(config, (c) => (c.ads[key] = v), `✅ ${cmd.slice(1)} ${args[0]}`);
    }

    case '/every': {
      const n = Number(args[0]);
      if (!/^\d+$/.test(args[0] ?? '') || n < 1 || n > 10) return err('usage: /every N  (1–10)');
      return change(
        config,
        (c) => (c.ads.interstitial_every_n_rounds = n),
        `✅ interstitial every ${n} turns`,
      );
    }

    case '/notice': {
      if (!restText) return err('usage: /notice <text>  or  /notice off');
      if (restText === 'off') {
        return change(config, (c) => (c.message = null), '✅ notice removed');
      }
      if (restText.length > 500) return err('notice is limited to 500 characters');
      return change(config, (c) => (c.message = restText), '✅ notice set');
    }

    case '/minversion': {
      const v = args[0];
      if (!/^\d+\.\d+\.\d+$/.test(v ?? '')) return err('usage: /minversion 1.2.0');
      return change(config, (c) => (c.min_supported_version = v), `✅ min version ${v}`);
    }

    case '/keys': {
      // One-shot form: /keys adivery app_id VALUE
      if (args.length === 3) {
        const [target, field, value] = args;
        if (!KEY_TARGETS.includes(target) || !ID_FIELDS[target].includes(field)) {
          return err(`unknown target/field. Targets: ${KEY_TARGETS.join(', ')}`);
        }
        const v = value === '-' ? '' : cleanId(value);
        if (v !== '' && !isValidId(v)) return { reply: ID_HINT, deleteMessage: true };
        const r = change(config, (c) => setId(c, target, field, v), `✅ ${target}.${field} = ${mask(v)}`);
        return { ...r, deleteMessage: true, session: null };
      }
      return {
        reply: `Which provider? ${KEY_TARGETS.join(', ')}\n(/cancel to stop)`,
        session: { step: 'target' },
      };
    }

    case '/rollback':
      return { rollback: true, reply: '' };

    default:
      return { reply: `Unknown command.\n\n${HELP}` };
  }
}

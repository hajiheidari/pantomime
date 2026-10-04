// Config storage in Workers KV.
//   config:current   live config (what GET /config.json serves)
//   config:history   previous versions, newest first (max 10) → /rollback
//   log              change log, newest first (max 200)
//   session:<chat>   /keys conversation state (expires after 10 minutes)
import defaultConfig from './default_config.json' with { type: 'json' };
import { clone, validateConfig } from './config.js';
import { bundledPack, validatePack } from './words.js';

const HISTORY_MAX = 10;
const LOG_MAX = 200;

export class ConfigStore {
  /** @param {KVNamespace} kv */
  constructor(kv, now = () => new Date()) {
    this.kv = kv;
    this.now = now;
  }

  async current() {
    const c = await this.kv.get('config:current', 'json');
    return c ?? clone(defaultConfig);
  }

  async history() {
    return (await this.kv.get('config:history', 'json')) ?? [];
  }

  async log() {
    return (await this.kv.get('log', 'json')) ?? [];
  }

  async _appendLog(entry) {
    const log = await this.log();
    log.unshift({ ts: this.now().toISOString(), ...entry });
    await this.kv.put('log', JSON.stringify(log.slice(0, LOG_MAX)));
  }

  /**
   * Publishes `next` as a new version: bumps config_version, keeps the
   * previous version in history and logs the change.
   */
  async publish(next, { actor, command }) {
    const prev = await this.current();
    const config = clone(next);
    config.config_version = (prev.config_version ?? 0) + 1;
    validateConfig(config);
    const history = await this.history();
    history.unshift(prev);
    await this.kv.put('config:history', JSON.stringify(history.slice(0, HISTORY_MAX)));
    await this.kv.put('config:current', JSON.stringify(config));
    await this._appendLog({ actor, command, version: config.config_version });
    return config;
  }

  /**
   * Restores the most recent previous version. Its content is republished
   * under a *higher* version number because apps never accept a lower one.
   * Returns null when there is nothing to roll back to.
   */
  async rollback({ actor }) {
    const [previous, ...older] = await this.history();
    if (!previous) return null;
    const current = await this.current();
    const config = clone(previous);
    config.config_version = (current.config_version ?? 0) + 1;
    validateConfig(config);
    await this.kv.put('config:history', JSON.stringify(older));
    await this.kv.put('config:current', JSON.stringify(config));
    await this._appendLog({
      actor,
      command: `/rollback (content of v${previous.config_version})`,
      version: config.config_version,
    });
    return config;
  }

  async session(chatId) {
    return this.kv.get(`session:${chatId}`, 'json');
  }

  async setSession(chatId, session) {
    if (session == null) {
      await this.kv.delete(`session:${chatId}`);
    } else {
      await this.kv.put(`session:${chatId}`, JSON.stringify(session), { expirationTtl: 600 });
    }
  }
}

// Word list storage in the same KV namespace.
//   words:fa        live word pack (what GET /words_fa.json serves);
//                   missing → the pack bundled with the app
//   words:fa:prev   the pack before the last change (/wordsundo)
export class WordStore {
  /** @param {KVNamespace} kv */
  constructor(kv, now = () => new Date()) {
    this.kv = kv;
    this.now = now;
    this.log = new ConfigStore(kv, now);
  }

  async current() {
    return (await this.kv.get('words:fa', 'json')) ?? bundledPack();
  }

  /** Publishes [next] with a higher version than both the live and the
   * bundled pack, so every app picks it up. */
  async publish(next, { actor, command }) {
    const prev = await this.current();
    const pack = JSON.parse(JSON.stringify(next));
    pack.version = Math.max(prev.version ?? 0, bundledPack().version, pack.version ?? 0) + 1;
    pack.language = 'fa';
    validatePack(pack);
    await this.kv.put('words:fa:prev', JSON.stringify(prev));
    await this.kv.put('words:fa', JSON.stringify(pack));
    await this.log._appendLog({ actor, command, words_version: pack.version });
    return pack;
  }

  /** Republishes the previous pack (under a new version). */
  async undo({ actor }) {
    const prev = await this.kv.get('words:fa:prev', 'json');
    if (!prev) return null;
    return this.publish(prev, { actor, command: '/wordsundo' });
  }
}

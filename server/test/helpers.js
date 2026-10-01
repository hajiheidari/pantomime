// In-memory stand-ins for Workers KV and fetch.
export class FakeKV {
  constructor() {
    this.map = new Map();
    this.puts = [];
  }
  async get(key, type) {
    const v = this.map.get(key);
    if (v == null) return null;
    return type === 'json' ? JSON.parse(v) : v;
  }
  async put(key, value, opts) {
    this.puts.push({ key, opts });
    this.map.set(key, value);
  }
  async delete(key) {
    this.map.delete(key);
  }
}

export function fakeFetch() {
  const calls = [];
  const fn = async (url, init = {}) => {
    calls.push({ url: String(url), init, body: init.body ? safeJson(init.body) : null });
    return new Response('{"ok":true}', { status: 200 });
  };
  fn.calls = calls;
  return fn;
}

function safeJson(s) {
  try {
    return JSON.parse(s);
  } catch {
    return s;
  }
}

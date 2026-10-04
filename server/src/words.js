// Word list editing for the bot: pure functions over a word pack
// ({version, language, categories: [{id, title, emoji, words: {easy, medium, hard}}]}).
// The app accepts a downloaded pack only if it passes the same checks as
// validatePack (lib/features/words/data/remote_words.dart).
import bundled from '../../assets/words/words_fa.json' with { type: 'json' };

export const bundledPack = () => JSON.parse(JSON.stringify(bundled));

export const LEVELS = ['easy', 'medium', 'hard'];
const LEVEL_ALIASES = {
  easy: 'easy', آسان: 'easy', اسان: 'easy', ساده: 'easy',
  medium: 'medium', متوسط: 'medium',
  hard: 'hard', سخت: 'hard',
};

export const WORD_HELP = `📚 Word list

/words – categories and counts
/addword <category> [easy|medium|hard] word1، word2
   (category: its id, emoji or title; default level: medium;
    several words: separate with «،» or one per line)
/delword word1، word2 – remove from every category
/findword word – where is it?
/wordsfile – download the whole list as a file
   (send an edited .json file back to replace the list)
/wordsundo – back to the previous list

Phones get the new list within a few hours (next game, never mid-game).`;

export class WordsError extends Error {}

/** Same normalization as normalizePersian() in the app. */
export function normalizeWord(input) {
  return String(input)
    .replace(/[يى]/g, 'ی')
    .replace(/ك/g, 'ک')
    .replace(/ـ/g, '')
    .replace(/[ً-ٰٟ]/g, '')
    .replace(/‌/g, '')
    .replace(/\s+/g, '')
    .trim()
    .toLowerCase();
}

/** Splits "a، b, c\nd" into clean words. */
export function splitWords(text) {
  return String(text ?? '')
    .split(/[\n،,؛;]+/)
    .map((w) => w.replace(/\s+/g, ' ').trim())
    .filter(Boolean);
}

export const countWords = (pack) =>
  pack.categories.reduce(
    (n, c) => n + LEVELS.reduce((m, l) => m + (c.words?.[l]?.length ?? 0), 0),
    0,
  );

/** Throws WordsError unless the app would accept [pack]. */
export function validatePack(pack, language = 'fa') {
  const fail = (m) => {
    throw new WordsError(m);
  };
  if (!pack || typeof pack !== 'object') fail('not a JSON object');
  if (!Number.isInteger(pack.version) || pack.version < 1) fail('version must be a whole number ≥ 1');
  if (pack.language !== language) fail(`language must be "${language}"`);
  if (!Array.isArray(pack.categories)) fail('categories must be a list');
  const ids = new Set();
  for (const c of pack.categories) {
    if (!c || typeof c.id !== 'string' || !c.id || typeof c.title !== 'string') {
      fail('every category needs "id" and "title"');
    }
    if (ids.has(c.id)) fail(`duplicate category id ${c.id}`);
    ids.add(c.id);
    if (!c.words || typeof c.words !== 'object') fail(`${c.id}: "words" missing`);
    for (const l of LEVELS) {
      const list = c.words[l];
      if (list == null) continue;
      if (!Array.isArray(list) || list.some((w) => typeof w !== 'string')) {
        fail(`${c.id}.${l} must be a list of words`);
      }
    }
  }
  if (pack.categories.length < 3) fail('at least 3 categories');
  if (countWords(pack) < 100) fail('at least 100 words');
  if (JSON.stringify(pack).length > 2 * 1024 * 1024) fail('file too big (max 2 MB)');
}

function findCategory(pack, key) {
  const k = normalizeWord(key);
  return pack.categories.find(
    (c) => c.id.toLowerCase() === key.toLowerCase() || c.emoji === key || normalizeWord(c.title) === k,
  );
}

function where(pack, word) {
  const key = normalizeWord(word);
  const hits = [];
  for (const c of pack.categories) {
    for (const l of LEVELS) {
      if ((c.words[l] ?? []).some((w) => normalizeWord(w) === key)) hits.push(`${c.id} (${l})`);
    }
  }
  return hits;
}

export function packSummary(pack) {
  const lines = pack.categories.map((c) => {
    const n = LEVELS.map((l) => c.words[l]?.length ?? 0);
    const total = n.reduce((a, b) => a + b, 0);
    return `${c.emoji ?? '🎲'} ${c.title} — ${c.id}${c.bonus ? ' 🎁' : ''}\n    ${total} (easy ${n[0]} · medium ${n[1]} · hard ${n[2]})`;
  });
  return `📚 words v${pack.version}: ${countWords(pack)} words, ${pack.categories.length} categories\n\n${lines.join('\n')}`;
}

/**
 * Runs a word command. Returns null when [cmd] is not a word command.
 * @returns {{reply: string, pack?: object, undo?: boolean, sendFile?: boolean} | null}
 */
export function runWordsCommand(cmd, restText, pack) {
  switch (cmd) {
    case '/words':
      return { reply: `${packSummary(pack)}\n\n${WORD_HELP}` };

    case '/wordsfile':
      return { reply: '', sendFile: true };

    case '/wordsundo':
      return { reply: '', undo: true };

    case '/findword': {
      const word = restText.trim();
      if (!word) return { reply: '⚠️ usage: /findword word' };
      const hits = where(pack, word);
      return { reply: hits.length ? `🔎 ${word}: ${hits.join(', ')}` : `🔎 ${word}: not in the list` };
    }

    case '/addword': {
      const [catKey, ...more] = restText.split(/\s+/);
      const category = catKey ? findCategory(pack, catKey) : null;
      if (!category) {
        return { reply: `⚠️ usage: /addword <category> [easy|medium|hard] word1، word2\nCategories: ${pack.categories.map((c) => c.id).join(', ')}` };
      }
      let rest = restText.slice(catKey.length).trim();
      let level = 'medium';
      const first = more[0];
      if (first && LEVEL_ALIASES[first.toLowerCase()]) {
        level = LEVEL_ALIASES[first.toLowerCase()];
        rest = rest.slice(first.length).trim();
      }
      const words = splitWords(rest);
      if (!words.length) return { reply: '⚠️ no words given' };
      const next = JSON.parse(JSON.stringify(pack));
      const cat = next.categories.find((c) => c.id === category.id);
      cat.words[level] ??= [];
      const added = [];
      const skipped = [];
      for (const w of words) {
        if (w.length > 60) {
          skipped.push(`${w.slice(0, 20)}… (too long)`);
          continue;
        }
        const hits = where(next, w).filter((h) => h.startsWith(`${cat.id} `));
        if (hits.length) {
          skipped.push(`${w} (already in ${hits[0]})`);
          continue;
        }
        cat.words[level].push(w);
        added.push(w);
      }
      const lines = [`➕ ${cat.title} (${level}): ${added.length} added`];
      if (added.length) lines.push(added.join('، '));
      if (skipped.length) lines.push(`skipped: ${skipped.join('، ')}`);
      return added.length ? { reply: lines.join('\n'), pack: next } : { reply: lines.join('\n') };
    }

    case '/delword': {
      const words = splitWords(restText);
      if (!words.length) return { reply: '⚠️ usage: /delword word1، word2' };
      const next = JSON.parse(JSON.stringify(pack));
      const removed = [];
      const missing = [];
      for (const w of words) {
        const key = normalizeWord(w);
        let hit = false;
        for (const c of next.categories) {
          for (const l of LEVELS) {
            const list = c.words[l];
            if (!list) continue;
            const kept = list.filter((x) => normalizeWord(x) !== key);
            if (kept.length !== list.length) {
              c.words[l] = kept;
              hit = true;
            }
          }
        }
        (hit ? removed : missing).push(w);
      }
      const lines = [`➖ ${removed.length} removed${removed.length ? `: ${removed.join('، ')}` : ''}`];
      if (missing.length) lines.push(`not found: ${missing.join('، ')}`);
      return removed.length ? { reply: lines.join('\n'), pack: next } : { reply: lines.join('\n') };
    }

    default:
      return null;
  }
}

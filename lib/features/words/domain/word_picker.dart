import 'dart:math';

import 'word_models.dart';

/// Picks words without repetition.
///
/// - A word shown once is never shown again in the same game.
/// - Across games, words already seen (see [seen]) are deprioritized. A
///   category's seen-set is reset only when every eligible word of that
///   category has been seen.
///
/// Pure Dart: persistence is done by the caller via [seen] / [onSeenChanged].
class WordPicker {
  WordPicker({
    required List<WordEntry> pool,
    Map<String, Set<String>>? seen,
    Random? random,
    this.onSeenChanged,
  }) : _pool = List.unmodifiable(pool),
       seen = seen ?? {},
       _random = random ?? Random();

  final List<WordEntry> _pool;
  final Random _random;

  /// categoryId → normalized word keys seen in previous games (and this one).
  final Map<String, Set<String>> seen;

  /// Called whenever [seen] changes, so it can be persisted.
  final void Function(Map<String, Set<String>> seen)? onSeenChanged;

  final Set<WordEntry> _usedThisGame = {};

  int get poolSize => _pool.length;
  Set<WordEntry> get usedThisGame => Set.unmodifiable(_usedThisGame);

  bool _isSeen(WordEntry w) => seen[w.categoryId]?.contains(w.key) ?? false;

  /// Returns the next word, or `null` if the pool is empty.
  WordEntry? next() {
    if (_pool.isEmpty) return null;

    var available = _pool.where((w) => !_usedThisGame.contains(w)).toList();
    if (available.isEmpty) {
      // Everything was played in this very game: start over rather than stop.
      _usedThisGame.clear();
      available = List.of(_pool);
    }

    var fresh = available.where((w) => !_isSeen(w)).toList();
    if (fresh.isEmpty) {
      _resetExhaustedCategories(available);
      fresh = available.where((w) => !_isSeen(w)).toList();
      if (fresh.isEmpty) fresh = available;
    }

    // Pick a category first so small categories are not drowned out by big
    // ones, then a word inside it.
    final byCategory = <String, List<WordEntry>>{};
    for (final w in fresh) {
      (byCategory[w.categoryId] ??= []).add(w);
    }
    final categoryIds = byCategory.keys.toList();
    final words = byCategory[categoryIds[_random.nextInt(categoryIds.length)]]!;
    final word = words[_random.nextInt(words.length)];

    _usedThisGame.add(word);
    (seen[word.categoryId] ??= {}).add(word.key);
    onSeenChanged?.call(seen);
    return word;
  }

  /// Clears the seen-set of every category whose eligible words are all seen.
  void _resetExhaustedCategories(List<WordEntry> available) {
    final categoryIds = available.map((w) => w.categoryId).toSet();
    for (final id in categoryIds) {
      final eligible = _pool.where((w) => w.categoryId == id);
      if (eligible.every(_isSeen)) {
        // Keep words already used in this game marked, so they stay behind.
        seen[id] = {
          for (final w in _usedThisGame)
            if (w.categoryId == id) w.key,
        };
      }
    }
  }
}

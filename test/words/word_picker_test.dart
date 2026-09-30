import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:pantomime/features/words/domain/word_models.dart';
import 'package:pantomime/features/words/domain/word_picker.dart';

List<WordEntry> _words(String cat, int n) => [
  for (var i = 0; i < n; i++)
    WordEntry(text: '$cat$i', categoryId: cat, difficulty: Difficulty.easy),
];

void main() {
  test('never repeats a word within a game until the pool is exhausted', () {
    final pool = [..._words('a', 5), ..._words('b', 7)];
    final picker = WordPicker(pool: pool, random: Random(1));
    final shown = [for (var i = 0; i < pool.length; i++) picker.next()!];
    expect(shown.toSet().length, pool.length);
    // Exhausted: keeps going instead of returning null.
    expect(picker.next(), isNotNull);
  });

  test('prefers words not seen in previous games', () {
    final pool = _words('a', 6);
    final seen = {
      'a': {for (final w in pool.take(4)) w.key},
    };
    final picker = WordPicker(pool: pool, seen: seen, random: Random(3));
    final first = {picker.next()!.text, picker.next()!.text};
    expect(first, {'a4', 'a5'});
  });

  test('resets a category seen-set only when it is exhausted', () {
    final a = _words('a', 3);
    final b = _words('b', 3);
    final seen = {
      'a': {for (final w in a) w.key}, // exhausted
      'b': {b[0].key}, // not exhausted
    };
    Map<String, Set<String>>? saved;
    final picker = WordPicker(
      pool: [...a, ...b],
      seen: seen,
      random: Random(5),
      onSeenChanged: (s) => saved = s,
    );
    // Fresh words exist in b, so they come first; a is not reset yet.
    final firstTwo = {picker.next()!.text, picker.next()!.text};
    expect(firstTwo, {'b1', 'b2'});
    expect(saved!['a']!.length, 3);

    // Now everything is seen → both exhausted categories reset, but words
    // used in this game are not shown again.
    final next = picker.next()!;
    expect(firstTwo.contains(next.text), isFalse);
    expect(saved!['a']!.length + saved!['b']!.length, lessThan(6));
  });

  test('empty pool returns null', () {
    expect(WordPicker(pool: const []).next(), isNull);
  });

  test('persists seen words through the callback', () {
    final pool = _words('a', 3);
    Map<String, Set<String>>? saved;
    final picker = WordPicker(pool: pool, onSeenChanged: (s) => saved = s);
    final w = picker.next()!;
    expect(saved!['a'], contains(w.key));
  });
}

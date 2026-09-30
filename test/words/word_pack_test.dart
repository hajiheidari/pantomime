import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pantomime/features/words/data/word_repository.dart';
import 'package:pantomime/features/words/domain/word_models.dart';

void main() {
  test('Persian pack: 11 regular categories + bonus, every level filled, no duplicates', () {
    final raw = File('assets/words/words_fa.json').readAsStringSync();
    final cats = parseWordPack(raw);
    expect(cats.where((c) => !c.bonus).length, 11);
    expect(cats.where((c) => c.bonus), isNotEmpty);
    for (final c in cats) {
      for (final d in Difficulty.values) {
        expect(c.words[d], isNotEmpty, reason: '${c.id}/${d.name}');
      }
    }
    expect(cats.map((c) => c.id).toSet().length, cats.length);
  });

  test('English pack parses', () {
    final raw = File('assets/words/words_en.json').readAsStringSync();
    expect(parseWordPack(raw), isNotEmpty);
  });

  test('parser drops normalized duplicates and bad entries', () {
    const raw = '''
    {"categories": [
      {"id": "x", "title": "X", "words": {
        "easy": ["می‌رود", "میرود", "كيك", "کیک", "", 5],
        "legendary": ["ignored"]
      }},
      {"id": "empty", "title": "E", "words": {}},
      {"title": "no id"}
    ]}''';
    final cats = parseWordPack(raw);
    expect(cats.length, 1);
    expect(cats.single.words[Difficulty.easy]!.map((w) => w.text), [
      'می‌رود',
      'كيك',
    ]);
    expect(cats.single.emoji, isNotEmpty);
  });
}

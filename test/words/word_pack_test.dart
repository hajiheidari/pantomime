import 'dart:convert';

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pantomime/features/words/data/word_repository.dart';
import 'package:pantomime/features/words/domain/word_models.dart';

void main() {
  test('Persian pack: 10 regular categories + 3 bonus, every level filled, no duplicates', () {
    final raw = File('assets/words/words_fa.json').readAsStringSync();
    final cats = parseWordPack(raw);
    expect(cats.where((c) => !c.bonus).length, 10);
    expect(cats.where((c) => c.bonus).length, 3);
    expect(cats.where((c) => c.bonus), isNotEmpty);
    for (final c in cats) {
      for (final d in Difficulty.values) {
        expect(c.words[d], isNotEmpty, reason: '${c.id}/${d.name}');
      }
    }
    expect(cats.map((c) => c.id).toSet().length, cats.length);
  });

  for (final (lang, minWords) in [
    ('en', 800),
    ('ar', 700),
    ('ru', 800),
    ('tr', 800),
  ]) {
    test('$lang pack: 10 regular categories + 3 bonus, no duplicates', () {
      final raw = File('assets/words/words_$lang.json').readAsStringSync();
      final cats = parseWordPack(raw);
      expect(cats.where((c) => !c.bonus), hasLength(10));
      expect(cats.where((c) => c.bonus), hasLength(3));
      expect(cats.where((c) => c.bonus), isNotEmpty);
      final all = [
        for (final c in cats) ...c.wordsFor(Difficulty.values.toSet()),
      ];
      expect(all.length, greaterThanOrEqualTo(minWords));
      for (final c in cats) {
        for (final d in Difficulty.values) {
          expect(c.words[d], isNotEmpty, reason: '${c.id}.${d.name}');
        }
      }
      final keys = all.map((w) => w.key.replaceAll(RegExp("[-']"), ''));
      expect(keys.toSet().length, all.length, reason: 'same word twice');
    });
  }

  test('English pack (legacy check)', () {
    final raw = File('assets/words/words_en.json').readAsStringSync();
    final cats = parseWordPack(raw);
    expect(cats.where((c) => !c.bonus), hasLength(10));
    expect(cats.where((c) => c.bonus), hasLength(3));
    expect(cats.where((c) => c.bonus), isNotEmpty);
    final all = [
      for (final c in cats) ...c.wordsFor(Difficulty.values.toSet()),
    ];
    expect(all.length, greaterThanOrEqualTo(800));
    for (final c in cats) {
      for (final d in Difficulty.values) {
        expect(c.words[d], isNotEmpty, reason: '${c.id}.${d.name}');
      }
    }
    final keys = all.map((w) => w.key.replaceAll(RegExp("[-']"), ''));
    expect(keys.toSet().length, all.length, reason: 'same word twice');
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

  test('special categories stay special even if a pack drops the flag', () {
    final pack = jsonEncode({
      'version': 9,
      'language': 'fa',
      'categories': [
        for (final id in ['party', 'funny_embarrassing', 'sports'])
          {
            'id': id,
            'title': id,
            'emoji': '🎲',
            'words': {
              'easy': ['a'],
            },
          },
      ],
    });
    final cats = parseWordPack(pack);
    expect(
      {for (final c in cats) c.id: c.bonus},
      {'party': true, 'funny_embarrassing': true, 'sports': false},
    );
  });
}

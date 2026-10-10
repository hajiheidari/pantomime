import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/word_models.dart';

/// Special categories, unlocked by sharing the game (or a rewarded ad).
/// Fixed here too, so a word pack downloaded later cannot drop the flag.
const bonusCategoryIds = {
  'cartoons',
  'party',
  'funny_embarrassing', // Persian
  'funny_situations', // English, Arabic
};

/// Source of word categories. Game logic depends only on this interface, so
/// the bundled JSON can later be replaced/augmented by downloadable packs.
abstract interface class WordRepository {
  Future<List<WordCategory>> loadCategories(String languageCode);
}

/// Loads `assets/words/words_<lang>.json`, falling back to Persian.
class AssetWordRepository implements WordRepository {
  AssetWordRepository({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;
  final Map<String, List<WordCategory>> _cache = {};

  @override
  Future<List<WordCategory>> loadCategories(String languageCode) async {
    final cached = _cache[languageCode];
    if (cached != null) return cached;
    String raw;
    try {
      raw = await _bundle.loadString('assets/words/words_$languageCode.json');
    } catch (_) {
      raw = await _bundle.loadString('assets/words/words_fa.json');
    }
    return _cache[languageCode] = parseWordPack(raw);
  }
}

/// Parses a word pack JSON document. Unknown difficulty keys are ignored,
/// duplicates (after Persian normalization) inside a category are dropped.
List<WordCategory> parseWordPack(String raw) {
  final json = jsonDecode(raw) as Map<String, dynamic>;
  final categories = <WordCategory>[];
  for (final c in (json['categories'] as List? ?? const [])) {
    if (c is! Map<String, dynamic>) continue;
    final id = c['id'];
    final title = c['title'];
    if (id is! String || title is! String) continue;
    final words = <Difficulty, List<WordEntry>>{};
    final seenKeys = <String>{};
    final rawWords = c['words'];
    if (rawWords is Map<String, dynamic>) {
      for (final d in Difficulty.values) {
        final list = rawWords[d.name];
        if (list is! List) continue;
        for (final w in list) {
          if (w is! String || w.trim().isEmpty) continue;
          final entry = WordEntry(
            text: w.trim(),
            categoryId: id,
            difficulty: d,
          );
          if (seenKeys.add(entry.key)) {
            (words[d] ??= []).add(entry);
          }
        }
      }
    }
    if (words.isEmpty) continue;
    categories.add(
      WordCategory(
        id: id,
        title: title,
        emoji: c['emoji'] as String? ?? '🎲',
        words: words,
        bonus: c['bonus'] == true || bonusCategoryIds.contains(id),
      ),
    );
  }
  return categories;
}

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:pantomime/features/words/data/word_repository.dart';
import 'package:pantomime/features/words/domain/word_models.dart';

/// Reads the real word packs from disk synchronously, avoiding asset-bundle
/// futures that don't cross fake-async test zones well.
class FileWordRepository implements WordRepository {
  @override
  Future<List<WordCategory>> loadCategories(String languageCode) =>
      SynchronousFuture(
        parseWordPack(
          File('assets/words/words_$languageCode.json').readAsStringSync(),
        ),
      );
}

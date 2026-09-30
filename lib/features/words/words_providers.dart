import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import 'data/seen_words_store.dart';
import 'data/word_repository.dart';
import 'domain/word_models.dart';

final wordRepositoryProvider = Provider<WordRepository>(
  (ref) => AssetWordRepository(),
);

final seenWordsStoreProvider = Provider<SeenWordsStore>(
  (ref) => SeenWordsStore(ref.watch(sharedPreferencesProvider)),
);

/// Categories of the current language's word pack.
final wordCategoriesProvider = FutureProvider<List<WordCategory>>((ref) {
  final lang = ref.watch(languageCodeProvider);
  return ref.watch(wordRepositoryProvider).loadCategories(lang);
});

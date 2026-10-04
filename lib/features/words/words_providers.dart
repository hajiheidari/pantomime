import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import 'data/seen_words_store.dart';
import 'data/remote_words.dart';
import 'data/word_repository.dart';
import 'domain/word_models.dart';

final wordRepositoryProvider = Provider<WordRepository>(
  (ref) => UpdatableWordRepository(prefs: ref.watch(sharedPreferencesProvider)),
);

/// Downloads a newer word pack in the background (at most every 6 hours).
/// The new words show up in games started afterwards, never mid-game.
Future<void> refreshWordPack(ProviderContainer container) async {
  try {
    final repo = container.read(wordRepositoryProvider);
    if (repo is! UpdatableWordRepository) return;
    final lang = container.read(languageCodeProvider);
    if (await repo.refresh(lang)) container.invalidate(wordCategoriesProvider);
  } catch (e) {
    debugPrint('word pack refresh: $e');
  }
}

final seenWordsStoreProvider = Provider<SeenWordsStore>(
  (ref) => SeenWordsStore(ref.watch(sharedPreferencesProvider)),
);

/// Categories of the current language's word pack.
final wordCategoriesProvider = FutureProvider<List<WordCategory>>((ref) {
  final lang = ref.watch(languageCodeProvider);
  return ref.watch(wordRepositoryProvider).loadCategories(lang);
});

/// Bonus categories unlocked in this app session (rewarded ad).
final unlockedBonusProvider = NotifierProvider<UnlockedBonus, Set<String>>(
  UnlockedBonus.new,
);

class UnlockedBonus extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  void unlock(String categoryId) => state = {...state, categoryId};
}

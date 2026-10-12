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

/// Clock, overridden in tests.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// The special (bonus) categories are open until this time, or null. One
/// rewarded ad, sharing the game, or a friend opening the invite link opens
/// all of them for 24 hours. Kept across app restarts.
final bonusUnlockProvider = NotifierProvider<BonusUnlock, DateTime?>(
  BonusUnlock.new,
);

class BonusUnlock extends Notifier<DateTime?> {
  static const duration = Duration(hours: 24);
  static const _key = 'bonus.open_until';

  @override
  DateTime? build() {
    final ms = ref.watch(sharedPreferencesProvider).getInt(_key);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  /// Time left, or null when closed.
  Duration? get remaining {
    final until = state;
    if (until == null) return null;
    final left = until.difference(ref.read(clockProvider)());
    return left.isNegative ? null : left;
  }

  bool get isOpen => remaining != null;

  void openForADay() {
    final until = ref.read(clockProvider)().add(duration);
    ref
        .read(sharedPreferencesProvider)
        .setInt(_key, until.millisecondsSinceEpoch);
    state = until;
  }
}

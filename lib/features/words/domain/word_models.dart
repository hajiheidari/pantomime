import '../../../core/utils/persian_text.dart';

enum Difficulty { easy, medium, hard }

/// Difficulty filter chosen in game setup.
enum DifficultyChoice {
  easy,
  medium,
  hard,
  mixed;

  Set<Difficulty> get levels => switch (this) {
    DifficultyChoice.easy => {Difficulty.easy},
    DifficultyChoice.medium => {Difficulty.medium},
    DifficultyChoice.hard => {Difficulty.hard},
    DifficultyChoice.mixed => Difficulty.values.toSet(),
  };
}

class WordEntry {
  const WordEntry({
    required this.text,
    required this.categoryId,
    required this.difficulty,
  });

  final String text;
  final String categoryId;
  final Difficulty difficulty;

  /// Stable key used for no-repeat tracking.
  String get key => normalizePersian(text);

  @override
  bool operator ==(Object other) =>
      other is WordEntry && other.key == key && other.categoryId == categoryId;

  @override
  int get hashCode => Object.hash(key, categoryId);

  @override
  String toString() => text;
}

class WordCategory {
  const WordCategory({
    required this.id,
    required this.title,
    required this.emoji,
    required this.words,
    this.bonus = false,
  });

  final String id;

  /// Bonus categories open for 24 hours after a fully watched rewarded ad,
  /// a share, or a new visit to the player's invite link.
  final bool bonus;
  final String title;
  final String emoji;
  final Map<Difficulty, List<WordEntry>> words;

  List<WordEntry> wordsFor(Set<Difficulty> levels) => [
    for (final d in levels) ...?words[d],
  ];

  int get totalWords => words.values.fold(0, (sum, list) => sum + list.length);
}

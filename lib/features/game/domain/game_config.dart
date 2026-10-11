import '../../words/domain/word_models.dart';

/// classic: one word per turn (the traditional game); teams: speed mode,
/// as many words as possible in one turn; forehead: phone on the forehead.
enum GameMode { classic, teams, forehead }

class GameConfig {
  const GameConfig({
    required this.teamNames,
    this.mode = GameMode.teams,
    this.roundSeconds = 60,
    this.roundsPerTeam = 3,
    this.difficulty = DifficultyChoice.mixed,
    this.categoryIds = const {},
    this.passLimit = 3,
    this.wordChanges = 0,
  });

  static List<int> roundSecondsOptions(GameMode mode) =>
      mode == GameMode.classic ? const [30, 60, 120] : const [30, 60, 90];

  /// Classic mode: how many times each team may swap its word, in the whole
  /// game (0 = off).
  static const wordChangeOptions = [0, 1, 2, 3];

  /// `null` means unlimited.
  static const passLimitOptions = <int?>[0, 1, 2, 3, 4, 5, null];

  /// Teams (team mode) or players (forehead mode).
  static int minTeams(GameMode mode) => mode == GameMode.forehead ? 1 : 2;
  static int maxTeams(GameMode mode) => mode == GameMode.forehead ? 8 : 4;

  static List<int> roundsOptions(GameMode mode) => switch (mode) {
    GameMode.classic => const [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
    GameMode.teams => const [3, 5, 7],
    GameMode.forehead => const [1, 2, 3],
  };
  static int defaultRounds(GameMode mode) =>
      mode == GameMode.classic ? 5 : roundsOptions(mode).first;

  /// Default config for [mode]. Forehead mode has unlimited passes (tilting
  /// up must always work); classic mode swaps words instead of passing.
  factory GameConfig.defaults(GameMode mode) => GameConfig(
    mode: mode,
    teamNames: const ['', ''],
    roundsPerTeam: defaultRounds(mode),
    passLimit: mode == GameMode.teams ? 3 : null,
    wordChanges: mode == GameMode.classic ? 1 : 0,
  );

  final List<String> teamNames;
  final GameMode mode;
  final int roundSeconds;
  final int roundsPerTeam;
  final DifficultyChoice difficulty;

  /// Selected categories. Empty means "all categories".
  final Set<String> categoryIds;

  /// Passes allowed per round; `null` = unlimited.
  final int? passLimit;

  /// Classic mode: word swaps per team for the whole game (0 = off).
  final int wordChanges;

  int get teamCount => teamNames.length;

  GameConfig copyWith({
    List<String>? teamNames,
    GameMode? mode,
    int? roundSeconds,
    int? roundsPerTeam,
    DifficultyChoice? difficulty,
    Set<String>? categoryIds,
    int? Function()? passLimit,
    int? wordChanges,
  }) => GameConfig(
    teamNames: teamNames ?? this.teamNames,
    mode: mode ?? this.mode,
    roundSeconds: roundSeconds ?? this.roundSeconds,
    roundsPerTeam: roundsPerTeam ?? this.roundsPerTeam,
    difficulty: difficulty ?? this.difficulty,
    categoryIds: categoryIds ?? this.categoryIds,
    passLimit: passLimit != null ? passLimit() : this.passLimit,
    wordChanges: wordChanges ?? this.wordChanges,
  );

  Map<String, dynamic> toJson() => {
    'teamNames': teamNames,
    'roundSeconds': roundSeconds,
    'roundsPerTeam': roundsPerTeam,
    'difficulty': difficulty.name,
    'categoryIds': categoryIds.toList(),
    'passLimit': passLimit,
    'wordChanges': wordChanges,
  };

  /// Lenient parsing of a previously saved setup; invalid values fall back to
  /// the defaults of [mode].
  static GameConfig fromJson(
    Map<String, dynamic> json, {
    required GameMode mode,
  }) {
    final d = GameConfig.defaults(mode);
    final names = (json['teamNames'] as List?)?.whereType<String>().toList();
    final seconds = json['roundSeconds'];
    final rounds = json['roundsPerTeam'];
    final pass = json['passLimit'];
    final changes = json['wordChanges'];
    return GameConfig(
      mode: mode,
      teamNames:
          names != null &&
              names.length >= minTeams(mode) &&
              names.length <= maxTeams(mode)
          ? names
          : d.teamNames,
      roundSeconds: roundSecondsOptions(mode).contains(seconds)
          ? seconds as int
          : d.roundSeconds,
      roundsPerTeam: roundsOptions(mode).contains(rounds)
          ? rounds as int
          : d.roundsPerTeam,
      difficulty: DifficultyChoice.values.firstWhere(
        (d) => d.name == json['difficulty'],
        orElse: () => DifficultyChoice.mixed,
      ),
      categoryIds: {...?(json['categoryIds'] as List?)?.whereType<String>()},
      passLimit: mode != GameMode.teams
          ? null
          : passLimitOptions.contains(pass)
          ? pass as int?
          : d.passLimit,
      wordChanges: mode != GameMode.classic
          ? 0
          : wordChangeOptions.contains(changes)
          ? changes as int
          : d.wordChanges,
    );
  }
}

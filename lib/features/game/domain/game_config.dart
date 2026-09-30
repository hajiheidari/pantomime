import '../../words/domain/word_models.dart';

enum GameMode { teams, forehead }

class GameConfig {
  const GameConfig({
    required this.teamNames,
    this.mode = GameMode.teams,
    this.roundSeconds = 60,
    this.roundsPerTeam = 3,
    this.difficulty = DifficultyChoice.mixed,
    this.categoryIds = const {},
    this.passLimit = 3,
  });

  static const roundSecondsOptions = [30, 60, 90];

  /// `null` means unlimited.
  static const passLimitOptions = <int?>[0, 1, 2, 3, 4, 5, null];

  /// Teams (team mode) or players (forehead mode).
  static int minTeams(GameMode mode) => mode == GameMode.teams ? 2 : 1;
  static int maxTeams(GameMode mode) => mode == GameMode.teams ? 4 : 8;

  static List<int> roundsOptions(GameMode mode) =>
      mode == GameMode.teams ? const [3, 5, 7] : const [1, 2, 3];
  static int defaultRounds(GameMode mode) => roundsOptions(mode).first;

  /// Default config for [mode]. Forehead mode has unlimited passes (tilting
  /// up must always work).
  factory GameConfig.defaults(GameMode mode) => GameConfig(
    mode: mode,
    teamNames: const ['', ''],
    roundsPerTeam: defaultRounds(mode),
    passLimit: mode == GameMode.teams ? 3 : null,
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

  int get teamCount => teamNames.length;

  GameConfig copyWith({
    List<String>? teamNames,
    GameMode? mode,
    int? roundSeconds,
    int? roundsPerTeam,
    DifficultyChoice? difficulty,
    Set<String>? categoryIds,
    int? Function()? passLimit,
  }) => GameConfig(
    teamNames: teamNames ?? this.teamNames,
    mode: mode ?? this.mode,
    roundSeconds: roundSeconds ?? this.roundSeconds,
    roundsPerTeam: roundsPerTeam ?? this.roundsPerTeam,
    difficulty: difficulty ?? this.difficulty,
    categoryIds: categoryIds ?? this.categoryIds,
    passLimit: passLimit != null ? passLimit() : this.passLimit,
  );

  Map<String, dynamic> toJson() => {
    'teamNames': teamNames,
    'roundSeconds': roundSeconds,
    'roundsPerTeam': roundsPerTeam,
    'difficulty': difficulty.name,
    'categoryIds': categoryIds.toList(),
    'passLimit': passLimit,
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
    return GameConfig(
      mode: mode,
      teamNames:
          names != null &&
              names.length >= minTeams(mode) &&
              names.length <= maxTeams(mode)
          ? names
          : d.teamNames,
      roundSeconds: roundSecondsOptions.contains(seconds)
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
      passLimit: mode == GameMode.forehead
          ? null
          : passLimitOptions.contains(pass)
          ? pass as int?
          : d.passLimit,
    );
  }
}

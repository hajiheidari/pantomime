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
  static const roundsPerTeamOptions = [3, 5, 7];

  /// `null` means unlimited.
  static const passLimitOptions = <int?>[0, 1, 2, 3, 4, 5, null];
  static const minTeams = 2;
  static const maxTeams = 4;

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
  /// defaults.
  static GameConfig fromJson(
    Map<String, dynamic> json, {
    required List<String> defaultTeamNames,
  }) {
    final names = (json['teamNames'] as List?)?.whereType<String>().toList();
    final seconds = json['roundSeconds'];
    final rounds = json['roundsPerTeam'];
    final pass = json['passLimit'];
    return GameConfig(
      teamNames:
          names != null && names.length >= minTeams && names.length <= maxTeams
          ? names
          : defaultTeamNames,
      roundSeconds: roundSecondsOptions.contains(seconds) ? seconds as int : 60,
      roundsPerTeam: roundsPerTeamOptions.contains(rounds) ? rounds as int : 3,
      difficulty: DifficultyChoice.values.firstWhere(
        (d) => d.name == json['difficulty'],
        orElse: () => DifficultyChoice.mixed,
      ),
      categoryIds: {...?(json['categoryIds'] as List?)?.whereType<String>()},
      passLimit: passLimitOptions.contains(pass) ? pass as int? : 3,
    );
  }
}

import '../../words/domain/word_models.dart';
import 'game_config.dart';

enum WordOutcome { correct, passed, timeout }

class WordResult {
  const WordResult(this.word, this.outcome);

  final WordEntry word;
  final WordOutcome outcome;

  bool get isCorrect => outcome == WordOutcome.correct;

  /// Flips a result between correct and not-correct (summary "fix mistake").
  WordResult toggled() =>
      WordResult(word, isCorrect ? WordOutcome.passed : WordOutcome.correct);
}

class TurnRecord {
  const TurnRecord({
    required this.teamIndex,
    required this.round,
    required this.suddenDeath,
    required this.results,
  });

  final int teamIndex;
  final int round;
  final bool suddenDeath;
  final List<WordResult> results;

  int get score => results.where((r) => r.isCorrect).length;

  TurnRecord withResults(List<WordResult> results) => TurnRecord(
    teamIndex: teamIndex,
    round: round,
    suddenDeath: suddenDeath,
    results: results,
  );
}

/// Immutable state of a whole game: turn order, completed turns, scores and
/// the sudden-death rule. Contains no timers or I/O so it is fully testable.
class GameState {
  const GameState._({
    required this.config,
    required this.schedule,
    required this.turnIndex,
    required this.turns,
    required this.suddenDeathAdded,
    required this.finished,
  });

  factory GameState.start(GameConfig config) => GameState._(
    config: config,
    schedule: [
      for (var r = 0; r < config.roundsPerTeam; r++)
        for (var t = 0; t < config.teamCount; t++) t,
    ],
    turnIndex: 0,
    turns: const [],
    suddenDeathAdded: false,
    finished: false,
  );

  final GameConfig config;

  /// Team index for every turn, in order.
  final List<int> schedule;

  /// Index into [schedule] of the turn being played / about to be played.
  final int turnIndex;

  /// Completed turns (one per played schedule entry).
  final List<TurnRecord> turns;
  final bool suddenDeathAdded;
  final bool finished;

  int get teamCount => config.teamCount;
  int get regularTurnCount => config.roundsPerTeam * config.teamCount;

  int get currentTeamIndex => schedule[turnIndex];
  bool get isSuddenDeath => turnIndex >= regularTurnCount;

  /// 1-based round number of the current turn.
  int get currentRound => isSuddenDeath
      ? config.roundsPerTeam + 1
      : turnIndex ~/ config.teamCount + 1;

  /// True once the current turn's results were recorded.
  bool get currentTurnCompleted => turns.length > turnIndex;

  int scoreOf(int teamIndex) => turns
      .where((t) => t.teamIndex == teamIndex)
      .fold(0, (sum, t) => sum + t.score);

  List<int> get scores => [for (var i = 0; i < teamCount; i++) scoreOf(i)];

  /// Teams with the highest score (more than one = tie).
  List<int> get leaders {
    final s = scores;
    final best = s.reduce((a, b) => a > b ? a : b);
    return [
      for (var i = 0; i < s.length; i++)
        if (s[i] == best) i,
    ];
  }

  /// Team indices ordered by score (desc), ties keep team order.
  List<int> get ranking =>
      List.generate(teamCount, (i) => i)
        ..sort((a, b) => scoreOf(b).compareTo(scoreOf(a)));

  /// Records the results of the current turn.
  GameState completeTurn(List<WordResult> results) {
    assert(!currentTurnCompleted, 'turn already completed');
    return _copy(
      turns: [
        ...turns,
        TurnRecord(
          teamIndex: currentTeamIndex,
          round: currentRound,
          suddenDeath: isSuddenDeath,
          results: List.unmodifiable(results),
        ),
      ],
    );
  }

  /// Flips one word of an already completed turn between correct/not.
  GameState toggleResult(int turn, int wordIndex) {
    final record = turns[turn];
    final results = [...record.results];
    results[wordIndex] = results[wordIndex].toggled();
    return _copy(
      turns: [...turns]
        ..[turn] = record.withResults(List.unmodifiable(results)),
    );
  }

  /// Moves on to the next turn, adding one sudden-death round for tied
  /// leaders when the regular rounds end, or finishing the game.
  GameState advance() {
    assert(currentTurnCompleted, 'complete the turn before advancing');
    final next = turnIndex + 1;
    if (next < schedule.length) return _copy(turnIndex: next);

    final tied = leaders;
    if (tied.length > 1 && !suddenDeathAdded) {
      return _copy(
        schedule: [...schedule, ...tied],
        turnIndex: next,
        suddenDeathAdded: true,
      );
    }
    return _copy(finished: true);
  }

  GameState _copy({
    List<int>? schedule,
    int? turnIndex,
    List<TurnRecord>? turns,
    bool? suddenDeathAdded,
    bool? finished,
  }) => GameState._(
    config: config,
    schedule: schedule ?? this.schedule,
    turnIndex: turnIndex ?? this.turnIndex,
    turns: turns ?? this.turns,
    suddenDeathAdded: suddenDeathAdded ?? this.suddenDeathAdded,
    finished: finished ?? this.finished,
  );
}

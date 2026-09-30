import 'package:flutter_test/flutter_test.dart';
import 'package:pantomime/features/game/domain/game_config.dart';
import 'package:pantomime/features/game/domain/game_state.dart';
import 'package:pantomime/features/words/domain/word_models.dart';

WordResult _r(String w, WordOutcome o) => WordResult(
  WordEntry(text: w, categoryId: 'c', difficulty: Difficulty.easy),
  o,
);

/// Plays the current turn with [correct] correct words and one pass.
GameState _play(GameState g, int correct) => g.completeTurn([
  for (var i = 0; i < correct; i++) _r('w$i', WordOutcome.correct),
  _r('p', WordOutcome.passed),
]).advance();

void main() {
  const config = GameConfig(teamNames: ['A', 'B', 'C'], roundsPerTeam: 2);

  test('teams alternate in order for every round', () {
    var g = GameState.start(config);
    final order = <(int, int)>[];
    while (!g.finished) {
      order.add((g.currentTeamIndex, g.currentRound));
      g = _play(g, g.currentTeamIndex + 1); // distinct scores → no tie
    }
    expect(order, [(0, 1), (1, 1), (2, 1), (0, 2), (1, 2), (2, 2)]);
  });

  test('+1 per correct word, passes cost nothing', () {
    var g = GameState.start(config);
    g = _play(g, 3); // A
    g = _play(g, 1); // B
    g = _play(g, 0); // C
    expect(g.scores, [3, 1, 0]);
    g = _play(g, 2); // A
    expect(g.scoreOf(0), 5);
  });

  test('toggling a result fixes the score', () {
    var g = GameState.start(config).completeTurn([
      _r('a', WordOutcome.correct),
      _r('b', WordOutcome.passed),
      _r('c', WordOutcome.timeout),
    ]);
    expect(g.scoreOf(0), 1);
    g = g.toggleResult(0, 1);
    expect(g.scoreOf(0), 2);
    g = g.toggleResult(0, 0);
    expect(g.scoreOf(0), 1);
    g = g.toggleResult(0, 2); // timeout → correct
    expect(g.scoreOf(0), 2);
  });

  test('game ends after N rounds; highest score wins', () {
    var g = GameState.start(config);
    for (final score in [1, 4, 2, 1, 1, 1]) {
      g = _play(g, score);
    }
    expect(g.finished, isTrue);
    expect(g.leaders, [1]);
    expect(g.ranking, [1, 2, 0]);
  });

  test('tie → one sudden-death round for tied leaders only', () {
    var g = GameState.start(config);
    for (final score in [2, 2, 0, 1, 1, 5]) {
      g = _play(g, score); // A=3 B=3 C=5 → no tie
    }
    expect(g.finished, isTrue);

    g = GameState.start(config);
    for (final score in [2, 2, 0, 1, 1, 1]) {
      g = _play(g, score); // A=3 B=3 C=1 → tie A/B
    }
    expect(g.finished, isFalse);
    expect(g.isSuddenDeath, isTrue);
    expect(g.currentTeamIndex, 0);
    expect(g.currentRound, 3);
    g = _play(g, 1);
    expect(g.currentTeamIndex, 1);
    g = _play(g, 2);
    expect(g.finished, isTrue);
    expect(g.leaders, [1]);
  });

  test('still tied after sudden death → game ends as a draw', () {
    var g = GameState.start(
      const GameConfig(teamNames: ['A', 'B'], roundsPerTeam: 3),
    );
    for (var i = 0; i < 6; i++) {
      g = _play(g, 1);
    }
    expect(g.isSuddenDeath, isTrue);
    g = _play(g, 2);
    g = _play(g, 2);
    expect(g.finished, isTrue);
    expect(g.leaders, [0, 1]);
  });

  test('config round-trips through JSON and rejects invalid values', () {
    const c = GameConfig(
      teamNames: ['x', 'y', 'z'],
      roundSeconds: 90,
      roundsPerTeam: 7,
      difficulty: DifficultyChoice.hard,
      categoryIds: {'animals'},
      passLimit: null,
    );
    final back = GameConfig.fromJson(c.toJson(), mode: GameMode.teams);
    expect(back.teamNames, ['x', 'y', 'z']);
    expect(back.roundSeconds, 90);
    expect(back.roundsPerTeam, 7);
    expect(back.difficulty, DifficultyChoice.hard);
    expect(back.categoryIds, {'animals'});
    expect(back.passLimit, isNull);

    final bad = GameConfig.fromJson({
      'teamNames': ['only one'],
      'roundSeconds': 45,
      'roundsPerTeam': 'x',
      'difficulty': 'insane',
      'passLimit': 99,
    }, mode: GameMode.teams);
    expect(bad.teamNames, ['', '']);
    expect(bad.roundSeconds, 60);
    expect(bad.roundsPerTeam, 3);
    expect(bad.difficulty, DifficultyChoice.mixed);
    expect(bad.passLimit, 3);

    final forehead = GameConfig.fromJson({
      'teamNames': ['solo'],
      'roundsPerTeam': 2,
      'passLimit': 1,
    }, mode: GameMode.forehead);
    expect(forehead.teamNames, ['solo']);
    expect(forehead.roundsPerTeam, 2);
    expect(forehead.passLimit, isNull);
    expect(
      GameConfig.fromJson({
        'roundsPerTeam': 5,
      }, mode: GameMode.forehead).roundsPerTeam,
      1,
    );
  });
}

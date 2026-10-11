import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantomime/core/providers.dart';
import 'package:pantomime/features/game/application/feedback_service.dart';
import 'package:pantomime/features/game/application/game_controller.dart';
import 'package:pantomime/features/game/application/sound_service.dart';
import 'package:pantomime/features/game/domain/game_config.dart';
import 'package:pantomime/features/game/domain/game_state.dart';
import 'package:pantomime/features/words/domain/word_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> container() async {
    SharedPreferences.setMockInitialValues({});
    final c = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(
          await SharedPreferences.getInstance(),
        ),
        soundServiceProvider.overrideWithValue(const SilentSoundService()),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  final words = [
    WordCategory(
      id: 'c',
      title: 'C',
      emoji: '🎲',
      words: {
        for (final d in Difficulty.values)
          d: [
            for (var i = 0; i < 5; i++)
              WordEntry(text: '${d.name}$i', categoryId: 'c', difficulty: d),
          ],
      },
    ),
  ];

  test('going to background during the countdown returns to ready', () async {
    final c = await container();
    final ctrl = c.read(gameControllerProvider.notifier);
    ctrl.startGame(const GameConfig(teamNames: ['A', 'B']), words);
    ctrl.startTurn();
    expect(c.read(gameControllerProvider)!.phase, GamePhase.countdown);
    ctrl.setPaused(true);
    expect(c.read(gameControllerProvider)!.phase, GamePhase.ready);
    // Starting again works normally.
    ctrl.startTurn();
    expect(c.read(gameControllerProvider)!.phase, GamePhase.countdown);
    ctrl.quit();
  });

  test('pause/resume only affects a running turn', () async {
    final c = await container();
    final ctrl = c.read(gameControllerProvider.notifier);
    ctrl.startGame(const GameConfig(teamNames: ['A', 'B']), words);
    ctrl.setPaused(true); // ready: no effect
    expect(c.read(gameControllerProvider)!.phase, GamePhase.ready);
    expect(c.read(gameControllerProvider)!.paused, isFalse);
    ctrl.quit();
  });

  Future<void> toPlaying(WidgetTester tester, GameController ctrl) async {
    ctrl.startTurn();
    await tester.pump(const Duration(seconds: 4));
  }

  const classic = GameConfig(
    mode: GameMode.classic,
    teamNames: ['A', 'B'],
    roundsPerTeam: 2,
    passLimit: null,
    wordChanges: 1,
  );

  testWidgets('classic: "got it" scores one point and ends the turn', (
    tester,
  ) async {
    final c = await container();
    final ctrl = c.read(gameControllerProvider.notifier);
    ctrl.startGame(classic, words);
    await toPlaying(tester, ctrl);
    final word = c.read(gameControllerProvider)!.currentWord!;
    ctrl.markCorrect();
    final s = c.read(gameControllerProvider)!;
    expect(s.phase, GamePhase.summary);
    expect(s.lastTurn!.results.single.word, word);
    expect(s.game.scoreOf(0), 1);
    ctrl.quit();
  });

  testWidgets('classic: give up ends the turn with no point', (tester) async {
    final c = await container();
    final ctrl = c.read(gameControllerProvider.notifier);
    ctrl.startGame(classic, words);
    await toPlaying(tester, ctrl);
    ctrl.giveUp();
    final s = c.read(gameControllerProvider)!;
    expect(s.phase, GamePhase.summary);
    expect(s.lastTurn!.results.single.outcome, WordOutcome.passed);
    expect(s.game.scoreOf(0), 0);
    ctrl.quit();
  });

  testWidgets('classic: word changes are limited per team for the game', (
    tester,
  ) async {
    final c = await container();
    final ctrl = c.read(gameControllerProvider.notifier);
    ctrl.startGame(classic, words);
    await toPlaying(tester, ctrl);
    GameSession s() => c.read(gameControllerProvider)!;
    final first = s().currentWord;
    ctrl.changeWord();
    expect(s().currentWord, isNot(first));
    expect(s().changesLeft, 0);
    final second = s().currentWord;
    ctrl.changeWord(); // none left
    expect(s().currentWord, second);
    // Still none left in this team's next turn; the other team has its own.
    ctrl.giveUp();
    ctrl.confirmSummary();
    ctrl.nextTurn();
    expect(s().changesLeft, 1); // team B
    ctrl.quit();
  });

  testWidgets('classic: the other team can give the word', (tester) async {
    final c = await container();
    final ctrl = c.read(gameControllerProvider.notifier);
    ctrl.startGame(classic, words);
    ctrl.setCustomWord('  هندوانه ');
    await toPlaying(tester, ctrl);
    expect(c.read(gameControllerProvider)!.currentWord!.text, 'هندوانه');
    expect(c.read(gameControllerProvider)!.customWord, isNull);
    // With word changes on, they can give another word.
    ctrl.changeWord('پرتقال');
    expect(c.read(gameControllerProvider)!.currentWord!.text, 'پرتقال');
    expect(c.read(gameControllerProvider)!.changesLeft, 0);
    ctrl.quit();
  });

  testWidgets('speed mode has no give up', (tester) async {
    final c = await container();
    final ctrl = c.read(gameControllerProvider.notifier);
    ctrl.startGame(const GameConfig(teamNames: ['A', 'B']), words);
    await toPlaying(tester, ctrl);
    ctrl.giveUp();
    expect(c.read(gameControllerProvider)!.phase, GamePhase.playing);
    ctrl.quit();
  });
}

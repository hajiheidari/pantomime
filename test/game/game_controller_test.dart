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

  testWidgets('give up ends the turn without waiting for the clock', (
    tester,
  ) async {
    final c = await container();
    final ctrl = c.read(gameControllerProvider.notifier);
    ctrl.startGame(const GameConfig(teamNames: ['A', 'B']), words);
    ctrl.startTurn();
    await tester.pump(const Duration(seconds: 4));
    final s = c.read(gameControllerProvider)!;
    expect(s.phase, GamePhase.playing);
    final word = s.currentWord!;
    ctrl.giveUp();
    final after = c.read(gameControllerProvider)!;
    expect(after.phase, GamePhase.summary);
    final turn = after.lastTurn!;
    expect(turn.results.last.word, word);
    expect(turn.results.last.outcome, WordOutcome.passed);
    ctrl.quit();
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantomime/app.dart';
import 'package:pantomime/core/providers.dart';
import 'package:pantomime/features/game/application/feedback_service.dart';
import 'package:pantomime/features/game/application/game_controller.dart';
import 'package:pantomime/features/game/application/sound_service.dart';
import 'package:pantomime/features/recording/round_recorder.dart';
import 'package:pantomime/features/words/words_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_words.dart';

class _BackRecorder implements RoundRecorder {
  int started = 0;
  int stopped = 0;
  bool _on = false;
  @override
  bool get isRecording => _on;
  @override
  Future<bool> prepare() async => true;
  @override
  Future<void> start() async {
    started++;
    _on = true;
  }

  @override
  Future<String?> stop() async {
    stopped++;
    _on = false;
    return '/tmp/turn.mp4';
  }

  @override
  Future<void> dispose() async {}
}

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 150));
  }
}

void main() {
  testWidgets('speed mode: film one turn with the back camera', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final recorder = _BackRecorder();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        soundServiceProvider.overrideWithValue(const SilentSoundService()),
        wordRepositoryProvider.overrideWithValue(FileWordRepository()),
        backRecorderFactoryProvider.overrideWithValue(() => recorder),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const PantomimeApp(),
      ),
    );
    await tester.pump(const Duration(seconds: 2));
    await settle(tester);
    await tester.tap(find.text('پانتومیم سرعتی'));
    await settle(tester);
    await tester.tap(find.text('بزن بریم!'));
    await settle(tester);
    // Group photo is offered once, before the first turn.
    expect(find.text('📸 عکس دسته‌جمعی؟'), findsOneWidget);
    await tester.tap(find.text('فعلاً نه'));
    await settle(tester);

    // Ready: choose to film this turn.
    await tester.ensureVisible(find.text('🎥 فیلم گرفتن از این نوبت'));
    await tester.tap(find.text('🎥 فیلم گرفتن از این نوبت'));
    await settle(tester);
    expect(find.textContaining('ضبط روشن'), findsOneWidget);
    await tester.ensureVisible(find.text('شروع'));
    await tester.tap(find.text('شروع'));
    await tester.pump(const Duration(seconds: 4));
    await settle(tester);
    GameSession session() => container.read(gameControllerProvider)!;
    expect(session().phase, GamePhase.playing);
    expect(recorder.started, 1);

    // The turn ends → clip saved for this turn, offered on the summary.
    await tester.pump(const Duration(seconds: 61));
    await settle(tester);
    expect(session().phase, GamePhase.summary);
    expect(recorder.stopped, 1);
    expect(container.read(roundClipsProvider)[0], '/tmp/turn.mp4');

    // Next turn: not filmed unless chosen again.
    await tester.tap(find.text('ادامه'));
    await settle(tester);
    await tester.tap(find.text('نوبت بعد: تیم ۲'));
    await settle(tester);
    expect(find.text('🎥 فیلم گرفتن از این نوبت'), findsOneWidget);
    await tester.ensureVisible(find.text('شروع'));
    await tester.tap(find.text('شروع'));
    await tester.pump(const Duration(seconds: 4));
    await settle(tester);
    expect(recorder.started, 1);

    container.read(gameControllerProvider.notifier).quit();
    await tester.pump(const Duration(seconds: 1));
  });
}

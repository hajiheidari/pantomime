import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantomime/app.dart';
import 'package:pantomime/core/providers.dart';
import 'package:pantomime/features/game/application/feedback_service.dart';
import 'package:pantomime/features/game/application/game_controller.dart';
import 'package:pantomime/features/game/application/motion.dart';
import 'package:pantomime/features/game/application/sound_service.dart';
import 'package:pantomime/features/game/domain/game_state.dart';
import 'package:pantomime/features/recording/round_recorder.dart';
import 'package:pantomime/features/words/words_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_words.dart';

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 150));
  }
}

void main() {
  late StreamController<MotionSample> motion;
  late ProviderContainer container;
  var clock = Duration.zero;

  /// Sends [pitch]-like samples for [ms] milliseconds (every 20 ms).
  /// upright: gravity on x; down: screen to floor (z<0); up: z>0.
  Future<void> hold(WidgetTester tester, String pose, int ms) async {
    final (x, z) = switch (pose) {
      'upright' => (9.8, 0.0),
      'down' => (0.0, -9.8),
      'up' => (0.0, 9.8),
      _ => throw ArgumentError(pose),
    };
    for (var t = 0; t < ms; t += 20) {
      clock += const Duration(milliseconds: 20);
      motion.add(MotionSample(x, 0, z, clock));
      await tester.pump(const Duration(milliseconds: 20));
    }
  }

  Future<void> boot(
    WidgetTester tester, {
    Map<String, Object> prefsValues = const {},
    FakeRecorder? recorder,
  }) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues(prefsValues);
    final prefs = await SharedPreferences.getInstance();
    final recordingOn = prefs.getBool('settings.recording') ?? false;
    motion = StreamController<MotionSample>.broadcast();
    clock = Duration.zero;
    container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        soundServiceProvider.overrideWithValue(const SilentSoundService()),
        wordRepositoryProvider.overrideWithValue(FileWordRepository()),
        accelerometerProvider.overrideWithValue(motion.stream),
        if (recorder != null)
          roundRecorderFactoryProvider.overrideWithValue(() => recorder),
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
    await tester.tap(find.text('گوشی روی پیشونی'));
    await settle(tester);
    // First time with recording off: it is suggested (once).
    final offered = find.text('ضبط ویدیوی خنده‌دار 🎥');
    expect(offered, recordingOn ? findsNothing : findsOneWidget);
    if (!recordingOn) {
      await tester.tap(find.text('فعلاً نه'));
      await settle(tester);
    }
    expect(find.text('بازیکن‌ها'), findsOneWidget);
    await tester.tap(find.text('بزن بریم!'));
    await settle(tester);
    // The game screen locks to landscape.
    tester.view.physicalSize = const Size(2340, 1080);
    await settle(tester);
    expect(find.text('نوبت بازیکن ۱'), findsOneWidget);
    await tester.tap(find.text('شروع'));
    await settle(tester);
  }

  GameSession session() => container.read(gameControllerProvider)!;

  testWidgets('calibrate, tilt down = correct, tilt up = pass', (tester) async {
    await boot(tester);
    expect(session().phase, GamePhase.calibrating);
    expect(find.text('گوشی را روی پیشانی بگذار'), findsOneWidget);

    // Held still upright on the forehead → calibrated → countdown.
    await hold(tester, 'upright', 2400);
    expect(session().phase, GamePhase.countdown);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 100));
    expect(session().phase, GamePhase.playing);
    expect(session().config.passLimit, isNull);

    await hold(tester, 'upright', 300);
    await hold(tester, 'down', 300);
    expect(session().results.map((r) => r.outcome), [WordOutcome.correct]);
    expect(find.text('✅ درست!'), findsOneWidget); // full-screen flash

    // Staying down does not count twice; back to neutral re-arms.
    await hold(tester, 'down', 500);
    expect(session().results.length, 1);
    await hold(tester, 'upright', 800);
    await hold(tester, 'up', 300);
    expect(session().results.map((r) => r.outcome), [
      WordOutcome.correct,
      WordOutcome.passed,
    ]);

    // Time runs out → summary; 2 players → next is player 2.
    await tester.pump(const Duration(seconds: 61));
    await settle(tester);
    expect(session().phase, GamePhase.summary);
    expect(find.text('۱ امتیاز'), findsOneWidget);
    await tester.tap(find.text('ادامه'));
    await settle(tester);
    expect(find.text('نوبت بعد: بازیکن ۲'), findsOneWidget);

    container.read(gameControllerProvider.notifier).quit();
    await motion.close();
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('no motion sensor → button fallback', (tester) async {
    await boot(tester);
    await tester.pump(const Duration(milliseconds: 1600)); // silence
    await settle(tester);
    expect(find.text('شروع با دکمه‌ها'), findsOneWidget);
    await tester.tap(find.text('شروع با دکمه‌ها'));
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 1600));
    await settle(tester);
    expect(session().phase, GamePhase.playing);
    await tester.tap(find.text('درست'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(session().correctCount, 1);

    container.read(gameControllerProvider.notifier).quit();
    await motion.close();
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('recording on: round is filmed, clip offered on summary', (
    tester,
  ) async {
    final recorder = FakeRecorder();
    await boot(
      tester,
      prefsValues: {'settings.recording': true},
      recorder: recorder,
    );
    await hold(tester, 'upright', 2400);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 100));
    expect(session().phase, GamePhase.playing);
    await tester.pump(const Duration(milliseconds: 50));
    expect(recorder.started, 1);
    expect(find.text('ضبط'), findsOneWidget); // REC badge

    await tester.pump(const Duration(seconds: 61));
    await settle(tester);
    expect(session().phase, GamePhase.summary);
    expect(recorder.stopped, 1);
    expect(container.read(roundClipsProvider), {0: '/tmp/clip.mp4'});
    expect(find.text('ذخیره ویدیو'), findsOneWidget);
    expect(find.text('ارسال ویدیو'), findsOneWidget);
    expect(find.text('کارت امتیاز'), findsOneWidget);

    container.read(gameControllerProvider.notifier).quit();
    await motion.close();
    await tester.pump(const Duration(seconds: 1));
  });
}

class FakeRecorder implements RoundRecorder {
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
    return '/tmp/clip.mp4';
  }

  @override
  Future<void> dispose() async {}
}

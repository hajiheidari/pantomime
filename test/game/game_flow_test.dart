import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantomime/app.dart';
import 'package:pantomime/core/providers.dart';
import 'package:pantomime/features/game/application/game_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pumps a few frames (can't use pumpAndSettle: some emoji bounce forever).
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 150));
  }
}

void main() {
  testWidgets('plays a full team turn in Persian RTL', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const PantomimeApp(),
      ),
    );
    // Word pack loads from real assets outside the fake-async zone.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pump(const Duration(seconds: 2));
    await settle(tester);

    // Home
    expect(find.text('بازی تیمی'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.text('بازی تیمی'))),
      TextDirection.rtl,
    );
    await tester.tap(find.text('بازی تیمی'));
    await settle(tester);

    // Setup: defaults (2 teams, all categories) → start
    expect(find.text('آماده‌سازی بازی'), findsOneWidget);
    await tester.tap(find.text('بزن بریم!'));
    await settle(tester);

    // Ready
    expect(find.text('نوبت تیم ۱'), findsOneWidget);
    await tester.tap(find.text('شروع'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('۳'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 300));

    // Play
    GameSession session() => container.read(gameControllerProvider)!;
    expect(session().phase, GamePhase.playing);
    final firstWord = session().currentWord!.text;
    expect(find.text(firstWord), findsOneWidget);
    await tester.tap(find.text('درست'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('درست'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('پاس'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(session().correctCount, 2);
    expect(find.text('پاس باقی‌مانده: ۲'), findsOneWidget);

    // Time runs out → summary
    await tester.pump(const Duration(seconds: 61));
    await settle(tester);
    expect(session().phase, GamePhase.summary);
    expect(find.text('۲ امتیاز'), findsOneWidget);
    expect(find.text(firstWord), findsOneWidget);

    // Fix a mistake: the passed word becomes correct
    await tester.tap(find.text(session().lastTurn!.results[2].word.text));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('۳ امتیاز'), findsOneWidget);

    await tester.tap(find.text('ادامه'));
    await settle(tester);
    expect(find.text('جدول امتیاز'), findsOneWidget);
    await tester.tap(find.text('نوبت بعد: تیم ۲'));
    await settle(tester);
    expect(find.text('نوبت تیم ۲'), findsOneWidget);
    expect(session().game.scores, [3, 0]);

    // Leave the game cleanly (stops timers).
    container.read(gameControllerProvider.notifier).quit();
    await tester.pump(const Duration(seconds: 1));
  });
}

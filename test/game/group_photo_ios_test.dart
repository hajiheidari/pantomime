import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantomime/app.dart';
import 'package:pantomime/core/providers.dart';
import 'package:pantomime/features/game/application/feedback_service.dart';
import 'package:pantomime/features/game/application/sound_service.dart';
import 'package:pantomime/features/words/words_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_words.dart';
import 'game_flow_test.dart' show settle;

void main() {
  testWidgets('iOS: group photo is a button, never a pop-up (App Review)', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        soundServiceProvider.overrideWithValue(const SilentSoundService()),
        wordRepositoryProvider.overrideWithValue(FileWordRepository()),
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

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('فعلاً نه'), findsNothing);
    expect(find.text('📸 عکس دسته‌جمعی'), findsOneWidget);
    expect(find.text('نوبت تیم ۱'), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
  });
}

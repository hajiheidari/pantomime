import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/l10n/default_language.dart';
import 'core/providers.dart';
import 'features/ads/ads_providers.dart';
import 'features/words/words_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final prefs = await SharedPreferences.getInstance();

  final device = DeviceLocale(
    locales: [
      for (final l in WidgetsBinding.instance.platformDispatcher.locales)
        [l.languageCode, ?l.countryCode].join('_'),
    ],
    utcOffset: DateTime.now().timeZoneOffset,
  );

  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      deviceLocaleProvider.overrideWithValue(device),
    ],
  );
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const PantomimeApp(),
    ),
  );
  // Remote config + ad SDKs: background only, never blocks start.
  unawaited(startAds(container));
  // A newer word list, if one was published (background, offline-safe).
  unawaited(
    Future<void>.delayed(
      const Duration(seconds: 3),
      () => refreshWordPack(container),
    ),
  );
}

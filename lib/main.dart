import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final prefs = await SharedPreferences.getInstance();

  // Persian if any preferred device language is Persian, otherwise the first.
  final locales = WidgetsBinding.instance.platformDispatcher.locales;
  final deviceLanguage = locales.any((l) => l.languageCode == 'fa')
      ? 'fa'
      : (locales.isEmpty ? 'fa' : locales.first.languageCode);

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        deviceLanguageProvider.overrideWithValue(deviceLanguage),
      ],
      child: const PantomimeApp(),
    ),
  );
}

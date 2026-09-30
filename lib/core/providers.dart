import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/settings/settings_controller.dart';
import 'l10n/app_strings.dart';

/// Overridden in `main()` with the loaded instance.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider not overridden'),
);

/// Device language code, overridden in `main()` (e.g. from
/// `PlatformDispatcher.locales`).
final deviceLanguageProvider = Provider<String>((ref) => 'fa');

/// Effective UI/word-pack language: the user's choice, or the device language
/// when it is set to "system". Persian unless the device prefers English.
final languageCodeProvider = Provider<String>((ref) {
  final choice = ref.watch(settingsProvider.select((s) => s.language));
  if (choice != AppLanguage.system) return choice.name;
  return ref.watch(deviceLanguageProvider) == 'en' ? 'en' : 'fa';
});

final stringsProvider = Provider<AppStrings>(
  (ref) => AppStrings.forLanguage(ref.watch(languageCodeProvider)),
);

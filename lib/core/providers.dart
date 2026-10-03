import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/settings/settings_controller.dart';
import 'l10n/app_strings.dart';

/// Overridden in `main()` with the loaded instance.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider not overridden'),
);

/// UI/word-pack language: Persian unless the user picked English in settings.
final languageCodeProvider = Provider<String>(
  (ref) => ref.watch(settingsProvider.select((s) => s.language)).name,
);

final stringsProvider = Provider<AppStrings>(
  (ref) => AppStrings.forLanguage(ref.watch(languageCodeProvider)),
);

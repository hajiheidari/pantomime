import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/settings/settings_controller.dart';
import '../features/ads/ads_providers.dart';
import 'l10n/app_strings.dart';
import 'l10n/default_language.dart';

/// Overridden in `main()` with the loaded instance.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider not overridden'),
);

/// Device locales and time zone, overridden in `main()` (unknown → Persian).
final deviceLocaleProvider = Provider<DeviceLocale>(
  (ref) => const DeviceLocale(locales: ['fa']),
);

/// UI/word-pack language: the player's choice in settings, otherwise
/// [defaultLanguage] for this store and device.
final languageCodeProvider = Provider<String>((ref) {
  final choice = ref.watch(settingsProvider.select((s) => s.language));
  return (choice ??
          defaultLanguage(
            ref.watch(appStoreProvider),
            ref.watch(deviceLocaleProvider),
          ))
      .name;
});

final stringsProvider = Provider<AppStrings>(
  (ref) => AppStrings.forLanguage(ref.watch(languageCodeProvider)),
);

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show appFlavor;

/// Where this build is distributed. Selects ad networks (remote config keys)
/// and, later, store-specific links (rate / update).
enum AppStore {
  play,
  bazaar,
  myket,
  ios;

  /// Bazaar / Myket builds must not use Google Play Services or AdMob.
  bool get allowsGooglePlayServices => this == play || this == ios;

  static AppStore? tryParse(String? value) {
    for (final s in values) {
      if (s.name == value) return s;
    }
    return null;
  }

  /// Android: product flavor (`--flavor bazaar`) or `--dart-define=STORE=…`,
  /// defaulting to `play`. iOS: always `ios`.
  static AppStore detect() {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      return AppStore.ios;
    }
    return tryParse(appFlavor) ??
        tryParse(const String.fromEnvironment('STORE')) ??
        AppStore.play;
  }
}

import 'package:flutter/foundation.dart';

/// Ad ids baked into the build, kept out of source control.
///
/// Pass them with `--dart-define-from-file=ad_keys.json` (git-ignored; see
/// `ad_keys.example.json`). Ids from remote config win when non-empty.
abstract final class LocalAdKeys {
  static const _adiveryAppId = String.fromEnvironment('ADIVERY_APP_ID');
  static const _adiveryInterstitial = String.fromEnvironment(
    'ADIVERY_INTERSTITIAL',
  );
  static const _adiveryRewarded = String.fromEnvironment('ADIVERY_REWARDED');
  static const _adiveryBanner = String.fromEnvironment('ADIVERY_BANNER');

  static const _tapsellAppKey = String.fromEnvironment('TAPSELL_APP_KEY');
  static const _tapsellInterstitial = String.fromEnvironment(
    'TAPSELL_INTERSTITIAL',
  );
  static const _tapsellRewarded = String.fromEnvironment('TAPSELL_REWARDED');
  static const _tapsellBanner = String.fromEnvironment('TAPSELL_BANNER');

  static const _admobAndroidInterstitial = String.fromEnvironment(
    'ADMOB_ANDROID_INTERSTITIAL',
  );
  static const _admobAndroidRewarded = String.fromEnvironment(
    'ADMOB_ANDROID_REWARDED',
  );
  static const _admobAndroidBanner = String.fromEnvironment(
    'ADMOB_ANDROID_BANNER',
  );
  static const _admobIosInterstitial = String.fromEnvironment(
    'ADMOB_IOS_INTERSTITIAL',
  );
  static const _admobIosRewarded = String.fromEnvironment('ADMOB_IOS_REWARDED');
  static const _admobIosBanner = String.fromEnvironment('ADMOB_IOS_BANNER');

  /// Google's public test units — used in debug builds when nothing is set.
  static const _admobTest = {
    'android': {
      'interstitial': 'ca-app-pub-3940256099942544/1033173712',
      'rewarded': 'ca-app-pub-3940256099942544/5224354917',
      'banner': 'ca-app-pub-3940256099942544/6300978111',
    },
    'ios': {
      'interstitial': 'ca-app-pub-3940256099942544/4411468910',
      'rewarded': 'ca-app-pub-3940256099942544/1712485313',
      'banner': 'ca-app-pub-3940256099942544/2934735716',
    },
  };

  static Map<String, String> _clean(Map<String, String> m) => {
    for (final e in m.entries)
      if (e.value.isNotEmpty) e.key: e.value,
  };

  static Map<String, String> forProvider(String provider, {required bool ios}) {
    switch (provider) {
      case 'adivery':
        return _clean({
          'app_id': _adiveryAppId,
          'interstitial': _adiveryInterstitial,
          'rewarded': _adiveryRewarded,
          'banner': _adiveryBanner,
        });
      case 'tapsell':
        return _clean({
          'app_id': _tapsellAppKey,
          'interstitial': _tapsellInterstitial,
          'rewarded': _tapsellRewarded,
          'banner': _tapsellBanner,
        });
      case 'admob':
        final ids = _clean(
          ios
              ? {
                  'interstitial': _admobIosInterstitial,
                  'rewarded': _admobIosRewarded,
                  'banner': _admobIosBanner,
                }
              : {
                  'interstitial': _admobAndroidInterstitial,
                  'rewarded': _admobAndroidRewarded,
                  'banner': _admobAndroidBanner,
                },
        );
        if (ids.isEmpty && kDebugMode) {
          return _admobTest[ios ? 'ios' : 'android']!;
        }
        return ids;
    }
    return const {};
  }
}

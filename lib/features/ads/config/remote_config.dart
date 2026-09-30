import '../../../core/store/app_store.dart';

/// Ad networks this app knows about. Only these may appear in remote config.
const knownAdProviders = {'adivery', 'tapsell', 'admob'};

class ConfigFormatException implements Exception {
  ConfigFormatException(this.message);

  final String message;

  @override
  String toString() => 'ConfigFormatException: $message';
}

/// Remote-controlled ad settings. May change only ad provider, ad ids,
/// frequency, on/off and an optional notice — never gameplay.
class AdsConfig {
  const AdsConfig({
    required this.enabled,
    required this.activeProvider,
    required this.abSplit,
    required this.fallbackChain,
    required this.providerIds,
    required this.admobIds,
    required this.interstitialEveryNRounds,
    required this.bannerOnHome,
    required this.rewardedEnabled,
  });

  final bool enabled;

  /// store → provider.
  final Map<AppStore, String> activeProvider;

  /// store → provider → percent (sums to 100). Empty for "no A/B test".
  final Map<AppStore, Map<String, int>> abSplit;

  /// store → ordered providers to try when the current one keeps failing.
  final Map<AppStore, List<String>> fallbackChain;

  /// adivery / tapsell ids, normalized to `app_id`, `interstitial`,
  /// `rewarded`, `banner`.
  final Map<String, Map<String, String>> providerIds;

  /// AdMob unit ids per platform (`android` / `ios`).
  final Map<String, Map<String, String>> admobIds;

  final int interstitialEveryNRounds;
  final bool bannerOnHome;
  final bool rewardedEnabled;
}

class RemoteConfig {
  const RemoteConfig({
    required this.configVersion,
    required this.ads,
    this.minSupportedVersion = '0.0.0',
    this.message,
  });

  final int configVersion;
  final AdsConfig ads;
  final String minSupportedVersion;

  /// Optional notice shown on the home screen.
  final String? message;

  /// Parses and strictly validates [json]. Throws [ConfigFormatException]
  /// on anything unexpected so a bad config never replaces a good one.
  /// Unknown keys are ignored (they cannot affect the app).
  static RemoteConfig parse(Object? json) {
    final root = _map(json, 'root');
    final version = root['config_version'];
    if (version is! int || version < 0) _fail('config_version');
    final ads = _parseAds(_map(root['ads'], 'ads'));

    final minVersion = root['min_supported_version'] ?? '0.0.0';
    if (minVersion is! String ||
        !RegExp(r'^\d+\.\d+\.\d+$').hasMatch(minVersion)) {
      _fail('min_supported_version');
    }
    final message = root['message'];
    if (message != null && (message is! String || message.length > 500)) {
      _fail('message');
    }
    return RemoteConfig(
      configVersion: version,
      ads: ads,
      minSupportedVersion: minVersion,
      message: (message as String?)?.trim().isEmpty ?? true ? null : message,
    );
  }

  static RemoteConfig? tryParse(Object? json) {
    try {
      return parse(json);
    } on ConfigFormatException {
      return null;
    }
  }
}

Never _fail(String what) => throw ConfigFormatException('invalid $what');

Map<String, dynamic> _map(Object? v, String what) {
  if (v is Map<String, dynamic>) return v;
  if (v is Map) return v.map((k, v) => MapEntry('$k', v));
  _fail(what);
}

String _provider(Object? v, String what) {
  if (v is! String || !knownAdProviders.contains(v)) _fail('$what: $v');
  return v;
}

AppStore _store(String key, String what) =>
    AppStore.tryParse(key) ?? _fail('$what store: $key');

void _checkStoreAllows(AppStore store, String provider, String what) {
  if (provider == 'admob' && !store.allowsGooglePlayServices) {
    _fail('$what: admob is not allowed on ${store.name}');
  }
}

bool _bool(Object? v, String what) => v is bool ? v : _fail(what);

AdsConfig _parseAds(Map<String, dynamic> ads) {
  final active = <AppStore, String>{};
  for (final e in _map(ads['active_provider'], 'active_provider').entries) {
    final store = _store(e.key, 'active_provider');
    final p = _provider(e.value, 'active_provider');
    _checkStoreAllows(store, p, 'active_provider');
    active[store] = p;
  }

  final split = <AppStore, Map<String, int>>{};
  final rawSplit = ads['ab_split'];
  if (rawSplit != null) {
    for (final e in _map(rawSplit, 'ab_split').entries) {
      final store = _store(e.key, 'ab_split');
      if (e.value == null) continue; // "off" for this store
      final parts = <String, int>{};
      for (final p in _map(e.value, 'ab_split').entries) {
        final provider = _provider(p.key, 'ab_split');
        _checkStoreAllows(store, provider, 'ab_split');
        final pct = p.value;
        if (pct is! int || pct < 0 || pct > 100) _fail('ab_split percent');
        parts[provider] = pct;
      }
      if (parts.isEmpty) continue;
      if (parts.values.fold(0, (a, b) => a + b) != 100) {
        _fail('ab_split must sum to 100');
      }
      split[store] = parts;
    }
  }

  final chain = <AppStore, List<String>>{};
  final rawChain = ads['fallback_chain'];
  if (rawChain != null) {
    for (final e in _map(rawChain, 'fallback_chain').entries) {
      final store = _store(e.key, 'fallback_chain');
      final list = e.value;
      if (list is! List) _fail('fallback_chain');
      final providers = <String>[];
      for (final p in list) {
        final provider = _provider(p, 'fallback_chain');
        _checkStoreAllows(store, provider, 'fallback_chain');
        if (!providers.contains(provider)) providers.add(provider);
      }
      chain[store] = providers;
    }
  }

  final ids = <String, Map<String, String>>{};
  final admob = <String, Map<String, String>>{};
  final rawProviders = ads['providers'];
  if (rawProviders != null) {
    for (final e in _map(rawProviders, 'providers').entries) {
      final p = _provider(e.key, 'providers');
      final fields = _map(e.value, 'providers.$p');
      switch (p) {
        case 'adivery':
          ids[p] = _ids(fields, p, {
            'app_id': 'app_id',
            'interstitial_placement': 'interstitial',
            'rewarded_placement': 'rewarded',
            'banner_placement': 'banner',
          });
        case 'tapsell':
          ids[p] = _ids(fields, p, {
            'app_key': 'app_id',
            'interstitial_zone': 'interstitial',
            'rewarded_zone': 'rewarded',
            'banner_zone': 'banner',
          });
        case 'admob':
          for (final platform in const ['android', 'ios']) {
            final v = fields[platform];
            if (v == null) continue;
            admob[platform] = _ids(_map(v, 'admob.$platform'), 'admob', {
              'interstitial': 'interstitial',
              'rewarded': 'rewarded',
              'banner': 'banner',
            });
          }
      }
    }
  }

  final every = ads['interstitial_every_n_rounds'] ?? 3;
  if (every is! int || every < 1 || every > 10) {
    _fail('interstitial_every_n_rounds');
  }

  return AdsConfig(
    enabled: _bool(ads['enabled'], 'enabled'),
    activeProvider: active,
    abSplit: split,
    fallbackChain: chain,
    providerIds: ids,
    admobIds: admob,
    interstitialEveryNRounds: every,
    bannerOnHome: _bool(ads['banner_on_home'] ?? true, 'banner_on_home'),
    rewardedEnabled: _bool(ads['rewarded_enabled'] ?? true, 'rewarded_enabled'),
  );
}

Map<String, String> _ids(
  Map<String, dynamic> fields,
  String provider,
  Map<String, String> keyMap,
) {
  final out = <String, String>{};
  for (final k in keyMap.entries) {
    final v = fields[k.key];
    if (v == null) continue;
    if (v is! String || v.length > 200) _fail('$provider.${k.key}');
    if (v.trim().isNotEmpty) out[k.value] = v.trim();
  }
  return out;
}

/// Compares dotted versions ("1.2.10" > "1.2.9").
int compareVersions(String a, String b) {
  List<int> parts(String v) =>
      v.split('+').first.split('.').map((p) => int.tryParse(p) ?? 0).toList();
  final pa = parts(a), pb = parts(b);
  for (var i = 0; i < 3; i++) {
    final x = i < pa.length ? pa[i] : 0;
    final y = i < pb.length ? pb[i] : 0;
    if (x != y) return x.compareTo(y);
  }
  return 0;
}

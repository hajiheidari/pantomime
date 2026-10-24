import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/store/iran_links.dart';
import 'remote_config.dart';

/// Config endpoints. Override per build with
/// `--dart-define=CONFIG_URL=… --dart-define=CONFIG_MIRROR_URL=…`
/// (set up in M4: Cloudflare Worker + a second mirror reachable from Iran).
const configPrimaryUrl = String.fromEnvironment(
  'CONFIG_URL',
  defaultValue: 'https://api.espadna.com/config.json',
);

/// The same Worker under its original workers.dev address: a second way in
/// if espadna.com is ever filtered.
const configFallbackUrl = String.fromEnvironment(
  'CONFIG_FALLBACK_URL',
  defaultValue:
      'https://pantomime-config.sepanta-hesaban.workers.dev/config.json',
);

/// Copy on the Iranian host espadna.ir (espadna-site/mirror-ir/sync.php):
/// fast from Iran, and still reachable on Iran's national internet.
const configIranUrl = String.fromEnvironment(
  'CONFIG_IRAN_URL',
  defaultValue: iranLinks ? 'https://espadna.ir/api/config.json' : '',
);

/// Older mirror on another Iranian host (server/mirror/pantomime-config.php).
const configMirrorUrl = String.fromEnvironment(
  'CONFIG_MIRROR_URL',
  defaultValue: iranLinks ? 'https://gabia.ir/pantomime-config.php' : '',
);

/// Loads the ad config: cached (last good) → bundled default, then refreshes
/// from the network in the background. Never blocks app start and never
/// throws.
class RemoteConfigService {
  RemoteConfigService({
    required this._prefs,
    required this._loadBundled,
    http.Client? client,
    List<String>? urls,
    this.timeout = const Duration(seconds: 3),
    this.minRefreshInterval = const Duration(hours: 1),
    DateTime Function()? now,
  }) : _client = client ?? http.Client(),
       _urls =
           (urls ??
                   const [
                     configPrimaryUrl,
                     configIranUrl,
                     configFallbackUrl,
                     configMirrorUrl,
                   ])
               .where((u) => u.isNotEmpty)
               .toList(),
       _now = now ?? DateTime.now;

  static const _kCache = 'remote_config.cache';
  static const _kFetchedAt = 'remote_config.fetched_at';

  final SharedPreferences _prefs;
  final Future<String> Function() _loadBundled;
  final http.Client _client;
  final List<String> _urls;
  final Duration timeout;
  final Duration minRefreshInterval;
  final DateTime Function() _now;

  RemoteConfig? _current;
  final _changes = StreamController<RemoteConfig>.broadcast();

  /// The config in effect. Available after [loadLocal].
  RemoteConfig get current => _current ?? _safeDefault;

  /// Emits whenever a newer config is applied.
  Stream<RemoteConfig> get changes => _changes.stream;

  /// Used only if even the bundled file is broken: ads off.
  static const _safeDefault = RemoteConfig(
    configVersion: -1,
    ads: AdsConfig(
      enabled: false,
      activeProvider: {},
      abSplit: {},
      fallbackChain: {},
      providerIds: {},
      admobIds: {},
      interstitialEveryNRounds: 3,
      bannerOnHome: false,
      rewardedEnabled: false,
    ),
  );

  /// Cached last-good config, else the bundled default.
  Future<RemoteConfig> loadLocal() async {
    final cached = _decode(_prefs.getString(_kCache));
    if (cached != null) return _current = cached;
    try {
      _current = _decode(await _loadBundled());
    } catch (e) {
      debugPrint('bundled config: $e');
    }
    return current;
  }

  /// Fetches primary, then the fallback, then the mirror (each with
  /// [timeout]). Applies the result
  /// only if it is valid and not older than the current config.
  /// Returns true when a new config was applied.
  Future<bool> refresh({bool force = false}) async {
    if (_urls.isEmpty) return false;
    final last = _prefs.getInt(_kFetchedAt);
    if (!force &&
        last != null &&
        _now().difference(DateTime.fromMillisecondsSinceEpoch(last)) <
            minRefreshInterval) {
      return false;
    }
    for (final url in _urls) {
      try {
        final res = await _client.get(Uri.parse(url)).timeout(timeout);
        if (res.statusCode != 200) continue;
        final body = utf8.decode(res.bodyBytes);
        final config = _decode(body);
        if (config == null) {
          // Invalid (e.g. unknown provider): keep the last good config.
          debugPrint('remote config from $url rejected');
          return false;
        }
        _prefs.setInt(_kFetchedAt, _now().millisecondsSinceEpoch);
        if (config.configVersion < current.configVersion) return false;
        _prefs.setString(_kCache, body);
        final changed = config.configVersion != current.configVersion;
        _current = config;
        if (changed) _changes.add(config);
        return changed;
      } catch (e) {
        debugPrint('remote config $url: $e');
      }
    }
    return false;
  }

  RemoteConfig? _decode(String? raw) {
    if (raw == null) return null;
    try {
      return RemoteConfig.tryParse(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }
}

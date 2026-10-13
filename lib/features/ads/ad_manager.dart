import 'dart:async';

import 'package:ads_core/ads_core.dart';
import 'package:flutter/widgets.dart';

import '../../core/store/app_store.dart';
import 'config/provider_selection.dart';
import 'config/remote_config.dart';

/// Outcome of asking for a rewarded ad to unlock the bonus pack.
enum RewardOutcome {
  /// Watched to the end.
  earned,

  /// Closed early — stays locked.
  skipped,

  /// No ad could be shown (disabled, no fill, error). Gameplay is never
  /// blocked by ads, so the caller unlocks anyway.
  unavailable,
}

/// Picks the ad network at runtime (remote config + A/B split + fallback),
/// enforces placement rules and hides every failure from gameplay.
///
/// Rules:
/// - never while a round is running ([isGameplayActive]);
/// - interstitial at most every N turn transitions;
/// - a provider that fails [maxConsecutiveFailures] times in a row is
///   skipped for the rest of the session (walks down the fallback chain);
/// - every wait is capped ([loadTimeout]).
class AdManager {
  AdManager({
    required this.store,
    required this.installId,
    required this._factories,
    required this._config,
    required this._localIds,
    required this._isGameplayActive,
    this.isIos = false,
    this.loadTimeout = const Duration(seconds: 3),
    this.maxConsecutiveFailures = 3,
  });

  final AppStore store;
  final String installId;
  final bool isIos;
  final Duration loadTimeout;
  final int maxConsecutiveFailures;

  final Map<String, AdProvider Function()> _factories;
  final RemoteConfig Function() _config;
  final Map<String, String> Function(String provider) _localIds;
  final bool Function() _isGameplayActive;

  final Map<String, AdProvider> _instances = {};
  final Map<String, int> _failures = {};
  final Set<String> _gaveUp = {};
  int _turnTransitions = 0;
  bool _showing = false;

  AdsConfig get _ads => _config().ads;

  /// Providers to try, best first (empty when ads are off).
  List<String> get chain => _ads.enabled
      ? providerChain(
          ads: _ads,
          store: store,
          installId: installId,
          compiled: _factories.keys.toSet(),
          failed: _gaveUp,
        )
      : const [];

  String? get currentProviderId {
    final c = chain;
    return c.isEmpty ? null : c.first;
  }

  /// Ids for [provider]: remote config values win, then build-time keys.
  Map<String, String> idsFor(String provider) {
    final remote = provider == 'admob'
        ? _ads.admobIds[isIos ? 'ios' : 'android']
        : _ads.providerIds[provider];
    return {..._localIds(provider), ...?remote};
  }

  Future<AdProvider?> _provider() async {
    final id = currentProviderId;
    if (id == null) return null;
    final p = _instances[id] ??= _factories[id]!();
    try {
      await p.init(idsFor(id)).timeout(loadTimeout);
    } catch (e) {
      debugPrint('ads: init $id: $e');
    }
    return p;
  }

  /// Initializes the chosen network and preloads full-screen ads.
  /// Call after the first frame; never awaited by app start.
  Future<void> warmUp() async {
    final p = await _provider();
    if (p == null) return;
    // Only the rewarded ad is placed in the app (special categories); the
    // interstitial and banner code paths stay for tests and a future change.
    if (_ads.rewardedEnabled) p.preload(AdFormat.rewarded);
  }

  void _record(String id, AdShowResult r) {
    if (r.shown) {
      _failures[id] = 0;
      return;
    }
    final n = (_failures[id] ?? 0) + 1;
    _failures[id] = n;
    if (n >= maxConsecutiveFailures) {
      debugPrint('ads: giving up on $id for this session');
      _gaveUp.add(id);
      unawaited(warmUp()); // next in the fallback chain
    }
  }

  /// Called when moving from the scoreboard to the next turn (the only
  /// interstitial slot). Shows an ad every N transitions.
  Future<void> onTurnTransition() async {
    _turnTransitions++;
    final ads = _ads;
    if (!ads.enabled || _showing || _isGameplayActive()) return;
    if (_turnTransitions % ads.interstitialEveryNRounds != 0) return;
    final p = await _provider();
    if (p == null) return;
    _showing = true;
    try {
      final r = await p.showInterstitial(timeout: loadTimeout);
      _record(p.id, r);
    } catch (e) {
      _record(p.id, AdShowResult.failed('$e'));
    } finally {
      _showing = false;
    }
  }

  /// Whether the bonus pack should be offered behind a rewarded ad.
  bool get rewardedOffered => _ads.enabled && _ads.rewardedEnabled;

  /// [timeout] overrides [loadTimeout]: the player asked for this ad and
  /// sees a loading indicator, so it may wait longer for a fill.
  Future<RewardOutcome> showRewarded({Duration? timeout}) async {
    if (!rewardedOffered || _showing || _isGameplayActive()) {
      return RewardOutcome.unavailable;
    }
    final p = await _provider();
    if (p == null) return RewardOutcome.unavailable;
    _showing = true;
    try {
      final r = await p.showRewarded(timeout: timeout ?? loadTimeout);
      _record(p.id, r);
      if (!r.shown) return RewardOutcome.unavailable;
      return r.rewarded ? RewardOutcome.earned : RewardOutcome.skipped;
    } catch (e) {
      _record(p.id, AdShowResult.failed('$e'));
      return RewardOutcome.unavailable;
    } finally {
      _showing = false;
    }
  }

  /// Small banner for the home screen, or null.
  Widget? homeBanner() {
    if (!_ads.enabled || !_ads.bannerOnHome) return null;
    final id = currentProviderId;
    final p = id == null ? null : _instances[id];
    return p?.buildBanner();
  }
}

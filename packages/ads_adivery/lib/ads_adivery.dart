import 'dart:async';
import 'dart:io' show Platform;

import 'package:adivery/adivery.dart';
import 'package:adivery/adivery_ads.dart' as adv;
import 'package:ads_core/ads_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Adivery (https://docs.adivery.com/flutter). Android only.
///
/// Ids: `app_id`, `interstitial`, `rewarded`, `banner` (placement ids).
class AdiveryProvider implements AdProvider {
  @override
  String get id => 'adivery';

  AdIds _ids = const {};
  bool _initialized = false;

  /// Resolves when the current full-screen ad closes.
  Completer<AdShowResult>? _showing;
  bool _lastRewarded = false;

  String? _placement(AdFormat f) {
    final v = _ids[f.name];
    return (v == null || v.isEmpty) ? null : v;
  }

  bool get _supported => !kIsWeb && Platform.isAndroid;

  @override
  Future<void> init(AdIds ids) async {
    _ids = ids;
    final appId = ids['app_id'] ?? '';
    if (!_supported || appId.isEmpty || _initialized) return;
    try {
      AdiveryPlugin.initialize(appId);
      AdiveryPlugin.addListener(
        onInterstitialClosed: (_) => _complete(true),
        onRewardedClosed: (_, rewarded) {
          _lastRewarded = rewarded;
          _complete(true);
        },
        onError: (placement, reason) {
          debugPrint('adivery error $placement: $reason');
          _complete(false, reason);
        },
      );
      _initialized = true;
    } catch (e) {
      debugPrint('adivery init: $e');
    }
  }

  void _complete(bool shown, [String? reason]) {
    final c = _showing;
    if (c == null || c.isCompleted) return;
    c.complete(
      shown
          ? AdShowResult(AdShowStatus.shown, rewarded: _lastRewarded)
          : AdShowResult.failed(reason ?? 'error'),
    );
  }

  // Adivery's isLoaded is async; keep the last known value.
  final Map<AdFormat, bool> _ready = {};

  @override
  bool isReady(AdFormat format) => _ready[format] ?? false;

  Future<bool> _checkLoaded(AdFormat f) async {
    final p = _placement(f);
    if (!_initialized || p == null) return false;
    try {
      final loaded = await AdiveryPlugin.isLoaded(p) ?? false;
      _ready[f] = loaded;
      return loaded;
    } catch (_) {
      return false;
    }
  }

  @override
  void preload(AdFormat format) {
    final p = _placement(format);
    if (!_initialized || p == null) return;
    try {
      switch (format) {
        case AdFormat.interstitial:
          AdiveryPlugin.prepareInterstitialAd(p);
        case AdFormat.rewarded:
          AdiveryPlugin.prepareRewardedAd(p);
        case AdFormat.banner:
          break;
      }
    } catch (e) {
      debugPrint('adivery preload: $e');
    }
  }

  Future<AdShowResult> _show(AdFormat f, Duration timeout) async {
    final p = _placement(f);
    if (!_initialized || p == null) return const AdShowResult.notReady();
    if (!await _checkLoaded(f)) {
      preload(f);
      final deadline = DateTime.now().add(timeout);
      var loaded = false;
      while (!loaded && DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 250));
        loaded = await _checkLoaded(f);
      }
      if (!loaded) return const AdShowResult.notReady();
    }
    _lastRewarded = false;
    final c = _showing = Completer<AdShowResult>();
    try {
      AdiveryPlugin.show(p);
    } catch (e) {
      return AdShowResult.failed('$e');
    }
    _ready[f] = false;
    // Full-screen ads close by user action; cap the wait so a lost callback
    // can never freeze the game.
    final result = await c.future.timeout(
      const Duration(minutes: 2),
      onTimeout: () => const AdShowResult(AdShowStatus.shown),
    );
    preload(f); // next one
    return result;
  }

  @override
  Future<AdShowResult> showInterstitial({
    Duration timeout = const Duration(seconds: 3),
  }) => _show(AdFormat.interstitial, timeout);

  @override
  Future<AdShowResult> showRewarded({
    Duration timeout = const Duration(seconds: 3),
  }) => _show(AdFormat.rewarded, timeout);

  @override
  Widget? buildBanner() {
    final p = _placement(AdFormat.banner);
    if (!_initialized || p == null) return null;
    return adv.BannerAd(
      p,
      adv.BannerAdSize.BANNER,
      onError: (_, reason) => debugPrint('adivery banner: $reason'),
    );
  }
}

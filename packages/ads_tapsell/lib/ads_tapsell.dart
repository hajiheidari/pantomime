import 'dart:async';
import 'dart:io' show Platform;

import 'package:ads_core/ads_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:tapsell_plus/tapsell_plus.dart';

/// Tapsell Plus mediation SDK. Android only.
///
/// Ids: `app_id` (app key), `interstitial`, `rewarded`, `banner` (zone ids).
class TapsellProvider implements AdProvider {
  @override
  String get id => 'tapsell';

  AdIds _ids = const {};
  bool _initialized = false;

  /// Loaded response ids per format (Tapsell ads are shown by response id).
  final Map<AdFormat, String> _loaded = {};
  final Map<AdFormat, Future<void>> _loading = {};

  bool get _supported => !kIsWeb && Platform.isAndroid;

  String? _zone(AdFormat f) {
    final v = _ids[f.name];
    return (v == null || v.isEmpty) ? null : v;
  }

  @override
  Future<void> init(AdIds ids) async {
    _ids = ids;
    final key = ids['app_id'] ?? '';
    if (!_supported || key.isEmpty || _initialized) return;
    try {
      _initialized = await TapsellPlus.instance.initialize(key);
    } catch (e) {
      debugPrint('tapsell init: $e');
    }
  }

  @override
  bool isReady(AdFormat format) => _loaded.containsKey(format);

  @override
  void preload(AdFormat format) {
    if (format == AdFormat.banner) return;
    _loading[format] ??= _load(format)
        .whenComplete(() => _loading.remove(format));
  }

  Future<void> _load(AdFormat f) async {
    final zone = _zone(f);
    if (!_initialized || zone == null) return;
    try {
      final responseId = f == AdFormat.interstitial
          ? await TapsellPlus.instance.requestInterstitialAd(zone)
          : await TapsellPlus.instance.requestRewardedVideoAd(zone);
      if (responseId.isNotEmpty) _loaded[f] = responseId;
    } catch (e) {
      debugPrint('tapsell load $f: $e');
      rethrow;
    }
  }

  Future<AdShowResult> _show(AdFormat f, Duration timeout) async {
    if (!_initialized || _zone(f) == null) {
      return const AdShowResult.notReady();
    }
    if (!isReady(f)) {
      preload(f);
      try {
        await _loading[f]?.timeout(timeout);
      } on TimeoutException {
        return const AdShowResult.notReady();
      } catch (e) {
        return AdShowResult.failed('$e');
      }
      if (!isReady(f)) return const AdShowResult.notReady();
    }
    final responseId = _loaded.remove(f)!;
    final done = Completer<AdShowResult>();
    var rewarded = false;
    void finish(AdShowResult r) {
      if (!done.isCompleted) done.complete(r);
    }

    try {
      final callbacks = (
        onRewarded: (Map<String, String> _) => rewarded = true,
        onClosed: (Map<String, String> _) =>
            finish(AdShowResult(AdShowStatus.shown, rewarded: rewarded)),
        onError: (Map<String, String> e) =>
            finish(AdShowResult.failed(e['error_message'] ?? '$e')),
      );
      final ok = f == AdFormat.interstitial
          ? await TapsellPlus.instance.showInterstitialAd(
              responseId,
              onClosed: callbacks.onClosed,
              onError: callbacks.onError,
            )
          : await TapsellPlus.instance.showRewardedVideoAd(
              responseId,
              onRewarded: callbacks.onRewarded,
              onClosed: callbacks.onClosed,
              onError: callbacks.onError,
            );
      if (!ok) finish(const AdShowResult.failed('show returned false'));
    } catch (e) {
      finish(AdShowResult.failed('$e'));
    }
    final result = await done.future.timeout(
      const Duration(minutes: 2),
      onTimeout: () => AdShowResult(AdShowStatus.shown, rewarded: rewarded),
    );
    preload(f);
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
    final zone = _zone(AdFormat.banner);
    if (!_initialized || zone == null) return null;
    return _TapsellBanner(zone: zone);
  }
}

/// Tapsell banners are native overlays pinned to the bottom of the screen.
/// This widget reserves the space and shows/destroys the banner with its own
/// lifecycle.
class _TapsellBanner extends StatefulWidget {
  const _TapsellBanner({required this.zone});

  final String zone;

  @override
  State<_TapsellBanner> createState() => _TapsellBannerState();
}

class _TapsellBannerState extends State<_TapsellBanner> {
  String? _responseId;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    TapsellPlus.instance
        .requestStandardBannerAd(
          widget.zone,
          TapsellPlusBannerType.BANNER_320x50,
          onResponse: (map) {
            final id = map['response_id'];
            if (id == null || _disposed) return;
            _responseId = id;
            TapsellPlus.instance.showStandardBannerAd(
              id,
              TapsellPlusHorizontalGravity.BOTTOM,
              TapsellPlusVerticalGravity.CENTER,
            );
          },
          onError: (e) => debugPrint('tapsell banner: $e'),
        )
        .catchError((Object e) {
          debugPrint('tapsell banner: $e');
          return false;
        });
  }

  @override
  void dispose() {
    _disposed = true;
    final id = _responseId;
    if (id != null) {
      TapsellPlus.instance.destroyStandardBanner(id).catchError((_) => false);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox(height: 50);
}

import 'dart:async';

import 'package:ads_core/ads_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Google AdMob (google_mobile_ads). Used on iOS and the Google Play build
/// only — never compiled into Bazaar / Myket builds.
///
/// Ids: `interstitial`, `rewarded`, `banner` (ad unit ids for the current
/// platform). The AdMob *app id* lives in AndroidManifest / Info.plist.
class AdmobProvider implements AdProvider {
  @override
  String get id => 'admob';

  AdIds _ids = const {};
  bool _initialized = false;

  InterstitialAd? _interstitial;
  RewardedAd? _rewarded;
  final Map<AdFormat, Completer<void>> _loading = {};

  String? _unit(AdFormat f) {
    final v = _ids[f.name];
    return (v == null || v.isEmpty) ? null : v;
  }

  @override
  Future<void> init(AdIds ids) async {
    _ids = ids;
    if (_initialized || kIsWeb) return;
    try {
      await MobileAds.instance.initialize();
      _initialized = true;
    } catch (e) {
      debugPrint('admob init: $e');
    }
  }

  @override
  bool isReady(AdFormat format) => switch (format) {
    AdFormat.interstitial => _interstitial != null,
    AdFormat.rewarded => _rewarded != null,
    AdFormat.banner => _initialized && _unit(AdFormat.banner) != null,
  };

  @override
  void preload(AdFormat format) {
    final unit = _unit(format);
    if (!_initialized || unit == null || isReady(format)) return;
    if (_loading.containsKey(format)) return;
    final c = _loading[format] = Completer<void>();
    void done() {
      _loading.remove(format);
      if (!c.isCompleted) c.complete();
    }

    void failed(LoadAdError e) {
      debugPrint('admob load $format: $e');
      _loading.remove(format);
      if (!c.isCompleted) c.completeError(e);
    }

    try {
      switch (format) {
        case AdFormat.interstitial:
          InterstitialAd.load(
            adUnitId: unit,
            request: const AdRequest(),
            adLoadCallback: InterstitialAdLoadCallback(
              onAdLoaded: (ad) {
                _interstitial = ad;
                done();
              },
              onAdFailedToLoad: failed,
            ),
          );
        case AdFormat.rewarded:
          RewardedAd.load(
            adUnitId: unit,
            request: const AdRequest(),
            rewardedAdLoadCallback: RewardedAdLoadCallback(
              onAdLoaded: (ad) {
                _rewarded = ad;
                done();
              },
              onAdFailedToLoad: failed,
            ),
          );
        case AdFormat.banner:
          done();
      }
    } catch (e) {
      debugPrint('admob preload: $e');
      _loading.remove(format);
    }
  }

  Future<AdShowResult?> _await(AdFormat f, Duration timeout) async {
    if (isReady(f)) return null;
    if (!_initialized || _unit(f) == null) return const AdShowResult.notReady();
    preload(f);
    try {
      await _loading[f]?.future.timeout(timeout);
    } on TimeoutException {
      return const AdShowResult.notReady();
    } catch (e) {
      return AdShowResult.failed('$e');
    }
    return isReady(f) ? null : const AdShowResult.notReady();
  }

  /// Shows a full-screen ad; resolves when it is dismissed or fails.
  Future<AdShowResult> _present(
    AdFormat f,
    void Function(
      void Function() onDismissed,
      void Function(String reason) onFailed,
    )
    attachAndShow,
    bool Function() rewarded,
  ) {
    final done = Completer<AdShowResult>();
    void finish(AdShowResult r) {
      if (!done.isCompleted) done.complete(r);
      preload(f);
    }

    try {
      attachAndShow(
        () => finish(AdShowResult(AdShowStatus.shown, rewarded: rewarded())),
        (reason) => finish(AdShowResult.failed(reason)),
      );
    } catch (e) {
      finish(AdShowResult.failed('$e'));
    }
    return done.future.timeout(
      const Duration(minutes: 2),
      onTimeout: () => AdShowResult(AdShowStatus.shown, rewarded: rewarded()),
    );
  }

  @override
  Future<AdShowResult> showInterstitial({
    Duration timeout = const Duration(seconds: 3),
  }) async {
    final early = await _await(AdFormat.interstitial, timeout);
    if (early != null) return early;
    final ad = _interstitial!;
    _interstitial = null;
    return _present(AdFormat.interstitial, (dismissed, failed) {
      ad.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (a) {
          a.dispose();
          dismissed();
        },
        onAdFailedToShowFullScreenContent: (a, e) {
          a.dispose();
          failed(e.message);
        },
      );
      ad.show();
    }, () => false);
  }

  @override
  Future<AdShowResult> showRewarded({
    Duration timeout = const Duration(seconds: 3),
  }) async {
    final early = await _await(AdFormat.rewarded, timeout);
    if (early != null) return early;
    final ad = _rewarded!;
    _rewarded = null;
    var earned = false;
    return _present(AdFormat.rewarded, (dismissed, failed) {
      ad.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (a) {
          a.dispose();
          dismissed();
        },
        onAdFailedToShowFullScreenContent: (a, e) {
          a.dispose();
          failed(e.message);
        },
      );
      ad.show(onUserEarnedReward: (_, _) => earned = true);
    }, () => earned);
  }

  @override
  Widget? buildBanner() {
    final unit = _unit(AdFormat.banner);
    if (!_initialized || unit == null) return null;
    return _AdmobBanner(unit: unit);
  }
}

class _AdmobBanner extends StatefulWidget {
  const _AdmobBanner({required this.unit});

  final String unit;

  @override
  State<_AdmobBanner> createState() => _AdmobBannerState();
}

class _AdmobBannerState extends State<_AdmobBanner> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _ad = BannerAd(
      adUnitId: widget.unit,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, e) {
          debugPrint('admob banner: $e');
          ad.dispose();
          _ad = null;
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (ad == null || !_loaded) return const SizedBox(height: 50);
    return SizedBox(
      width: ad.size.width.toDouble(),
      height: ad.size.height.toDouble(),
      child: AdWidget(ad: ad),
    );
  }
}

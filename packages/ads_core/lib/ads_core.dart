/// Ad provider interface. Each ad network lives in its own package
/// (ads_adivery, ads_tapsell, ads_admob) so a store build can leave an SDK
/// out entirely (e.g. no AdMob / Google Play Services in Bazaar and Myket).
library;

import 'package:flutter/widgets.dart';

enum AdFormat { interstitial, rewarded, banner }

enum AdShowStatus {
  /// The ad was shown (and, for rewarded ads, see [AdShowResult.rewarded]).
  shown,

  /// Nothing was ready in time; skipped silently.
  notReady,

  /// The network reported an error while loading or showing.
  failed,
}

class AdShowResult {
  const AdShowResult(this.status, {this.rewarded = false, this.reason});

  const AdShowResult.notReady() : this(AdShowStatus.notReady);
  const AdShowResult.failed(String reason)
    : this(AdShowStatus.failed, reason: reason);

  final AdShowStatus status;

  /// Rewarded ads only: the user watched long enough to earn the reward.
  final bool rewarded;
  final String? reason;

  bool get shown => status == AdShowStatus.shown;

  @override
  String toString() => 'AdShowResult($status, rewarded: $rewarded, $reason)';
}

/// Ids of one network: app id / key and placement (zone / unit) ids.
///
/// Keys used by the built-in providers:
/// `app_id`, `interstitial`, `rewarded`, `banner`.
typedef AdIds = Map<String, String>;

/// One ad network. Implementations must never throw and never block the
/// caller for long; failures are reported through [AdShowResult].
abstract interface class AdProvider {
  /// Stable id used in remote config: `adivery`, `tapsell`, `admob`.
  String get id;

  /// Initializes the SDK. Safe to call more than once; later calls may pass
  /// updated ids.
  Future<void> init(AdIds ids);

  bool isReady(AdFormat format);

  /// Starts loading an ad in the background.
  void preload(AdFormat format);

  /// Shows an interstitial if one becomes ready within [timeout].
  Future<AdShowResult> showInterstitial({Duration timeout});

  /// Shows a rewarded ad if one becomes ready within [timeout].
  Future<AdShowResult> showRewarded({Duration timeout});

  /// A small banner widget, or `null` when banners are unavailable.
  Widget? buildBanner();
}

/// Waits until [isReady] or [timeout]; used by providers whose SDK has no
/// awaitable load call.
Future<bool> waitUntilReady(
  bool Function() isReady, {
  required Duration timeout,
  Duration poll = const Duration(milliseconds: 100),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!isReady()) {
    if (DateTime.now().isAfter(deadline)) return false;
    await Future<void>.delayed(poll);
  }
  return true;
}

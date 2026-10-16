import 'package:ads_core/ads_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantomime/core/store/app_store.dart';
import 'package:pantomime/features/ads/ad_manager.dart';
import 'package:pantomime/features/ads/config/remote_config.dart';

import 'remote_config_test.dart' show specExample;

class FakeProvider implements AdProvider {
  FakeProvider(this.id);

  @override
  final String id;
  AdShowResult next = const AdShowResult(AdShowStatus.shown);
  int interstitials = 0;
  int rewardeds = 0;
  AdIds? initIds;

  @override
  Future<void> init(AdIds ids) async => initIds = ids;

  @override
  bool isReady(AdFormat format) => true;

  @override
  void preload(AdFormat format) {}

  @override
  Future<AdShowResult> showInterstitial({Duration? timeout}) async {
    interstitials++;
    return next;
  }

  @override
  Future<AdShowResult> showRewarded({Duration? timeout}) async {
    rewardeds++;
    return next;
  }

  @override
  Widget? buildBanner() => const SizedBox(key: Key('banner'));
}

void main() {
  late Map<String, FakeProvider> fakes;
  late RemoteConfig config;
  var gameplayActive = false;

  RemoteConfig cfg(void Function(Map<String, dynamic> ads) f) {
    final json = specExample();
    final ads = json['ads'] as Map<String, dynamic>;
    ads['ab_split'] = null;
    f(ads);
    return RemoteConfig.parse(json);
  }

  AdManager manager({AppStore store = AppStore.play, Set<String>? compiled}) =>
      AdManager(
        store: store,
        installId: 'install',
        factories: {
          for (final id in compiled ?? fakes.keys.toSet()) id: () => fakes[id]!,
        },
        config: () => config,
        localIds: (p) => {'app_id': 'local-$p', 'banner': 'local-banner'},
        isGameplayActive: () => gameplayActive,
      );

  setUp(() {
    fakes = {for (final id in knownAdProviders) id: FakeProvider(id)};
    config = cfg((_) {});
    gameplayActive = false;
  });

  test('interstitial every N turn transitions', () async {
    config = cfg((a) => a['interstitial_every_n_rounds'] = 3);
    final m = manager();
    for (var i = 0; i < 7; i++) {
      await m.onTurnTransition();
    }
    expect(fakes['adivery']!.interstitials, 2); // after 3rd and 6th
  });

  test('never during a running round', () async {
    config = cfg((a) => a['interstitial_every_n_rounds'] = 1);
    gameplayActive = true;
    final m = manager();
    await m.onTurnTransition();
    expect(await m.showRewarded(), RewardOutcome.unavailable);
    expect(fakes['adivery']!.interstitials, 0);
    expect(fakes['adivery']!.rewardeds, 0);
  });

  test('ads disabled → nothing shown, bonus unlocks freely', () async {
    config = cfg((a) {
      a['enabled'] = false;
      a['interstitial_every_n_rounds'] = 1;
    });
    final m = manager();
    await m.onTurnTransition();
    expect(fakes.values.every((f) => f.interstitials == 0), isTrue);
    expect(m.rewardedOffered, isFalse);
    expect(m.homeBanner(), isNull);
  });

  test('no ad network in the build (iOS) → no rewarded offer', () async {
    final m = manager(store: AppStore.ios, compiled: const {});
    expect(m.rewardedOffered, isFalse);
    expect(await m.showRewarded(), RewardOutcome.unavailable);
  });

  test('3 consecutive failures → next provider in the chain', () async {
    config = cfg((a) => a['interstitial_every_n_rounds'] = 1);
    fakes['adivery']!.next = const AdShowResult.notReady();
    final m = manager();
    for (var i = 0; i < 3; i++) {
      await m.onTurnTransition();
    }
    expect(fakes['adivery']!.interstitials, 3);
    expect(m.currentProviderId, 'tapsell');
    await m.onTurnTransition();
    expect(fakes['tapsell']!.interstitials, 1);
  });

  test('a success resets the failure count', () async {
    config = cfg((a) => a['interstitial_every_n_rounds'] = 1);
    final f = fakes['adivery']!;
    final m = manager();
    f.next = const AdShowResult.failed('x');
    await m.onTurnTransition();
    await m.onTurnTransition();
    f.next = const AdShowResult(AdShowStatus.shown);
    await m.onTurnTransition();
    f.next = const AdShowResult.failed('x');
    await m.onTurnTransition();
    await m.onTurnTransition();
    expect(m.currentProviderId, 'adivery');
  });

  test('rewarded outcomes', () async {
    final m = manager();
    final f = fakes['adivery']!;
    f.next = const AdShowResult(AdShowStatus.shown, rewarded: true);
    expect(await m.showRewarded(), RewardOutcome.earned);
    f.next = const AdShowResult(AdShowStatus.shown);
    expect(await m.showRewarded(), RewardOutcome.skipped);
    f.next = const AdShowResult.notReady();
    expect(await m.showRewarded(), RewardOutcome.unavailable);
  });

  test('bazaar build never uses AdMob; remote ids override local', () async {
    config = cfg((a) {
      (a['fallback_chain'] as Map)['bazaar'] = ['adivery', 'tapsell'];
      a['interstitial_every_n_rounds'] = 1;
    });
    final m = manager(store: AppStore.bazaar, compiled: {'adivery', 'admob'});
    fakes['adivery']!.next = const AdShowResult.failed('no fill');
    for (var i = 0; i < 5; i++) {
      await m.onTurnTransition();
    }
    expect(fakes['admob']!.interstitials, 0);
    expect(m.currentProviderId, isNull);
    expect(fakes['adivery']!.initIds, {
      'app_id': 'A', // remote wins over 'local-adivery'
      'interstitial': 'I',
      'banner': 'B',
    });
  });

  test('home banner only when enabled', () async {
    final m = manager();
    await m.warmUp();
    expect(m.homeBanner(), isNotNull);
    config = cfg((a) => a['banner_on_home'] = false);
    expect(m.homeBanner(), isNull);
  });
}

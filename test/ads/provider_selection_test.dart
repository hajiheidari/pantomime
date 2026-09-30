import 'package:flutter_test/flutter_test.dart';
import 'package:pantomime/core/store/app_store.dart';
import 'package:pantomime/features/ads/config/provider_selection.dart';
import 'package:pantomime/features/ads/config/remote_config.dart';

import 'remote_config_test.dart' show specExample;

AdsConfig ads([void Function(Map<String, dynamic>)? f]) {
  final json = specExample();
  f?.call(json['ads'] as Map<String, dynamic>);
  return RemoteConfig.parse(json).ads;
}

void main() {
  const all = {'adivery', 'tapsell', 'admob'};

  test('A/B assignment is deterministic per install', () {
    const split = {'adivery': 50, 'tapsell': 50};
    for (var i = 0; i < 50; i++) {
      final id = 'install-$i';
      expect(
        pickFromSplit(split, id, AppStore.bazaar),
        pickFromSplit(split, id, AppStore.bazaar),
      );
    }
  });

  test('A/B assignment follows the percentages', () {
    for (final split in [
      {'adivery': 50, 'tapsell': 50},
      {'adivery': 80, 'tapsell': 20},
      {'adivery': 0, 'tapsell': 100},
    ]) {
      final counts = <String, int>{};
      const n = 20000;
      for (var i = 0; i < n; i++) {
        final p = pickFromSplit(split, 'id-$i-x', AppStore.myket);
        counts[p] = (counts[p] ?? 0) + 1;
      }
      for (final e in split.entries) {
        expect(
          (counts[e.key] ?? 0) / n,
          closeTo(e.value / 100, 0.02),
          reason: '$split',
        );
      }
    }
  });

  test('no split → active provider, then fallback chain', () {
    final c = ads((a) => a['ab_split'] = null);
    expect(
      providerChain(
        ads: c,
        store: AppStore.play,
        installId: 'x',
        compiled: all,
      ),
      ['adivery', 'tapsell', 'admob'],
    );
    expect(
      providerChain(ads: c, store: AppStore.ios, installId: 'x', compiled: all),
      ['admob'],
    );
  });

  test('split winner comes first', () {
    final c = ads();
    final chain = providerChain(
      ads: c,
      store: AppStore.bazaar,
      installId: 'abc',
      compiled: all,
    );
    expect(
      chain.first,
      pickFromSplit({'adivery': 50, 'tapsell': 50}, 'abc', AppStore.bazaar),
    );
    expect(chain.toSet(), {'adivery', 'tapsell'});
  });

  test('only compiled-in, non-failed providers are used', () {
    final c = ads((a) => a['ab_split'] = null);
    expect(
      providerChain(
        ads: c,
        store: AppStore.bazaar,
        installId: 'x',
        compiled: {'adivery'},
      ),
      ['adivery'],
    );
    expect(
      providerChain(
        ads: c,
        store: AppStore.play,
        installId: 'x',
        compiled: all,
        failed: {'adivery'},
      ),
      ['tapsell', 'admob'],
    );
    expect(
      providerChain(
        ads: c,
        store: AppStore.play,
        installId: 'x',
        compiled: all,
        failed: all,
      ),
      isEmpty,
    );
  });

  test('A/B winner missing from the build → store active provider', () {
    final c = ads((a) => (a['ab_split'] as Map)['bazaar'] = {'tapsell': 100});
    expect(
      providerChain(
        ads: c,
        store: AppStore.bazaar,
        installId: 'x',
        compiled: {'adivery'},
      ),
      ['adivery'],
    );
  });

  test('AdMob is never chosen on Bazaar / Myket even if compiled in', () {
    // Build a config object directly, bypassing validation.
    const c = AdsConfig(
      enabled: true,
      activeProvider: {AppStore.bazaar: 'admob'},
      abSplit: {},
      fallbackChain: {
        AppStore.myket: ['admob', 'adivery'],
      },
      providerIds: {},
      admobIds: {},
      interstitialEveryNRounds: 3,
      bannerOnHome: true,
      rewardedEnabled: true,
    );
    expect(
      providerChain(
        ads: c,
        store: AppStore.bazaar,
        installId: 'x',
        compiled: all,
      ),
      isEmpty,
    );
    expect(
      providerChain(
        ads: c,
        store: AppStore.myket,
        installId: 'x',
        compiled: all,
      ),
      ['adivery'],
    );
  });
}

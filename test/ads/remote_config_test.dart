import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pantomime/core/store/app_store.dart';
import 'package:pantomime/features/ads/config/remote_config.dart';

/// The example from the project spec.
Map<String, dynamic> specExample() =>
    jsonDecode(jsonEncode(_spec)) as Map<String, dynamic>;

const _spec = {
  'config_version': 12,
  'ads': {
    'enabled': true,
    'active_provider': {
      'play': 'adivery',
      'bazaar': 'adivery',
      'myket': 'adivery',
      'ios': 'admob',
    },
    'ab_split': {
      'play': {'adivery': 50, 'tapsell': 50},
      'bazaar': {'adivery': 50, 'tapsell': 50},
      'myket': {'adivery': 50, 'tapsell': 50},
    },
    'fallback_chain': {
      'play': ['adivery', 'tapsell', 'admob'],
      'bazaar': ['adivery', 'tapsell'],
      'myket': ['adivery', 'tapsell'],
      'ios': ['admob'],
    },
    'providers': {
      'adivery': {
        'app_id': 'A',
        'interstitial_placement': 'I',
        'rewarded_placement': '',
        'banner_placement': 'B',
      },
      'tapsell': {
        'app_key': 'K',
        'interstitial_zone': 'TI',
        'rewarded_zone': 'TR',
        'banner_zone': '',
      },
      'admob': {
        'android': {'interstitial': 'ai', 'rewarded': '', 'banner': ''},
        'ios': {'interstitial': 'ii', 'rewarded': 'ir', 'banner': 'ib'},
      },
    },
    'interstitial_every_n_rounds': 3,
    'banner_on_home': true,
    'rewarded_enabled': true,
  },
  'min_supported_version': '1.0.0',
  'message': null,
};

Map<String, dynamic> mutate(void Function(Map<String, dynamic> ads) f) {
  final c = specExample();
  f(c['ads'] as Map<String, dynamic>);
  return c;
}

void main() {
  test('parses the spec example', () {
    final c = RemoteConfig.parse(specExample());
    expect(c.configVersion, 12);
    expect(c.ads.enabled, isTrue);
    expect(c.ads.activeProvider[AppStore.ios], 'admob');
    expect(c.ads.abSplit[AppStore.bazaar], {'adivery': 50, 'tapsell': 50});
    expect(c.ads.fallbackChain[AppStore.play], ['adivery', 'tapsell', 'admob']);
    expect(c.ads.providerIds['adivery'], {
      'app_id': 'A',
      'interstitial': 'I',
      'banner': 'B',
    });
    expect(c.ads.providerIds['tapsell']!['app_id'], 'K');
    expect(c.ads.admobIds['ios']!['banner'], 'ib');
    expect(c.ads.admobIds['android'], {'interstitial': 'ai'});
    expect(c.message, isNull);
  });

  test('bundled default config is valid', () {
    final raw = File('assets/config/default_config.json').readAsStringSync();
    final c = RemoteConfig.parse(jsonDecode(raw));
    expect(c.ads.abSplit, isEmpty);
    expect(c.ads.activeProvider[AppStore.bazaar], 'adivery');
  });

  test('ab_split null or per-store null means no A/B test', () {
    expect(
      RemoteConfig.parse(mutate((a) => a['ab_split'] = null)).ads.abSplit,
      isEmpty,
    );
    final c = RemoteConfig.parse(
      mutate((a) => (a['ab_split'] as Map)['play'] = null),
    );
    expect(c.ads.abSplit.containsKey(AppStore.play), isFalse);
    expect(c.ads.abSplit.containsKey(AppStore.bazaar), isTrue);
  });

  group('rejects', () {
    final cases = <String, Map<String, dynamic>>{
      'unknown provider': mutate(
        (a) => (a['active_provider'] as Map)['play'] = 'unityads',
      ),
      'unknown store': mutate(
        (a) => (a['active_provider'] as Map)['huawei'] = 'adivery',
      ),
      'admob on bazaar': mutate(
        (a) => (a['fallback_chain'] as Map)['bazaar'] = ['adivery', 'admob'],
      ),
      'admob active on myket': mutate(
        (a) => (a['active_provider'] as Map)['myket'] = 'admob',
      ),
      'split not summing to 100': mutate(
        (a) => (a['ab_split'] as Map)['play'] = {'adivery': 60, 'tapsell': 60},
      ),
      'split with unknown provider': mutate(
        (a) => (a['ab_split'] as Map)['play'] = {'adivery': 50, 'x': 50},
      ),
      'frequency out of range': mutate(
        (a) => a['interstitial_every_n_rounds'] = 0,
      ),
      'enabled not bool': mutate((a) => a['enabled'] = 'yes'),
      'id not a string': mutate(
        (a) => (a['providers'] as Map)['adivery'] = {'app_id': 5},
      ),
      'unknown provider ids': mutate(
        (a) => (a['providers'] as Map)['facebook'] = {'app_id': 'x'},
      ),
    };
    for (final e in cases.entries) {
      test(e.key, () {
        expect(
          () => RemoteConfig.parse(e.value),
          throwsA(isA<ConfigFormatException>()),
        );
        expect(RemoteConfig.tryParse(e.value), isNull);
      });
    }

    test('missing version / bad min version / huge message', () {
      expect(
        RemoteConfig.tryParse({...specExample()}..remove('config_version')),
        isNull,
      );
      expect(
        RemoteConfig.tryParse({
          ...specExample(),
          'min_supported_version': 'latest',
        }),
        isNull,
      );
      expect(
        RemoteConfig.tryParse({...specExample(), 'message': 'x' * 501}),
        isNull,
      );
      expect(RemoteConfig.tryParse('not a map'), isNull);
    });
  });

  test('unknown keys are ignored (cannot change gameplay)', () {
    final c = RemoteConfig.parse({
      ...specExample(),
      'round_seconds': 5,
      'hide_forehead_mode': true,
    });
    expect(c.configVersion, 12);
  });

  test('notice text', () {
    expect(
      RemoteConfig.parse({...specExample(), 'message': '  '}).message,
      isNull,
    );
    expect(
      RemoteConfig.parse({...specExample(), 'message': 'سلام'}).message,
      'سلام',
    );
  });

  test('compareVersions', () {
    expect(compareVersions('1.2.10', '1.2.9'), greaterThan(0));
    expect(compareVersions('1.0.0', '1.0.0'), 0);
    expect(compareVersions('1.0.0+5', '1.0.1'), lessThan(0));
    expect(compareVersions('2.0', '1.9.9'), greaterThan(0));
  });
}

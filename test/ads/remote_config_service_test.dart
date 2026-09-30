import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pantomime/core/store/app_store.dart';
import 'package:pantomime/features/ads/config/remote_config_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'remote_config_test.dart' show specExample;

String configJson({int version = 12, String playProvider = 'adivery'}) {
  final c = specExample();
  c['config_version'] = version;
  ((c['ads'] as Map)['active_provider'] as Map)['play'] = playProvider;
  return jsonEncode(c);
}

const primary = 'https://primary.example/config.json';
const mirror = 'https://mirror.example/config.json';

void main() {
  late SharedPreferences prefs;
  final bundled = configJson(version: 0);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  });

  RemoteConfigService service(
    Future<http.Response> Function(http.Request) handler, {
    DateTime Function()? now,
  }) => RemoteConfigService(
    prefs: prefs,
    loadBundled: () async => bundled,
    client: MockClient(handler),
    urls: const [primary, mirror],
    timeout: const Duration(milliseconds: 200),
    now: now,
  );

  test('no network → bundled default, app still works', () async {
    final s = service((_) async => throw const SocketLike());
    expect((await s.loadLocal()).configVersion, 0);
    expect(await s.refresh(), isFalse);
    expect(s.current.configVersion, 0);
  });

  test('primary fails → mirror is used and cached', () async {
    final hits = <String>[];
    final s = service((req) async {
      hits.add(req.url.toString());
      return req.url.toString() == primary
          ? http.Response('down', 503)
          : http.Response(configJson(version: 5), 200);
    });
    await s.loadLocal();
    expect(await s.refresh(), isTrue);
    expect(hits, [primary, mirror]);
    expect(s.current.configVersion, 5);

    // Next launch, offline: the cached (last good) config is used.
    final offline = service((_) async => throw const SocketLike());
    expect((await offline.loadLocal()).configVersion, 5);
  });

  test('primary timeout → mirror', () async {
    final s = service((req) async {
      if (req.url.toString() == primary) {
        await Future<void>.delayed(const Duration(seconds: 2));
      }
      return http.Response(configJson(version: 7), 200);
    });
    await s.loadLocal();
    expect(await s.refresh(), isTrue);
    expect(s.current.configVersion, 7);
  });

  test('invalid config (unknown provider) keeps the last good one', () async {
    final s = service(
      (_) async => http.Response(configJson(playProvider: 'unityads'), 200),
    );
    await s.loadLocal();
    expect(await s.refresh(), isFalse);
    expect(s.current.configVersion, 0);
    expect(s.current.ads.activeProvider[AppStore.play], 'adivery');
  });

  test('a stale mirror never downgrades the config', () async {
    var version = 9;
    final s = service(
      (_) async => http.Response(configJson(version: version), 200),
    );
    await s.loadLocal();
    await s.refresh(force: true);
    version = 4;
    expect(await s.refresh(force: true), isFalse);
    expect(s.current.configVersion, 9);
  });

  test('fetches at most once per interval unless forced', () async {
    var calls = 0;
    var now = DateTime(2026, 1, 1, 12);
    final s = service((_) async {
      calls++;
      return http.Response(configJson(version: 3), 200);
    }, now: () => now);
    await s.loadLocal();
    await s.refresh();
    await s.refresh();
    expect(calls, 1);
    now = now.add(const Duration(hours: 2));
    await s.refresh();
    expect(calls, 2);
  });

  test('changes stream emits the new config', () async {
    final s = service((_) async => http.Response(configJson(version: 2), 200));
    await s.loadLocal();
    final next = s.changes.first;
    await s.refresh();
    expect((await next).configVersion, 2);
  });
}

class SocketLike implements Exception {
  const SocketLike();
}

import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pantomime/features/words/data/remote_words.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Serves the real asset files from disk.
class _DiskBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    final f = File(key);
    if (!f.existsSync()) throw StateError('missing $key');
    return ByteData.sublistView(f.readAsBytesSync());
  }
}

String _bundledFa() => File('assets/words/words_fa.json').readAsStringSync();

/// The bundled pack with [version] and one extra word.
String _newerPack(int version) {
  final json = jsonDecode(_bundledFa()) as Map<String, dynamic>;
  json['version'] = version;
  final first = (json['categories'] as List).first as Map<String, dynamic>;
  ((first['words'] as Map)['easy'] as List).add('کلمه‌ی تازه');
  return jsonEncode(json);
}

void main() {
  late SharedPreferences prefs;
  final requested = <String>[];

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    requested.clear();
  });

  UpdatableWordRepository repo(
    Future<http.Response> Function(http.Request) handler, {
    DateTime Function()? now,
  }) => UpdatableWordRepository(
    prefs: prefs,
    bundle: _DiskBundle(),
    client: MockClient((r) {
      requested.add(r.url.toString());
      return handler(r);
    }),
    urls: (lang) => ['https://primary/words_$lang.json', 'https://mirror/x'],
    now: now,
  );

  http.Response ok(String body) => http.Response.bytes(utf8.encode(body), 200);

  test('urls: sibling of the config, php mirror gets ?file=', () {
    expect(
      wordPackUrls(
        'fa',
        primary: 'https://api.example.com/config.json',
        iran: 'https://example.ir/api/config.json',
        fallback: 'https://w.example.dev/config.json',
        mirror: 'https://host.ir/pantomime-config.php',
      ),
      [
        'https://api.example.com/words_fa.json',
        'https://example.ir/api/words_fa.json',
        'https://w.example.dev/words_fa.json',
        'https://host.ir/pantomime-config.php?file=words_fa.json',
      ],
    );
  });

  test('offline: bundled words, no crash', () async {
    final r = repo((_) async => throw const SocketException('offline'));
    final bundledCount = (await r.loadCategories('fa')).length;
    expect(bundledCount, greaterThan(5));
    expect(await r.refresh('fa'), isFalse);
    expect((await r.loadCategories('fa')).length, bundledCount);
  });

  test('newer pack is stored and survives a restart', () async {
    final r = repo((_) async => ok(_newerPack(5)));
    expect(await r.refresh('fa'), isTrue);
    expect(await r.versionOf('fa'), 5);
    final again = repo((_) async => throw const SocketException('offline'));
    expect(await again.versionOf('fa'), 5);
    final words = (await again.loadCategories('fa'))
        .expand((c) => c.wordsFor(c.words.keys.toSet()))
        .map((w) => w.text);
    expect(words, contains('کلمه‌ی تازه'));
  });

  test('same or older version is ignored', () async {
    final r = repo((_) async => ok(_newerPack(1)));
    expect(await r.refresh('fa'), isFalse);
    expect(prefs.getString('words.remote.fa'), isNull);
  });

  test('broken or tiny packs never replace the words', () async {
    for (final body in [
      'not json',
      '{"version": 9, "language": "fa", "categories": []}',
      jsonEncode({
        'version': 9,
        'language': 'en',
        'categories': (jsonDecode(_bundledFa()) as Map)['categories'],
      }),
    ]) {
      final r = repo((_) async => ok(body));
      expect(await r.refresh('fa', force: true), isFalse, reason: body);
    }
    expect(prefs.getString('words.remote.fa'), isNull);
  });

  test('primary down → mirror', () async {
    final r = repo(
      (req) async => req.url.host == 'primary'
          ? http.Response('nope', 500)
          : ok(_newerPack(3)),
    );
    expect(await r.refresh('fa'), isTrue);
    expect(requested, ['https://primary/words_fa.json', 'https://mirror/x']);
  });

  test('refreshes at most every 6 hours', () async {
    var t = DateTime(2026, 1, 1, 10);
    final r = repo((_) async => ok(_newerPack(2)), now: () => t);
    await r.refresh('fa');
    requested.clear();
    t = t.add(const Duration(hours: 1));
    await r.refresh('fa');
    expect(requested, isEmpty);
    t = t.add(const Duration(hours: 6));
    await r.refresh('fa');
    expect(requested, isNotEmpty);
  });
}

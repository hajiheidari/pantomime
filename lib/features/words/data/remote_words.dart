import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../ads/config/remote_config_service.dart';
import '../domain/word_models.dart';
import 'word_repository.dart';

/// Where a word pack for [languageCode] can be downloaded: next to the
/// config on the primary server, the Iranian copy and the fallback address,
/// and through the older mirror (`pantomime-config.php?file=words_fa.json`).
List<String> wordPackUrls(
  String languageCode, {
  String primary = configPrimaryUrl,
  String iran = configIranUrl,
  String fallback = configFallbackUrl,
  String mirror = configMirrorUrl,
}) {
  final file = 'words_$languageCode.json';
  return [
    for (final base in [primary, iran, fallback, mirror])
      if (base.isNotEmpty)
        Uri.parse(base).path.endsWith('.php')
            ? Uri.parse(base)
                  .replace(queryParameters: {'file': file})
                  .toString()
            : Uri.parse(base).resolve(file).toString(),
  ];
}

/// A word pack that passed validation.
class WordPack {
  const WordPack(this.version, this.categories, this.raw);

  final int version;
  final List<WordCategory> categories;
  final String raw;

  int get wordCount => categories.fold(0, (n, c) => n + c.totalWords);

  /// Parses and checks [raw]. Returns null for anything that is not a sane
  /// pack in [languageCode]: a broken or nearly empty download never
  /// replaces the words the app already has.
  static WordPack? tryParse(String? raw, String languageCode) {
    if (raw == null || raw.length > 2 * 1024 * 1024) return null;
    try {
      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic>) return null;
      final version = json['version'];
      if (version is! int || version < 1) return null;
      if (json['language'] != languageCode) return null;
      final pack = WordPack(version, parseWordPack(raw), raw);
      if (pack.categories.length < 3 || pack.wordCount < 100) return null;
      return pack;
    } catch (_) {
      return null;
    }
  }
}

/// Bundled word packs, replaced by a newer downloaded pack when there is
/// one. Everything works offline: downloads only happen in [refresh], in
/// the background, and the result is used from the next game on.
class UpdatableWordRepository implements WordRepository {
  UpdatableWordRepository({
    required this._prefs,
    AssetBundle? bundle,
    http.Client? client,
    List<String> Function(String languageCode)? urls,
    this.timeout = const Duration(seconds: 6),
    this.minRefreshInterval = const Duration(hours: 6),
    DateTime Function()? now,
  }) : _bundle = bundle ?? rootBundle,
       _client = client ?? http.Client(),
       _urls = urls ?? wordPackUrls,
       _now = now ?? DateTime.now;

  final SharedPreferences _prefs;
  final AssetBundle _bundle;
  final http.Client _client;
  final List<String> Function(String languageCode) _urls;
  final Duration timeout;
  final Duration minRefreshInterval;
  final DateTime Function() _now;
  final Map<String, WordPack> _packs = {};

  static String _kPack(String lang) => 'words.remote.$lang';
  static String _kFetchedAt(String lang) => 'words.fetched_at.$lang';

  @override
  Future<List<WordCategory>> loadCategories(String languageCode) async =>
      (await _pack(languageCode)).categories;

  /// Version of the pack in use (bundled or downloaded).
  Future<int> versionOf(String languageCode) async =>
      (await _pack(languageCode)).version;

  Future<WordPack> _pack(String lang) async {
    final cached = _packs[lang];
    if (cached != null) return cached;
    var bundled = await _bundled(lang);
    if (bundled == null && lang != 'fa') {
      lang = 'fa';
      bundled = await _bundled(lang);
    }
    final downloaded = WordPack.tryParse(_prefs.getString(_kPack(lang)), lang);
    final best =
        downloaded != null &&
            (bundled == null || downloaded.version > bundled.version)
        ? downloaded
        : bundled;
    if (best == null) throw StateError('no word pack for $lang');
    return _packs[lang] = best;
  }

  Future<WordPack?> _bundled(String lang) async {
    try {
      final raw = await _bundle.loadString('assets/words/words_$lang.json');
      return WordPack.tryParse(raw, lang) ??
          // A small bundled pack (e.g. English) is still better than none.
          WordPack(1, parseWordPack(raw), raw);
    } catch (_) {
      return null;
    }
  }

  /// Downloads a newer pack (primary, then mirror). Returns true when one
  /// was stored; it is used by games started after that.
  Future<bool> refresh(String languageCode, {bool force = false}) async {
    final last = _prefs.getInt(_kFetchedAt(languageCode));
    if (!force &&
        last != null &&
        _now().difference(DateTime.fromMillisecondsSinceEpoch(last)) <
            minRefreshInterval) {
      return false;
    }
    final current = await _pack(languageCode);
    for (final url in _urls(languageCode)) {
      try {
        final res = await _client.get(Uri.parse(url)).timeout(timeout);
        if (res.statusCode != 200) continue;
        final pack = WordPack.tryParse(
          utf8.decode(res.bodyBytes),
          languageCode,
        );
        if (pack == null) {
          debugPrint('word pack from $url rejected');
          continue;
        }
        _prefs.setInt(_kFetchedAt(languageCode), _now().millisecondsSinceEpoch);
        if (pack.version <= current.version) return false;
        await _prefs.setString(_kPack(languageCode), pack.raw);
        _packs[languageCode] = pack;
        return true;
      } catch (e) {
        debugPrint('word pack $url: $e');
      }
    }
    return false;
  }
}

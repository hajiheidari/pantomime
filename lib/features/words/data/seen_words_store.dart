import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Persists which words were already shown, per category, across games.
class SeenWordsStore {
  SeenWordsStore(this._prefs);

  final SharedPreferences _prefs;

  String _key(String languageCode) => 'seen_words_$languageCode';

  Map<String, Set<String>> load(String languageCode) {
    final raw = _prefs.getString(_key(languageCode));
    if (raw == null) return {};
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return {
        for (final e in json.entries)
          e.key: {for (final w in (e.value as List)) w as String},
      };
    } catch (_) {
      return {};
    }
  }

  Future<void> save(String languageCode, Map<String, Set<String>> seen) =>
      _prefs.setString(
        _key(languageCode),
        jsonEncode({for (final e in seen.entries) e.key: e.value.toList()}),
      );
}

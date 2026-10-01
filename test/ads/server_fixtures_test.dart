import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pantomime/features/ads/config/remote_config.dart';

/// Configs produced by the Telegram bot (server/scripts/write-fixtures.js)
/// must be accepted by the app, and the invalid ones rejected, so the bot can
/// never publish a config the app would ignore.
void main() {
  List<File> files(String kind) =>
      Directory('server/test/fixtures/$kind')
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .toList();

  test('bot-produced configs are accepted by the app', () {
    final valid = files('valid');
    expect(valid, isNotEmpty);
    for (final f in valid) {
      expect(
        () => RemoteConfig.parse(jsonDecode(f.readAsStringSync())),
        returnsNormally,
        reason: f.path,
      );
    }
  });

  test('configs the bot rejects are rejected by the app too', () {
    final invalid = files('invalid');
    expect(invalid, isNotEmpty);
    for (final f in invalid) {
      expect(
        RemoteConfig.tryParse(jsonDecode(f.readAsStringSync())),
        isNull,
        reason: f.path,
      );
    }
  });
}

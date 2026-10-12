import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/providers.dart';
import '../words/words_providers.dart';
import 'share_link.dart';

/// Invite links: every shared link carries this install's code (i=CODE).
/// The web game (or the app page) reports a friend's visit to the server (Cloudflare
/// Worker, server/src/invite.js, or its copy on the Iranian host), and once
/// a friend opens the link the special categories open for 24 hours (like
/// sharing itself or a rewarded ad, see [bonusUnlockProvider]).
const inviteEndpoints = ['https://api.espadna.com', 'https://espadna.ir/api'];

class InviteService {
  InviteService(this._prefs, {http.Client? client, List<String>? endpoints})
    : _client = client ?? http.Client(),
      _endpoints = endpoints ?? inviteEndpoints;

  final SharedPreferences _prefs;
  final http.Client _client;
  final List<String> _endpoints;

  static const _codeKey = 'invite_code';
  static const _seenKey = 'invite_seen_visits';
  static final _valid = RegExp(r'^[A-Z2-9]{6,12}$');
  static const _alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  /// This install's code (made once, then kept).
  String get code {
    final saved = _prefs.getString(_codeKey);
    if (saved != null && _valid.hasMatch(saved)) return saved;
    final rnd = Random.secure();
    final fresh = String.fromCharCodes(
      List.generate(8, (_) => _alphabet.codeUnitAt(rnd.nextInt(32))),
    );
    unawaited(_prefs.setString(_codeKey, fresh));
    return fresh;
  }

  /// Asks the servers whether a friend opened the link since the last check
  /// (true once per new visit). Also registers this device as the owner, so
  /// opening your own link never counts.
  Future<bool> check() async {
    final c = code;
    final counts = await Future.wait(_endpoints.map((e) => _visits(e, c)));
    final total = counts.fold(0, (a, b) => a + b);
    final seen = _prefs.getInt(_seenKey) ?? 0;
    if (total > seen) {
      await _prefs.setInt(_seenKey, total);
      return true;
    }
    return false;
  }

  Future<int> _visits(String endpoint, String code) async {
    try {
      final res = await _client
          .get(Uri.parse('$endpoint/invite/$code'))
          .timeout(const Duration(seconds: 6));
      if (res.statusCode != 200) return 0;
      final v = (jsonDecode(res.body) as Map)['visits'];
      return v is int ? v : 0;
    } catch (e) {
      debugPrint('invite check $endpoint: $e');
      return 0;
    }
  }
}

/// Web game opened from someone's invite link (?i=CODE): count the visit.
/// Link-preview bots don't run the game, so only real visits count.
Future<void> reportInviteVisit({http.Client? client}) async {
  if (!kIsWeb) return;
  final code = Uri.base.queryParameters['i'];
  if (code == null || !InviteService._valid.hasMatch(code)) return;
  final api = Uri.base.host.endsWith('espadna.ir')
      ? inviteEndpoints[1]
      : inviteEndpoints[0];
  try {
    await (client ?? http.Client())
        .post(Uri.parse('$api/invite/$code'))
        .timeout(const Duration(seconds: 8));
  } catch (e) {
    debugPrint('invite visit: $e');
  }
}

final inviteServiceProvider = Provider<InviteService>((ref) {
  final service = InviteService(ref.watch(sharedPreferencesProvider));
  inviteCode = service.code;
  return service;
});

/// A friend opened the invite link since the last check: the special
/// categories open for another 24 hours. Returns true when that happened.
Future<bool> checkInviteVisits(InviteService invites, BonusUnlock bonus) async {
  if (!await invites.check()) return false;
  bonus.openForADay();
  return true;
}

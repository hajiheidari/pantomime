import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/providers.dart';

/// Game Center (iOS only; a no-op everywhere else). Leaderboards and
/// achievements are defined in App Store Connect under these ids; the
/// native side is `GameCenter` in ios/Runner/AppDelegate.swift.
///
/// Totals are kept on the phone and submitted as the player's score, so the
/// "most turns" and "most words" boards grow with every game.
class GameCenter {
  GameCenter(this._prefs, {bool? enabled})
    : enabled =
          enabled ?? (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS);

  static const _channel = MethodChannel('pantomime/gamecenter');
  static const _p = 'com.espadna.pantomime.';
  static const turnsBoard = '${_p}turns_played';
  static const wordsBoard = '${_p}words_guessed';
  static const bestTurnBoard = '${_p}best_turn';

  final SharedPreferences _prefs;
  final bool enabled;

  int _get(String k) => _prefs.getInt('gc.$k') ?? 0;
  Future<void> _set(String k, int v) => _prefs.setInt('gc.$k', v);

  int get turns => _get('turns');
  int get words => _get('words');
  int get games => _get('games');
  int get bestTurn => _get('best_turn');

  Future<void> _call(String method, [Map<String, Object>? args]) async {
    if (!enabled) return;
    try {
      await _channel.invokeMethod<void>(method, args);
    } catch (e) {
      debugPrint('game center $method: $e');
    }
  }

  /// Shows the Game Center sign-in the first time (iOS decides when).
  Future<void> signIn() => _call('signIn');

  /// Opens the Game Center dashboard (leaderboards and achievements).
  Future<void> show() => _call('show');

  Future<void> _unlock(String id) => _call('unlock', {'id': '$_p$id'});
  Future<void> _submit(String board, int score) =>
      _call('submit', {'id': board, 'score': score});

  /// A turn ended with [correct] guessed words; [speed]: speed mode (only
  /// those count for the best-turn board).
  Future<void> turnEnded({required int correct, required bool speed}) async {
    final t = turns + 1;
    final w = words + correct;
    await _set('turns', t);
    await _set('words', w);
    await _submit(turnsBoard, t);
    if (correct > 0) await _submit(wordsBoard, w);
    if (speed && correct > bestTurn) {
      await _set('best_turn', correct);
      await _submit(bestTurnBoard, correct);
    }
    if (w >= 100) await _unlock('words_100');
    if (w >= 1000) await _unlock('words_1000');
    if (speed && correct >= 10) await _unlock('turn_10');
  }

  Future<void> gameFinished() async {
    final g = games + 1;
    await _set('games', g);
    await _unlock('first_game');
    if (g >= 10) await _unlock('games_10');
    if (g >= 50) await _unlock('games_50');
  }
}

final gameCenterProvider = Provider<GameCenter>(
  (ref) => GameCenter(ref.watch(sharedPreferencesProvider)),
);

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../settings/settings_controller.dart';
import 'sound_service.dart';

/// Sound + haptic cues for game events. Respects the user's settings
/// (global mute / vibration toggles).
class FeedbackService {
  FeedbackService(this._settings, this._sounds);

  final AppSettings Function() _settings;
  final SoundService _sounds;

  bool get _vibrate => _settings().vibrationOn;

  void _play(GameSound s) {
    if (_settings().soundOn) _sounds.play(s);
  }

  void correct() {
    _play(GameSound.correct);
    if (_vibrate) HapticFeedback.mediumImpact();
  }

  void pass() {
    _play(GameSound.pass);
    if (_vibrate) HapticFeedback.lightImpact();
  }

  /// Every second during the last 10 seconds.
  void tick() {
    _play(GameSound.tick);
    if (_vibrate) HapticFeedback.selectionClick();
  }

  void countdown() {
    _play(GameSound.count);
    if (_vibrate) HapticFeedback.lightImpact();
  }

  void go() {
    _play(GameSound.go);
    if (_vibrate) HapticFeedback.mediumImpact();
  }

  void roundEnd() {
    _play(GameSound.roundEnd);
    if (_vibrate) HapticFeedback.heavyImpact();
  }

  void win() => _play(GameSound.win);
}

/// Overridden in tests with [SilentSoundService].
final soundServiceProvider = Provider<SoundService>(
  (ref) => AudioPoolSoundService()..preload(),
);

final feedbackProvider = Provider<FeedbackService>(
  (ref) => FeedbackService(
    () => ref.read(settingsProvider),
    ref.watch(soundServiceProvider),
  ),
);

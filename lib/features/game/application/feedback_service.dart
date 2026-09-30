import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../settings/settings_controller.dart';

/// Sound + haptic cues for game events. Respects the user's settings.
///
/// M1 ships haptics only; sounds are wired in M2 behind the same methods.
class FeedbackService {
  FeedbackService(this._settings);

  final AppSettings Function() _settings;

  bool get _vibrate => _settings().vibrationOn;

  void correct() {
    if (_vibrate) HapticFeedback.mediumImpact();
  }

  void pass() {
    if (_vibrate) HapticFeedback.lightImpact();
  }

  /// Every second during the last 10 seconds.
  void tick() {
    if (_vibrate) HapticFeedback.selectionClick();
  }

  void countdown() {
    if (_vibrate) HapticFeedback.lightImpact();
  }

  void roundEnd() {
    if (_vibrate) HapticFeedback.heavyImpact();
  }
}

final feedbackProvider = Provider<FeedbackService>(
  (ref) => FeedbackService(() => ref.read(settingsProvider)),
);

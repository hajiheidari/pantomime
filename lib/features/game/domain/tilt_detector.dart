import 'dart:math' as math;

/// Tilt gestures in forehead mode.
enum TiltAction {
  /// Head nods forward, screen faces the floor → correct.
  down,

  /// Head tips back, screen faces the ceiling → pass.
  up,
}

/// Pitch of the screen in degrees from an accelerometer sample (gravity
/// included, m/s²): 0 = screen vertical, -90 = facing the floor,
/// +90 = facing the ceiling. Independent of landscape-left/right.
double pitchDegrees(double x, double y, double z) =>
    math.atan2(z, math.sqrt(x * x + y * y)) * 180 / math.pi;

/// Turns a stream of accelerometer samples into [TiltAction]s.
///
/// - Samples are low-pass filtered to ignore hand jitter.
/// - An action fires when the pitch (relative to the calibrated [baseline])
///   passes ±[triggerDegrees].
/// - After an action the detector is disarmed until the phone has been back
///   in the neutral zone (±[neutralDegrees]) for [neutralHold], and at least
///   [cooldown] has passed. This prevents one nod from counting twice.
///
/// Pure Dart; timestamps are passed in so it is deterministic in tests.
class TiltDetector {
  TiltDetector({
    this.triggerDegrees = 40,
    this.neutralDegrees = 20,
    this.neutralHold = const Duration(milliseconds: 250),
    this.cooldown = const Duration(milliseconds: 700),
    this.smoothing = 0.35,
    this.baseline = 0,
  });

  final double triggerDegrees;
  final double neutralDegrees;
  final Duration neutralHold;
  final Duration cooldown;

  /// Weight of the newest sample in the low-pass filter (0..1].
  final double smoothing;

  /// Pitch considered "neutral" (set by calibration).
  double baseline;

  double? _filtered;
  bool _armed = true;
  Duration? _neutralSince;
  Duration? _lastAction;

  /// Current filtered pitch relative to [baseline].
  double get relativePitch => (_filtered ?? baseline) - baseline;

  bool get isArmed => _armed;

  void reset() {
    _filtered = null;
    _armed = true;
    _neutralSince = null;
    _lastAction = null;
  }

  /// Feeds one sample; returns an action when a gesture completes.
  TiltAction? add(double x, double y, double z, Duration timestamp) =>
      addPitch(pitchDegrees(x, y, z), timestamp);

  TiltAction? addPitch(double pitch, Duration timestamp) {
    final f = _filtered;
    _filtered = f == null ? pitch : f + smoothing * (pitch - f);
    final rel = relativePitch;

    if (!_armed) {
      final cooled =
          _lastAction == null || timestamp - _lastAction! >= cooldown;
      if (rel.abs() <= neutralDegrees) {
        _neutralSince ??= timestamp;
        if (cooled && timestamp - _neutralSince! >= neutralHold) {
          _armed = true;
        }
      } else {
        _neutralSince = null;
      }
      return null;
    }

    TiltAction? action;
    if (rel <= -triggerDegrees) action = TiltAction.down;
    if (rel >= triggerDegrees) action = TiltAction.up;
    if (action != null) {
      _armed = false;
      _neutralSince = null;
      _lastAction = timestamp;
    }
    return action;
  }
}

/// Detects that the phone is held still, roughly upright, on the forehead,
/// and reports the pitch to use as the neutral baseline.
class CalibrationTracker {
  CalibrationTracker({
    this.maxUprightDegrees = 35,
    this.stableDegrees = 8,
    this.hold = const Duration(milliseconds: 900),
  });

  /// |pitch| must be below this to count as "on the forehead".
  final double maxUprightDegrees;

  /// Allowed wobble while holding still.
  final double stableDegrees;
  final Duration hold;

  Duration? _since;
  double _anchor = 0;
  double _sum = 0;
  int _count = 0;

  /// 0..1 progress towards a successful calibration.
  double progress = 0;

  void reset() {
    _since = null;
    _sum = 0;
    _count = 0;
    progress = 0;
  }

  /// Returns the baseline pitch once calibrated, otherwise `null`.
  double? add(double x, double y, double z, Duration timestamp) =>
      addPitch(pitchDegrees(x, y, z), timestamp);

  double? addPitch(double pitch, Duration timestamp) {
    final upright = pitch.abs() <= maxUprightDegrees;
    if (!upright ||
        (_since != null && (pitch - _anchor).abs() > stableDegrees)) {
      reset();
      if (!upright) return null;
    }
    if (_since == null) {
      _since = timestamp;
      _anchor = pitch;
    }
    _sum += pitch;
    _count++;
    final held = timestamp - _since!;
    progress = (held.inMicroseconds / hold.inMicroseconds).clamp(0, 1);
    return held >= hold ? _sum / _count : null;
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'motion/motion_platform_stub.dart'
    if (dart.library.js_interop) 'motion/motion_platform_web.dart'
    as platform;

/// Asks for motion-sensor access where the platform needs it (iPhone
/// Safari). Call it from a button tap, before forehead calibration.
Future<bool> requestMotionPermission() => platform.requestMotionPermission();

/// One accelerometer sample (gravity included, m/s²) with a monotonic
/// timestamp.
class MotionSample {
  const MotionSample(this.x, this.y, this.z, this.time);

  final double x;
  final double y;
  final double z;
  final Duration time;
}

/// Accelerometer stream used by forehead mode. Overridden in tests.
final accelerometerProvider = Provider<Stream<MotionSample>>((ref) {
  final web = platform.platformMotionStream();
  if (web != null) return web;
  final clock = Stopwatch()..start();
  return accelerometerEventStream(samplingPeriod: SensorInterval.gameInterval)
      .map((e) => MotionSample(e.x, e.y, e.z, clock.elapsed));
});

/// Browsers: `accelerationIncludingGravity` should point "up" (spec), but
/// some (iOS Safari) report it inverted. While the phone is clearly upright,
/// gravity lies along one screen axis whose sign the screen rotation
/// ([screenAngle]: 0, 90, 180, 270) tells us. Returns +1 if the readings
/// follow the spec, -1 if inverted, null while unsure.
double? gravitySign(int screenAngle, double x, double y) {
  const upright = 7.0; // m/s²
  final double? axis = switch (screenAngle) {
    0 => y, // portrait: the device top is up → +y
    180 => -y,
    90 => x, // landscape, device top to the left → +x is up
    270 => -x,
    _ => null,
  };
  if (axis == null || axis.abs() < upright) return null;
  return axis > 0 ? 1 : -1;
}

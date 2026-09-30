import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensors_plus/sensors_plus.dart';

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
  final clock = Stopwatch()..start();
  return accelerometerEventStream(samplingPeriod: SensorInterval.gameInterval)
      .map((e) => MotionSample(e.x, e.y, e.z, clock.elapsed));
});

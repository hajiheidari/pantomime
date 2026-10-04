import '../motion.dart';

/// Native builds read the sensors through sensors_plus (see motion.dart).
Stream<MotionSample>? platformMotionStream() => null;

/// Native builds need no runtime permission for the accelerometer.
Future<bool> requestMotionPermission() async => true;

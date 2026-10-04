import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

import '../motion.dart';

/// Browsers: `devicemotion` events (works on iPhone Safari and Android
/// Chrome; sensors_plus uses the Generic Sensor API, which Safari lacks).
///
/// `accelerationIncludingGravity` should point "up" (spec), but iOS reports
/// it inverted. The sign is checked against the screen orientation while the
/// phone is held upright (calibration), with a user-agent guess before that.
Stream<MotionSample>? platformMotionStream() {
  late final StreamController<MotionSample> controller;
  var sign = _looksLikeIos() ? -1.0 : 1.0;
  var signChecked = false;

  void onMotion(web.Event event) {
    final e = event as web.DeviceMotionEvent;
    final a = e.accelerationIncludingGravity;
    final x = a?.x?.toDouble();
    final y = a?.y?.toDouble();
    final z = a?.z?.toDouble();
    if (x == null || y == null || z == null) return;
    if (!signChecked) {
      final expected = gravitySign(_screenAngle(), x, y);
      if (expected != null) {
        sign = expected;
        signChecked = true;
      }
    }
    controller.add(
      MotionSample(
        sign * x,
        sign * y,
        sign * z,
        Duration(microseconds: (e.timeStamp * 1000).round()),
      ),
    );
  }

  final listener = onMotion.toJS;
  controller = StreamController<MotionSample>.broadcast(
    onListen: () => web.window.addEventListener('devicemotion', listener),
    onCancel: () => web.window.removeEventListener('devicemotion', listener),
  );
  return controller.stream;
}

/// iPhone / iPad Safari (iPadOS reports itself as a Mac with touch).
bool _looksLikeIos() {
  final nav = web.window.navigator;
  final ua = nav.userAgent;
  return RegExp('iPhone|iPad|iPod').hasMatch(ua) ||
      (ua.contains('Macintosh') && nav.maxTouchPoints > 1);
}

/// Screen rotation in degrees (0, 90, 180, 270).
int _screenAngle() {
  try {
    return web.window.screen.orientation.angle;
  } catch (_) {
    // Older iOS: window.orientation (0, 90, -90, 180).
    final o = (web.window as JSObject).getProperty<JSNumber?>(
      'orientation'.toJS,
    );
    return ((o?.toDartInt ?? 0) + 360) % 360;
  }
}

/// iOS 13+: motion data needs a permission prompt, which must be started
/// from a tap. Elsewhere it resolves immediately.
Future<bool> requestMotionPermission() async {
  try {
    final ctor = web.window.getProperty<JSObject?>('DeviceMotionEvent'.toJS);
    if (ctor == null || !ctor.has('requestPermission')) return true;
    final result = await ctor
        .callMethod<JSPromise<JSString>>('requestPermission'.toJS)
        .toDart;
    return result.toDart == 'granted';
  } catch (_) {
    return false;
  }
}

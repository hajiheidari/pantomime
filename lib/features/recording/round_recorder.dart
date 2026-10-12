import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Records a round: the front camera in forehead mode, the back camera in
/// the pantomime modes (whoever holds the phone films the actor).
/// Videos stay on the device; nothing is ever uploaded.
abstract interface class RoundRecorder {
  /// Opens the camera (asks for camera + microphone permission the first
  /// time). Returns false if permission is denied or no camera exists.
  Future<bool> prepare();

  Future<void> start();

  /// Stops and returns the video file path, or null.
  Future<String?> stop();

  /// Releases the camera. [prepare] may be called again afterwards.
  Future<void> dispose();

  bool get isRecording;
}

class CameraRoundRecorder implements RoundRecorder {
  CameraRoundRecorder({this.back = false});

  /// Back camera instead of the front one.
  final bool back;

  CameraController? _controller;
  bool _recording = false;

  @override
  bool get isRecording => _recording;

  @override
  Future<bool> prepare() async {
    if (_controller?.value.isInitialized ?? false) return true;
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return false;
      final want = back ? CameraLensDirection.back : CameraLensDirection.front;
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == want,
        orElse: () => cameras.first,
      );
      final c = CameraController(camera, ResolutionPreset.medium);
      await c.initialize();
      await c.prepareForVideoRecording();
      _controller = c;
      return true;
    } on CameraException catch (e) {
      debugPrint('camera: ${e.code} ${e.description}');
      return false;
    } catch (e) {
      debugPrint('camera: $e');
      return false;
    }
  }

  @override
  Future<void> start() async {
    final c = _controller;
    if (c == null || _recording) return;
    try {
      await c.startVideoRecording();
      _recording = true;
    } catch (e) {
      debugPrint('camera start: $e');
    }
  }

  @override
  Future<String?> stop() async {
    final c = _controller;
    if (c == null || !_recording) return null;
    _recording = false;
    try {
      return (await c.stopVideoRecording()).path;
    } catch (e) {
      debugPrint('camera stop: $e');
      return null;
    }
  }

  @override
  Future<void> dispose() async {
    if (_recording) await stop();
    final c = _controller;
    _controller = null;
    await c?.dispose();
  }
}

/// A fresh recorder per game screen. Overridden in tests.
final roundRecorderFactoryProvider = Provider<RoundRecorder Function()>(
  (ref) => CameraRoundRecorder.new,
);

/// Back-camera recorder for the pantomime modes. Overridden in tests.
final backRecorderFactoryProvider = Provider<RoundRecorder Function()>(
  (ref) =>
      () => CameraRoundRecorder(back: true),
);

/// Video of each finished turn (turn index → file path) in the current game.
final roundClipsProvider = NotifierProvider<RoundClips, Map<int, String>>(
  RoundClips.new,
);

class RoundClips extends Notifier<Map<int, String>> {
  @override
  Map<int, String> build() => const {};

  void add(int turn, String path) => state = {...state, turn: path};

  void clear() => state = const {};
}

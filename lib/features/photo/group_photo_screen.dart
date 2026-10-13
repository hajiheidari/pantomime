import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/cartoon.dart';
import '../share/share_link.dart';
import 'photo_date.dart';
import 'photo_frames.dart';

/// Everyone together before the first turn: a selfie with the front camera
/// (3-2-1), then a frame, the date and a line of their own, saved or shared.
/// The photo stays on the phone unless they save or share it.
class GroupPhotoScreen extends ConsumerStatefulWidget {
  const GroupPhotoScreen({super.key, required this.names});

  /// Team / player names of this game.
  final List<String> names;

  @override
  ConsumerState<GroupPhotoScreen> createState() => _GroupPhotoScreenState();
}

class _GroupPhotoScreenState extends ConsumerState<GroupPhotoScreen> {
  CameraController? _camera;
  List<CameraDescription> _cameras = const [];
  bool _front = true;
  bool _failed = false;
  int? _countdown;

  Uint8List? _photo;
  PhotoFrame _frame = PhotoFrame.cartoon;
  final _caption = TextEditingController();
  final _key = GlobalKey();
  bool _busy = false;

  AppStrings get _s => ref.read(stringsProvider);

  @override
  void initState() {
    super.initState();
    _caption.text = _s.defaultCaption;
    _open();
  }

  Future<void> _open() async {
    try {
      _cameras = await availableCameras();
      final want = _front
          ? CameraLensDirection.front
          : CameraLensDirection.back;
      final cam = _cameras.firstWhere(
        (c) => c.lensDirection == want,
        orElse: () => _cameras.first,
      );
      final c = CameraController(
        cam,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await c.initialize();
      if (!mounted) {
        await c.dispose();
        return;
      }
      final old = _camera;
      setState(() => _camera = c);
      await old?.dispose();
    } catch (e) {
      debugPrint('group photo camera: $e');
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _shoot() async {
    for (var i = 3; i > 0; i--) {
      if (!mounted) return;
      setState(() => _countdown = i);
      await Future<void>.delayed(const Duration(seconds: 1));
    }
    if (!mounted) return;
    setState(() => _countdown = null);
    try {
      final file = await _camera!.takePicture();
      final bytes = await file.readAsBytes();
      if (mounted) setState(() => _photo = bytes);
      await _camera?.dispose();
      _camera = null;
    } catch (e) {
      debugPrint('group photo: $e');
    }
  }

  Future<void> _retake() async {
    setState(() => _photo = null);
    await _open();
  }

  Future<Uint8List?> _render() async {
    final boundary =
        _key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 1);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data?.buffer.asUint8List();
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      final png = await _render();
      if (png == null) return;
      if (!await Gal.hasAccess() && !await Gal.requestAccess()) return;
      await Gal.putImageBytes(png, album: 'Pantomime');
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_s.photoSaved)));
      }
    } catch (e) {
      debugPrint('save photo: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _share() async {
    setState(() => _busy = true);
    try {
      final png = await _render();
      if (png == null) return;
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/pantomime_group.png');
      await file.writeAsBytes(png);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'image/png')],
          text: withShareLink(_caption.text, _s.languageCode),
        ),
      );
    } catch (e) {
      debugPrint('share photo: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _camera?.dispose();
    _caption.dispose();
    super.dispose();
  }

  Widget _frameView(PhotoFrame f, {Key? key}) {
    final s = ref.watch(stringsProvider);
    final now = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    final (jy, jm, jd) = toJalali(now);
    final stamp = s.languageCode == 'fa'
        ? "'${two(jy % 100)} ${two(jm)} ${two(jd)}"
        : "'${two(now.year % 100)} ${two(now.month)} ${two(now.day)}";
    return RepaintBoundary(
      key: key,
      child: PhotoFrameView(
        frame: f,
        photo: _photo == null ? null : MemoryImage(_photo!),
        caption: _caption.text,
        names: widget.names.join(s.isRtl ? '، ' : ', '),
        date: photoDate(s, now),
        stamp: stamp,
        s: s,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(s.groupPhotoTitle)),
      body: DecoratedBox(
        decoration: appBackground,
        child: SafeArea(
          top: false,
          child: _photo == null ? _cameraView(s) : _editor(s),
        ),
      ),
    );
  }

  Widget _cameraView(AppStrings s) {
    final c = _camera;
    if (_failed) {
      return Center(
        child: Text(s.noCamera, style: const TextStyle(fontSize: 18)),
      );
    }
    if (c == null || !c.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: AspectRatio(
                    aspectRatio: 1 / c.value.aspectRatio,
                    child: CameraPreview(c),
                  ),
                ),
                if (_countdown != null)
                  PopIn(
                    key: ValueKey(_countdown),
                    child: Text(
                      s.n(_countdown!),
                      style: const TextStyle(
                        fontSize: 160,
                        fontWeight: FontWeight.w900,
                        color: AppColors.yellow,
                        shadows: [
                          Shadow(
                            color: AppColors.outline,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Row(
            children: [
              if (_cameras.length > 1)
                IconButton(
                  iconSize: 36,
                  icon: const Icon(Icons.flip_camera_ios_rounded),
                  onPressed: _countdown != null
                      ? null
                      : () {
                          _front = !_front;
                          _open();
                        },
                ),
              const SizedBox(width: 12),
              Expanded(
                child: CartoonButton(
                  label: s.groupPhotoYes,
                  icon: '📸',
                  color: AppColors.yellow,
                  onPressed: _countdown != null ? null : _shoot,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _editor(AppStrings s) => ListView(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
    children: [
      Center(
        child: SizedBox(
          height: 420,
          child: FittedBox(child: _frameView(_frame, key: _key)),
        ),
      ),
      const SizedBox(height: 12),
      SizedBox(
        height: 120,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            for (final f in PhotoFrame.values)
              GestureDetector(
                onTap: () => setState(() => _frame = f),
                child: Container(
                  width: 88,
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: f == _frame
                          ? AppColors.yellow
                          : Colors.transparent,
                      width: 4,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: FittedBox(child: _frameView(f)),
                  ),
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _caption,
        maxLength: 60,
        onChanged: (_) => setState(() {}),
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: AppColors.ink,
        ),
        decoration: InputDecoration(
          hintText: s.captionHint,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            child: CartoonButton(
              label: s.savePhoto,
              icon: '💾',
              stacked: true,
              height: 76,
              fontSize: 16,
              color: AppColors.card,
              onPressed: _busy ? null : _save,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: CartoonButton(
              label: s.share,
              icon: '📤',
              stacked: true,
              height: 76,
              fontSize: 16,
              color: AppColors.pink,
              onPressed: _busy ? null : _share,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: CartoonButton(
              label: s.retake,
              icon: '🔄',
              stacked: true,
              height: 76,
              fontSize: 16,
              color: AppColors.orange,
              onPressed: _busy ? null : _retake,
            ),
          ),
        ],
      ),
    ],
  );
}

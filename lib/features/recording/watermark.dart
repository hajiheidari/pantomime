import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../share/share_link.dart';

/// Burns a watermark (game name, score, site address) into a recorded clip
/// before it is saved or shared. Native side: AVFoundation (ios/Runner/
/// Watermark.swift) and Media3 Transformer (android/…/Watermark.kt).
///
/// Never fails: if anything goes wrong the original clip is returned, so
/// saving and sharing always work.
const _channel = MethodChannel('pantomime/watermark');

final _cache = <String, Future<String>>{};

/// Watermarked copy of [clip] for this [score] (computed once, cached).
Future<String> watermarkedClip(
  String clip, {
  required AppStrings s,
  required int score,
}) => _cache.putIfAbsent('$clip#$score', () => _apply(clip, s, score));

/// True when [watermarkedClip] for these arguments has already finished.
bool watermarkReady(String clip, int score) => _done.contains('$clip#$score');

final _done = <String>{};

Future<String> _apply(String clip, AppStrings s, int score) async {
  var result = clip;
  if (!kIsWeb) {
    try {
      final png = await renderWatermark(
        title: '🎭 ${s.appName}  |  ${s.score(score)}',
        link: shareLinkLabel(s.languageCode),
        rtl: s.isRtl,
      );
      final dot = clip.lastIndexOf('.');
      final out = '${dot > 0 ? clip.substring(0, dot) : clip}_wm$score.mp4';
      final path = await _channel
          .invokeMethod<String>('apply', {
            'input': clip,
            'output': out,
            'overlay': png,
          })
          .timeout(const Duration(seconds: 120));
      if (path != null && File(path).existsSync()) result = path;
    } catch (e) {
      debugPrint('watermark: $e (sharing the clip without it)');
    }
  }
  _done.add('$clip#$score');
  return result;
}

/// The watermark as a transparent PNG: a dark rounded label with the game
/// name and score on the first line and the site address on the second.
Future<Uint8List> renderWatermark({
  required String title,
  required String link,
  required bool rtl,
}) async {
  const width = 1000.0;
  const pad = 34.0;
  ui.Paragraph line(String text, double size, Color color, TextDirection d) {
    final b =
        ui.ParagraphBuilder(
            ui.ParagraphStyle(
              textAlign: TextAlign.center,
              textDirection: d,
              maxLines: 1,
              ellipsis: '…',
            ),
          )
          ..pushStyle(
            ui.TextStyle(
              color: color,
              fontSize: size,
              fontFamily: appFontFamily,
              fontWeight: FontWeight.w900,
            ),
          )
          ..addText(text);
    return b.build()
      ..layout(const ui.ParagraphConstraints(width: width - 2 * pad));
  }

  final top = line(
    title,
    66,
    AppColors.yellow,
    rtl ? TextDirection.rtl : TextDirection.ltr,
  );
  final bottom = line(link, 46, const Color(0xFFFFFFFF), TextDirection.ltr);
  final height = (pad + top.height + 6 + bottom.height + pad).ceilToDouble();

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final box = RRect.fromRectAndRadius(
    Rect.fromLTWH(3, 3, width - 6, height - 6),
    const Radius.circular(44),
  );
  canvas
    ..drawRRect(box, Paint()..color = const Color(0xC0140F2E))
    ..drawRRect(
      box,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..color = AppColors.yellow,
    )
    ..drawParagraph(top, const Offset(pad, pad))
    ..drawParagraph(bottom, Offset(pad, pad + top.height + 6));
  final image = await recorder.endRecording().toImage(
    width.toInt(),
    height.toInt(),
  );
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}

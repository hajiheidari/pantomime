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
        name: s.appName,
        detail: shareLinkLabel(s.languageCode),
        rtl: s.isRtl,
        logo: await _logo(),
      );
      final dot = clip.lastIndexOf('.');
      final out = '${dot > 0 ? clip.substring(0, dot) : clip}_wm$score.mp4';
      final path = await _channel
          .invokeMethod<String>('apply', {
            'input': clip,
            'output': out,
            'overlay': png,
            'left': !s.isRtl,
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

Future<Uint8List?> _logo() async {
  try {
    final d = await rootBundle.load(watermarkLogoAsset);
    return d.buffer.asUint8List(d.offsetInBytes, d.lengthInBytes);
  } catch (_) {
    return null;
  }
}

const watermarkLogoAsset = 'assets/branding/icon_512.png';

/// The watermark as a transparent PNG: the app icon next to the game name
/// (yellow, outlined so it reads on any background) and the site address
/// under it. No backing box; it hugs the bottom-right corner (RTL) or the
/// bottom-left one (LTR).
Future<Uint8List> renderWatermark({
  required String name,
  required String detail,
  required bool rtl,
  Uint8List? logo,
}) async {
  const width = 1000.0;
  const height = 230.0;
  const logoSize = 210.0;
  const gap = 26.0;
  final dir = rtl ? TextDirection.rtl : TextDirection.ltr;
  const textWidth = width - logoSize - gap - 10;

  ui.Paragraph line(
    String text,
    double size,
    Paint paint,
    List<Shadow> sh, {
    TextDirection? d,
  }) {
    final b =
        ui.ParagraphBuilder(
            ui.ParagraphStyle(
              textAlign: rtl ? TextAlign.right : TextAlign.left,
              textDirection: d ?? dir,
              maxLines: 1,
              ellipsis: '…',
            ),
          )
          ..pushStyle(
            ui.TextStyle(
              foreground: paint,
              fontSize: size,
              fontFamily: appFontFamily,
              fontWeight: FontWeight.w900,
              shadows: sh,
            ),
          )
          ..addText(text);
    return b.build()..layout(const ui.ParagraphConstraints(width: textWidth));
  }

  Paint fill(Color c) => Paint()..color = c;
  Paint stroke(double w) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeJoin = StrokeJoin.round
    ..color = const Color(0xE6140F2E);
  const glow = [Shadow(color: Color(0x99000000), blurRadius: 14)];

  // Outline first, fill on top.
  final nameOut = line(name, 84, stroke(14), glow);
  final nameIn = line(name, 84, fill(AppColors.yellow), const []);
  final detailOut = line(detail, 46, stroke(10), glow, d: TextDirection.ltr);
  final detailIn = line(
    detail,
    46,
    fill(const Color(0xFFFFFFFF)),
    const [],
    d: TextDirection.ltr,
  );

  // Text block sits beside the logo, and everything hugs the corner the
  // native side anchors to: bottom-right for RTL, bottom-left for LTR.
  final logoLeft = rtl ? width - logoSize - 6 : 6.0;
  // Paragraphs are aligned inside textWidth towards the logo.
  final textX = rtl ? logoLeft - gap - textWidth : logoLeft + logoSize + gap;
  final textH = nameIn.height + detailIn.height;
  final textTop = (height - textH) / 2;

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  final logoRect = Rect.fromLTWH(
    logoLeft,
    (height - logoSize) / 2,
    logoSize,
    logoSize,
  );
  final rounded = RRect.fromRectAndRadius(logoRect, const Radius.circular(48));
  canvas.drawRRect(
    rounded.shift(const Offset(0, 4)),
    Paint()
      ..color = const Color(0x80000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
  );
  if (logo != null) {
    final codec = await ui.instantiateImageCodec(
      logo,
      targetWidth: logoSize.toInt() * 2,
    );
    final img = (await codec.getNextFrame()).image;
    canvas
      ..save()
      ..clipRRect(rounded)
      ..drawImageRect(
        img,
        Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
        logoRect,
        Paint()..filterQuality = FilterQuality.high,
      )
      ..restore();
  } else {
    canvas.drawRRect(rounded, fill(AppColors.yellow));
  }
  canvas.drawRRect(
    rounded,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..color = const Color(0xFFFFFFFF),
  );

  for (final (p, dy) in [
    (nameOut, 0.0),
    (nameIn, 0.0),
    (detailOut, nameIn.height),
    (detailIn, nameIn.height),
  ]) {
    canvas.drawParagraph(p, Offset(textX, textTop + dy));
  }

  final image = await recorder.endRecording().toImage(
    width.toInt(),
    height.toInt(),
  );
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}

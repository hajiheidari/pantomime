import 'package:flutter/material.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/cartoon.dart';

/// Frames for the group photo (designs: polaroid, theater, cartoon, film,
/// minimal). Each is laid out on a fixed 1080 × 1350 canvas (Instagram 4:5)
/// and captured at that size.
enum PhotoFrame { polaroid, theater, cartoon, film, minimal }

const photoCanvas = Size(1080, 1350);

const _ink = Color(0xFF140F2E);
const _night = Color(0xFF2A1D5E);
const _yellow = Color(0xFFFFD43B);
const _pink = Color(0xFFFF5C9A);

class PhotoFrameView extends StatelessWidget {
  const PhotoFrameView({
    super.key,
    required this.frame,
    required this.photo,
    required this.caption,
    required this.names,
    required this.date,
    required this.stamp,
    required this.s,
  });

  final PhotoFrame frame;
  final ImageProvider? photo;
  final String caption;

  /// Team / player names, already joined.
  final String names;
  final String date;

  /// Short numeric date for the film frame's camera stamp ('05 07 21).
  final String stamp;
  final AppStrings s;

  Widget _photo({double radius = 0}) => ClipRRect(
    borderRadius: BorderRadius.circular(radius),
    child: photo == null
        ? Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF7FB3FF),
                  Color(0xFFFFB3D1),
                  Color(0xFFFFE08A),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            alignment: Alignment.center,
            child: const Text('😄😂🤪🥳', style: TextStyle(fontSize: 120)),
          )
        : Image(image: photo!, fit: BoxFit.cover),
  );

  Widget _text(
    String t,
    double size,
    Color color, {
    FontWeight weight = FontWeight.w900,
    int lines = 2,
    TextAlign align = TextAlign.center,
  }) => Text(
    t,
    textAlign: align,
    maxLines: lines,
    overflow: TextOverflow.ellipsis,
    style: TextStyle(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: 1.35,
    ),
  );

  Widget _brand(double logo, double size, Color color) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      AppLogo(size: logo),
      const SizedBox(width: 6),
      _text(s.appName, size, color, lines: 1),
    ],
  );

  Widget _footer(Color infoColor, Color brandColor, {Widget? info}) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Flexible(
        child:
            info ??
            _text(
              '$names | $date',
              32,
              infoColor,
              weight: FontWeight.w700,
              lines: 1,
              align: TextAlign.start,
            ),
      ),
      const SizedBox(width: 16),
      _brand(64, 32, brandColor),
    ],
  );

  @override
  Widget build(BuildContext context) => DefaultTextStyle(
    // Self-contained: rendered the same wherever it is placed or captured.
    style: const TextStyle(
      fontFamily: appFontFamily,
      fontFamilyFallback: appFontFallback,
      decoration: TextDecoration.none,
      color: Colors.white,
    ),
    child: SizedBox.fromSize(
      size: photoCanvas,
      child: switch (frame) {
        PhotoFrame.polaroid => _polaroid(),
        PhotoFrame.theater => _theater(),
        PhotoFrame.cartoon => _cartoon(),
        PhotoFrame.film => _film(),
        PhotoFrame.minimal => _minimal(),
      },
    ),
  );

  Widget _polaroid() => ColoredBox(
    color: _night,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(90, 70, 90, 60),
      child: Transform.rotate(
        angle: -0.035,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFFFDF6),
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [
              BoxShadow(
                color: Color(0x88000000),
                blurRadius: 60,
                offset: Offset(0, 30),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 50,
                right: 50,
                top: 50,
                height: 860,
                child: _photo(radius: 4),
              ),
              Positioned(
                top: -30,
                left: 0,
                right: 0,
                child: Center(
                  child: Transform.rotate(
                    angle: 0.05,
                    child: Container(
                      width: 220,
                      height: 60,
                      color: const Color(0xCCFFD43B),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 50,
                right: 50,
                top: 935,
                child: _text(caption, 50, _night),
              ),
              Positioned(
                left: 50,
                right: 50,
                bottom: 24,
                child: _footer(_pink, _night),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _theater() => Container(
    decoration: const BoxDecoration(
      gradient: RadialGradient(
        center: Alignment(0, -0.4),
        radius: 1.1,
        colors: [Color(0xFFB3123B), Color(0xFF4A0418)],
      ),
    ),
    child: Stack(
      children: [
        // Curtain.
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 150,
          child: Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: _yellow, width: 10)),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.elliptical(540, 60),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < 18; i++)
                  Expanded(
                    child: ColoredBox(
                      color: i.isEven
                          ? const Color(0xFF8E0E2F)
                          : const Color(0xFFA8143A),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 170,
          left: 40,
          right: 40,
          child: Text(
            '🎭 ${s.photoTonight} 🎭',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 62,
              fontWeight: FontWeight.w900,
              color: _yellow,
              shadows: [Shadow(color: Color(0xFF4A0418), offset: Offset(0, 5))],
            ),
          ),
        ),
        Positioned(
          top: 290,
          left: 90,
          right: 90,
          height: 760,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: _yellow, width: 14),
              borderRadius: BorderRadius.circular(30),
              boxShadow: const [
                BoxShadow(color: Color(0x88FFD43B), blurRadius: 60),
                BoxShadow(color: Color(0xFF4A0418), spreadRadius: 8),
              ],
            ),
            child: _photo(radius: 16),
          ),
        ),
        Positioned(
          top: 1075,
          left: 90,
          right: 90,
          child: _text(caption, 48, Colors.white),
        ),
        Positioned(
          left: 90,
          right: 90,
          bottom: 40,
          child: _footer(_yellow, Colors.white),
        ),
      ],
    ),
  );

  Widget _cartoon() => ColoredBox(
    color: _night,
    child: Stack(
      children: [
        const Positioned.fill(child: CustomPaint(painter: _Dots())),
        for (final (e, x, y, a) in const [
          ('✨', 40.0, 40.0, -0.6),
          ('🎉', 960.0, 50.0, 0.3),
          ('🎈', 970.0, 330.0, -0.2),
          ('💥', 20.0, 420.0, 0.4),
          ('🎊', 965.0, 620.0, 0.5),
          ('⭐', 25.0, 760.0, -0.3),
        ])
          Positioned(
            left: x,
            top: y,
            child: Transform.rotate(
              angle: a,
              child: Text(e, style: const TextStyle(fontSize: 68)),
            ),
          ),
        Positioned(
          top: 110,
          left: 110,
          right: 110,
          height: 830,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _yellow,
              border: Border.all(color: _ink, width: 10),
              borderRadius: BorderRadius.circular(60),
              boxShadow: const [BoxShadow(color: _ink, offset: Offset(0, 18))],
            ),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: _ink, width: 8),
                borderRadius: BorderRadius.circular(40),
              ),
              child: _photo(radius: 32),
            ),
          ),
        ),
        Positioned(
          top: 985,
          left: 140,
          right: 140,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: _ink, width: 8),
              borderRadius: BorderRadius.circular(40),
              boxShadow: const [BoxShadow(color: _ink, offset: Offset(0, 12))],
            ),
            child: _text(caption, 44, _ink),
          ),
        ),
        Positioned(
          left: 80,
          right: 80,
          bottom: 36,
          child: _footer(
            _ink,
            _yellow,
            info: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
              decoration: BoxDecoration(
                color: _pink,
                border: Border.all(color: _ink, width: 6),
                borderRadius: BorderRadius.circular(30),
              ),
              child: _text('$names | $date', 30, _ink, lines: 1),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _film() {
    Widget holes() => Column(
      children: [
        for (var i = 0; i < 14; i++)
          Container(
            width: 70,
            height: 40,
            margin: const EdgeInsets.symmetric(vertical: 30),
            color: const Color(0xFFEEEEEE),
          ),
      ],
    );
    return ColoredBox(
      color: const Color(0xFF111111),
      child: Stack(
        children: [
          Positioned(
            left: 40,
            top: 0,
            bottom: 0,
            width: 70,
            child: ClipRect(
              child: OverflowBox(
                alignment: Alignment.topCenter,
                maxHeight: 2000,
                child: holes(),
              ),
            ),
          ),
          Positioned(
            right: 40,
            top: 0,
            bottom: 0,
            width: 70,
            child: ClipRect(
              child: OverflowBox(
                alignment: Alignment.topCenter,
                maxHeight: 2000,
                child: holes(),
              ),
            ),
          ),
          Positioned(
            top: 90,
            left: 150,
            right: 150,
            height: 900,
            child: _photo(),
          ),
          Positioned(
            left: 180,
            top: 920,
            child: Text(
              stamp,
              textDirection: TextDirection.ltr,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 44,
                fontWeight: FontWeight.w700,
                color: Color(0xFFFF8A3D),
                shadows: [Shadow(color: Color(0xFFFF8A3D), blurRadius: 12)],
              ),
            ),
          ),
          Positioned(
            top: 1025,
            left: 150,
            right: 150,
            child: _text(caption, 50, Colors.white),
          ),
          Positioned(
            left: 150,
            right: 150,
            bottom: 50,
            child: _footer(const Color(0xFFBBBBBB), _yellow),
          ),
        ],
      ),
    );
  }

  Widget _minimal() => ColoredBox(
    color: const Color(0xFFFFFAF0),
    child: Stack(
      children: [
        Positioned(top: 0, left: 0, right: 0, height: 1050, child: _photo()),
        PositionedDirectional(
          top: 990,
          start: 60,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
            decoration: BoxDecoration(
              color: _yellow,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 24,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: _text(date, 34, _night, lines: 1),
          ),
        ),
        Positioned(
          top: 1090,
          left: 60,
          right: 60,
          child: _text(caption, 52, _night, align: TextAlign.start),
        ),
        Positioned(
          left: 60,
          right: 60,
          bottom: 36,
          child: _footer(
            _pink,
            _night,
            info: _text(
              names,
              32,
              _pink,
              weight: FontWeight.w700,
              lines: 1,
              align: TextAlign.start,
            ),
          ),
        ),
      ],
    ),
  );
}

class _Dots extends CustomPainter {
  const _Dots();

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = const Color(0x14FFFFFF);
    for (var y = 20.0; y < size.height; y += 40) {
      for (var x = 20.0; x < size.width; x += 40) {
        canvas.drawCircle(Offset(x, y), 3, p);
      }
    }
  }

  @override
  bool shouldRepaint(_Dots oldDelegate) => false;
}

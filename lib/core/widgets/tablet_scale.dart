import 'package:flutter/widgets.dart';

/// UI scale for a screen: 1 on phones; on tablets (shortest side ≥ 600)
/// 1.2–1.4, so the game looks like a big phone instead of tiny widgets in a
/// sea of empty space.
double tabletScaleFor(Size size) {
  final shortest = size.shortestSide;
  if (shortest < 600) return 1;
  return (shortest / 600).clamp(1.2, 1.4);
}

/// Lays the app out on a smaller "virtual" screen and scales it up to fill
/// the real one. Touches, dialogs and sheets follow the same transform.
class TabletScale extends StatelessWidget {
  const TabletScale({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final scale = tabletScaleFor(mq.size);
    if (scale == 1) return child;
    final size = mq.size / scale;
    return FittedBox(
      fit: BoxFit.fill,
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: MediaQuery(
          data: mq.copyWith(
            size: size,
            devicePixelRatio: mq.devicePixelRatio * scale,
            padding: mq.padding / scale,
            viewPadding: mq.viewPadding / scale,
            viewInsets: mq.viewInsets / scale,
          ),
          child: child,
        ),
      ),
    );
  }
}

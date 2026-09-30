import 'package:flutter/material.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/cartoon.dart';
import '../application/game_controller.dart';

bool isLandscape(BuildContext context) =>
    MediaQuery.orientationOf(context) == Orientation.landscape;

/// Header + scrollable body + actions. Portrait: stacked. Landscape (forehead
/// mode): header/actions on one side, body on the other.
class PhaseLayout extends StatelessWidget {
  const PhaseLayout({
    super.key,
    required this.header,
    required this.body,
    required this.actions,
  });

  final List<Widget> header;
  final Widget body;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    if (!isLandscape(context)) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
        child: Column(
          children: [
            ...header,
            Expanded(child: body),
            const SizedBox(height: 12),
            ...actions,
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: FillOrScroll(
              padding: const EdgeInsets.only(top: 40),
              child: Column(children: [...header, const Spacer(), ...actions]),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(child: body),
        ],
      ),
    );
  }
}

class TimerBadge extends StatelessWidget {
  const TimerBadge({
    super.key,
    required this.seconds,
    required this.s,
    this.size = 96,
  });

  final int seconds;
  final AppStrings s;
  final double size;

  @override
  Widget build(BuildContext context) {
    final warning = seconds <= GameController.warningSeconds;
    return TweenAnimationBuilder<double>(
      key: ValueKey(warning ? seconds : -1),
      tween: Tween(begin: warning ? 1.25 : 1, end: 1),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: warning ? AppColors.red : AppColors.yellow,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.outline, width: 4),
        ),
        child: Text(
          s.n(seconds),
          style: TextStyle(
            fontSize: size * 0.42,
            fontWeight: FontWeight.w900,
            color: warning ? Colors.white : AppColors.ink,
          ),
        ),
      ),
    );
  }
}

class PausedOverlay extends StatelessWidget {
  const PausedOverlay({super.key, required this.s, required this.onResume});

  final AppStrings s;
  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) => Positioned.fill(
    child: ColoredBox(
      color: AppColors.backgroundDeep.withValues(alpha: 0.96),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('⏸️', style: TextStyle(fontSize: 72)),
              Text(
                s.paused,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 20),
              CartoonButton(
                label: s.resume,
                icon: '▶️',
                expand: false,
                color: AppColors.green,
                onPressed: onResume,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class GameBanner extends StatelessWidget {
  const GameBanner({super.key, required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.outline, width: 3),
    ),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w900,
        color: Colors.white,
      ),
    ),
  );
}

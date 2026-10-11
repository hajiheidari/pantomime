import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// Big, chunky button with a thick outline and a hard offset shadow that
/// "presses in" when tapped.
class CartoonButton extends StatefulWidget {
  const CartoonButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = AppColors.yellow,
    this.textColor = AppColors.ink,
    this.icon,
    this.subtitle,
    this.height = 72,
    this.fontSize = 24,
    this.expand = true,
    this.stacked = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final Color textColor;
  final String? icon;
  final String? subtitle;
  final double height;
  final double fontSize;
  final bool expand;

  /// Icon above the label (for narrow buttons side by side).
  final bool stacked;

  @override
  State<CartoonButton> createState() => _CartoonButtonState();
}

Widget _maybeFit(bool fit, Widget child) =>
    fit ? FittedBox(fit: BoxFit.scaleDown, child: child) : child;

class _CartoonButtonState extends State<CartoonButton> {
  static const _depth = 6.0;
  bool _down = false;

  bool get _enabled => widget.onPressed != null;

  void _set(bool down) {
    if (_enabled && _down != down) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    final color = _enabled ? widget.color : const Color(0xFF6E6690);
    final offset = _down ? _depth - 2 : 0.0;
    // Tall buttons (e.g. play screen) stack the icon above the label so
    // short Persian words never get truncated in narrow buttons.
    final iconOnTop = widget.stacked || widget.height >= 110;
    final content = Flex(
      direction: iconOnTop ? Axis.vertical : Axis.horizontal,
      mainAxisSize: widget.expand && !iconOnTop
          ? MainAxisSize.max
          : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.icon != null) ...[
          Text(widget.icon!, style: TextStyle(fontSize: widget.fontSize + 4)),
          SizedBox(width: iconOnTop ? 0 : 12, height: iconOnTop ? 4 : 0),
        ],
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Stacked labels shrink to fit rather than lose letters.
              _maybeFit(
                iconOnTop,
                Text(
                  widget.label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: iconOnTop ? null : TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: widget.fontSize,
                    fontWeight: FontWeight.w900,
                    color: widget.textColor,
                    height: 1.2,
                  ),
                ),
              ),
              if (widget.subtitle != null)
                Text(
                  widget.subtitle!,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: widget.fontSize * 0.55,
                    fontWeight: FontWeight.w600,
                    color: widget.textColor.withValues(alpha: 0.8),
                  ),
                ),
            ],
          ),
        ),
      ],
    );

    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _set(true),
        onTapCancel: () => _set(false),
        onTapUp: (_) => _set(false),
        onTap: _enabled
            ? () {
                HapticFeedback.selectionClick();
                widget.onPressed!();
              }
            : null,
        child: SizedBox(
          height: widget.height + _depth,
          child: Stack(
            children: [
              Positioned.fill(
                top: _depth,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.outline,
                    borderRadius: BorderRadius.circular(widget.height / 3),
                  ),
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 60),
                top: offset,
                left: 0,
                right: 0,
                height: widget.height,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(widget.height / 3),
                    border: Border.all(color: AppColors.outline, width: 3),
                  ),
                  child: Center(child: content),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Light card with thick outline, used for grouped content.
class CartoonCard extends StatelessWidget {
  const CartoonCard({
    super.key,
    required this.child,
    this.color = AppColors.card,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final Color color;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: AppColors.outline, width: 3),
      boxShadow: const [
        BoxShadow(color: AppColors.outline, offset: Offset(0, 5)),
      ],
    ),
    child: child,
  );
}

/// Small selectable pill used for option groups in setup.
class CartoonChip extends StatelessWidget {
  const CartoonChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.color = AppColors.yellow,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    child: GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.outline, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.outline,
              offset: Offset(0, selected ? 1 : 3),
            ),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
      ),
    ),
  );
}

/// Emoji that gently bounces forever.
class BouncyEmoji extends StatefulWidget {
  const BouncyEmoji(this.emoji, {super.key, this.size = 72}) : content = null;

  /// Bounces any widget (e.g. the app logo) instead of an emoji.
  const BouncyEmoji.widget(Widget this.content, {super.key})
    : emoji = '',
      size = 0;

  final String emoji;
  final double size;
  final Widget? content;

  @override
  State<BouncyEmoji> createState() => _BouncyEmojiState();
}

class _BouncyEmojiState extends State<BouncyEmoji>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (context, child) {
      final t = Curves.easeInOut.transform(_c.value);
      return Transform.translate(
        offset: Offset(0, -10 * t),
        child: Transform.rotate(angle: (t - 0.5) * 0.15, child: child),
      );
    },
    child:
        widget.content ??
        Text(widget.emoji, style: TextStyle(fontSize: widget.size)),
  );
}

/// The masks logo (same drawing as the app icon and the launch screen).
/// [size] is the size of the masks; the image has a wide transparent margin.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 96});

  static const asset = 'assets/branding/splash_logo.png';

  /// The masks fill about 45% of the image.
  static const _fill = 0.45;

  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: OverflowBox(
      maxWidth: size / _fill,
      maxHeight: size / _fill,
      child: Image.asset(asset, width: size / _fill, height: size / _fill),
    ),
  );
}

/// Pops a child in with an elastic scale when it first appears (or its key
/// changes).
class PopIn extends StatelessWidget {
  const PopIn({super.key, required this.child, this.delay = Duration.zero});

  final Widget child;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    final total = const Duration(milliseconds: 550) + delay;
    final start = delay.inMilliseconds / total.inMilliseconds;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      builder: (context, v, child) {
        final t = v <= start ? 0.0 : (v - start) / (1 - start);
        return Transform.scale(
          scale: Curves.elasticOut.transform(t),
          child: child,
        );
      },
      child: child,
    );
  }
}

/// Team avatar: coloured circle with the team emoji.
class TeamAvatar extends StatelessWidget {
  const TeamAvatar({super.key, required this.teamIndex, this.size = 44});

  final int teamIndex;
  final double size;

  @override
  Widget build(BuildContext context) {
    final style = TeamStyle.of(teamIndex);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: style.color,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.outline, width: 2.5),
      ),
      child: Text(style.emoji, style: TextStyle(fontSize: size * 0.55)),
    );
  }
}

/// Section title used on setup/settings screens.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 10),
    child: Row(
      children: [
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
              color: AppColors.yellow,
            ),
          ),
        ),
        ?trailing,
      ],
    ),
  );
}

/// Lays out [child] (a Column that may contain Spacers) to fill the screen,
/// but scrolls instead of overflowing on small screens / large text.
class FillOrScroll extends StatelessWidget {
  const FillOrScroll({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      padding: padding,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight:
              constraints.maxHeight - (padding?.vertical ?? 0).clamp(0, 1e9),
        ),
        child: IntrinsicHeight(child: child),
      ),
    ),
  );
}

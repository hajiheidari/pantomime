import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/cartoon.dart';
import '../application/game_controller.dart';
import '../application/motion.dart';
import '../domain/game_state.dart';
import '../domain/tilt_detector.dart';
import 'game_widgets.dart';

/// Declares sensors unavailable when the stream errors or stays silent.
mixin _MotionSubscription<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {
  static const _silenceTimeout = Duration(milliseconds: 1500);

  StreamSubscription<MotionSample>? _sub;
  Timer? _silence;
  bool sensorsUnavailable = false;

  void onSample(MotionSample sample);

  void listenMotion() {
    _silence = Timer(_silenceTimeout, _markUnavailable);
    _sub = ref
        .read(accelerometerProvider)
        .listen(
          (sample) {
            _silence?.cancel();
            _silence = null;
            onSample(sample);
          },
          onError: (Object _) => _markUnavailable(),
          cancelOnError: true,
        );
  }

  void _markUnavailable() {
    if (mounted && !sensorsUnavailable) {
      setState(() => sensorsUnavailable = true);
    }
  }

  void cancelMotion() {
    _silence?.cancel();
    _sub?.cancel();
  }
}

// ---------------------------------------------------------------------------
// Calibration

/// "Put the phone on your forehead": waits until it is held still and
/// upright, then records the neutral tilt and starts the countdown.
class CalibrateView extends ConsumerStatefulWidget {
  const CalibrateView({super.key, required this.session, required this.s});

  final GameSession session;
  final AppStrings s;

  @override
  ConsumerState<CalibrateView> createState() => _CalibrateViewState();
}

class _CalibrateViewState extends ConsumerState<CalibrateView>
    with _MotionSubscription {
  /// Gives the player time to lift the phone before we accept "still".
  static const _grace = Duration(milliseconds: 1200);

  final _tracker = CalibrationTracker();
  Duration? _start;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    listenMotion();
  }

  @override
  void dispose() {
    cancelMotion();
    super.dispose();
  }

  @override
  void onSample(MotionSample m) {
    if (_done) return;
    _start ??= m.time;
    if (m.time - _start! < _grace) return;
    final before = _tracker.progress;
    final baseline = _tracker.add(m.x, m.y, m.z, m.time);
    if (baseline != null) {
      _done = true;
      ref.read(gameControllerProvider.notifier).calibrated(baseline);
    } else if ((_tracker.progress - before).abs() > 0.02) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    final color = TeamStyle.of(widget.session.game.currentTeamIndex).color;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: sensorsUnavailable ? 0 : _tracker.progress,
                    strokeWidth: 10,
                    color: color,
                    backgroundColor: AppColors.surface,
                  ),
                ),
                const BouncyEmoji('🤳', size: 56),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            s.putOnForehead,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            sensorsUnavailable ? s.sensorUnavailable : s.holdStill,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 17, color: AppColors.textMuted),
          ),
          if (sensorsUnavailable) ...[
            const SizedBox(height: 16),
            CartoonButton(
              label: s.startWithButtons,
              icon: '👆',
              expand: false,
              color: color,
              onPressed: () =>
                  ref.read(gameControllerProvider.notifier).calibrated(0),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Play

/// Forehead play screen: giant word for the group, tilt down = correct,
/// tilt up = pass. Falls back to buttons when there is no motion sensor.
class ForeheadPlayView extends ConsumerStatefulWidget {
  const ForeheadPlayView({super.key, required this.session, required this.s});

  final GameSession session;
  final AppStrings s;

  @override
  ConsumerState<ForeheadPlayView> createState() => _ForeheadPlayViewState();
}

class _ForeheadPlayViewState extends ConsumerState<ForeheadPlayView>
    with _MotionSubscription {
  late final _detector = TiltDetector(baseline: widget.session.tiltBaseline);

  /// Outcome currently flashed full-screen, if any.
  WordOutcome? _flash;
  Timer? _flashTimer;

  @override
  void initState() {
    super.initState();
    listenMotion();
  }

  @override
  void dispose() {
    cancelMotion();
    _flashTimer?.cancel();
    super.dispose();
  }

  @override
  void onSample(MotionSample m) {
    final action = _detector.add(m.x, m.y, m.z, m.time);
    if (action == null) return;
    final ctrl = ref.read(gameControllerProvider.notifier);
    action == TiltAction.down ? ctrl.markCorrect() : ctrl.markPass();
  }

  void _showFlash(WordOutcome outcome) {
    _flashTimer?.cancel();
    setState(() => _flash = outcome);
    _flashTimer = Timer(const Duration(milliseconds: 650), () {
      if (mounted) setState(() => _flash = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(gameControllerProvider.select((s) => s?.results.length ?? 0), (
      prev,
      next,
    ) {
      final results = ref.read(gameControllerProvider)?.results;
      if (next > (prev ?? 0) && results != null && results.isNotEmpty) {
        _showFlash(results.last.outcome);
      }
    });

    final session = widget.session;
    final s = widget.s;
    final ctrl = ref.read(gameControllerProvider.notifier);
    final word = session.currentWord;
    final flash = _flash;

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            children: [
              Row(
                children: [
                  TeamAvatar(teamIndex: session.game.currentTeamIndex),
                  const Spacer(),
                  TimerBadge(seconds: session.remainingSeconds, s: s, size: 72),
                  const Spacer(),
                  IconButton(
                    iconSize: 34,
                    icon: const Icon(Icons.pause_circle_filled_rounded),
                    onPressed: () => ctrl.setPaused(true),
                  ),
                ],
              ),
              Expanded(
                child: Center(
                  child: PopIn(
                    key: ValueKey(word),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 700),
                        child: Text(
                          word?.text ?? '—',
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          style: const TextStyle(
                            fontSize: 72,
                            height: 1.3,
                            fontWeight: FontWeight.w900,
                            color: AppColors.yellow,
                            shadows: [
                              Shadow(
                                color: AppColors.outline,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (sensorsUnavailable)
                Row(
                  children: [
                    Expanded(
                      child: CartoonButton(
                        label: s.correct,
                        icon: '✅',
                        color: AppColors.green,
                        onPressed: ctrl.markCorrect,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: CartoonButton(
                        label: s.pass,
                        icon: '⏭️',
                        color: AppColors.orange,
                        onPressed: ctrl.markPass,
                      ),
                    ),
                  ],
                )
              else
                Text(
                  '${s.tiltDownCorrect}   •   ${s.tiltUpPass}',
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ),
        if (flash != null)
          Positioned.fill(
            child: IgnorePointer(
              child: ColoredBox(
                color: flash == WordOutcome.correct
                    ? AppColors.green
                    : AppColors.orange,
                child: Center(
                  child: PopIn(
                    child: Text(
                      flash == WordOutcome.correct
                          ? '✅ ${s.correct}!'
                          : '⏭️ ${s.pass}',
                      style: const TextStyle(
                        fontSize: 72,
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        if (session.paused)
          PausedOverlay(s: s, onResume: () => ctrl.setPaused(false)),
      ],
    );
  }
}

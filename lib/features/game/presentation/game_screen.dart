import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/cartoon.dart';
import '../../ads/ads_providers.dart';
import '../../recording/round_recorder.dart';
import '../../settings/settings_controller.dart';
import '../../share/share_cards.dart';
import '../../share/share_sheet.dart';
import '../application/game_controller.dart';
import '../application/motion.dart';
import '../domain/game_config.dart';
import '../domain/game_state.dart';
import 'forehead_views.dart';
import 'game_widgets.dart';

/// Hosts a whole game. Switches between phases driven by [GameController].
/// Forehead mode is landscape-locked for the whole game.
class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  late final AppLifecycleListener _lifecycle;
  late final bool _forehead;

  /// Front-camera recorder (forehead mode with recording enabled only).
  RoundRecorder? _recorder;
  bool _recording = false;

  @override
  void initState() {
    super.initState();
    _forehead =
        ref.read(gameControllerProvider)?.config.mode == GameMode.forehead;
    if (_forehead) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
    // Not during build: providers can't change while the tree builds.
    Future.microtask(() => ref.read(roundClipsProvider.notifier).clear());
    if (_forehead && !kIsWeb && ref.read(settingsProvider).recordingOn) {
      _recorder = ref.read(roundRecorderFactoryProvider)();
    }
    WakelockPlus.enable().catchError((_) {});
    _lifecycle = AppLifecycleListener(
      onInactive: () =>
          ref.read(gameControllerProvider.notifier).setPaused(true),
    );
  }

  /// Starts recording when a round starts, stops it when the round ends.
  Future<void> _onPhase(GamePhase? prev, GameSession next) async {
    final recorder = _recorder;
    if (recorder == null) return;
    if (next.phase == GamePhase.ready && next.game.turnIndex == 0) {
      ref.read(roundClipsProvider.notifier).clear(); // "play again"
    }
    // The camera is on only from calibration to the end of the round (no
    // privacy indicator during summaries or the scoreboard).
    if (next.phase == GamePhase.calibrating) {
      await recorder.prepare(); // ready before the countdown ends
    } else if (next.phase == GamePhase.ready && prev != null) {
      await recorder.dispose(); // e.g. countdown cancelled
    } else if (next.phase == GamePhase.playing && prev != GamePhase.playing) {
      if (await recorder.prepare()) {
        await recorder.start();
        if (mounted) setState(() => _recording = recorder.isRecording);
      }
    } else if (prev == GamePhase.playing && next.phase != GamePhase.playing) {
      final turn = next.game.turns.length - 1;
      final path = await recorder.stop();
      await recorder.dispose(); // release the camera until the next round
      if (mounted) setState(() => _recording = false);
      if (path != null && turn >= 0) {
        ref.read(roundClipsProvider.notifier).add(turn, path);
      }
    }
  }

  @override
  void dispose() {
    _recorder?.dispose();
    _lifecycle.dispose();
    WakelockPlus.disable().catchError((_) {});
    if (_forehead) {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    super.dispose();
  }

  Future<void> _confirmExit() async {
    final ctrl = ref.read(gameControllerProvider.notifier);
    final session = ref.read(gameControllerProvider);
    if (session == null || session.phase == GamePhase.finished) {
      _leave();
      return;
    }
    ctrl.setPaused(true);
    final s = ref.read(stringsProvider);
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.exitGameTitle),
        content: Text(s.exitGameBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(s.exit, style: const TextStyle(color: AppColors.red)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.green,
              foregroundColor: AppColors.ink,
            ),
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              s.stay,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
    if (leave ?? false) {
      _leave();
    } else {
      ctrl.setPaused(false);
    }
  }

  void _leave() {
    ref.read(gameControllerProvider.notifier).quit();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(gameControllerProvider);
    final s = ref.watch(stringsProvider);
    ref.listen(gameControllerProvider, (prev, next) {
      if (next != null && prev?.phase != next.phase) {
        _onPhase(prev?.phase, next);
      }
    });
    if (session == null) return const Scaffold(body: SizedBox.shrink());

    final Widget view = switch (session.phase) {
      GamePhase.ready => _ReadyView(session: session, s: s),
      GamePhase.calibrating => CalibrateView(session: session, s: s),
      GamePhase.countdown => _CountdownView(session: session, s: s),
      GamePhase.playing =>
        session.isForehead
            ? ForeheadPlayView(session: session, s: s)
            : _PlayView(session: session, s: s),
      GamePhase.summary => _SummaryView(session: session, s: s),
      GamePhase.scoreboard => _ScoreboardView(session: session, s: s),
      GamePhase.finished => _FinishedView(
        session: session,
        s: s,
        onHome: _leave,
      ),
    };

    final showClose =
        session.phase != GamePhase.playing &&
        session.phase != GamePhase.countdown;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmExit();
      },
      child: Scaffold(
        body: DecoratedBox(
          decoration: appBackground,
          child: SafeArea(
            child: Stack(
              children: [
                Positioned.fill(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: KeyedSubtree(
                      key: ValueKey(
                        '${session.phase}-${session.game.turnIndex}',
                      ),
                      child: view,
                    ),
                  ),
                ),
                if (_recording && session.phase == GamePhase.playing)
                  PositionedDirectional(
                    bottom: 8,
                    start: 12,
                    child: _RecBadge(label: s.rec),
                  ),
                if (showClose)
                  PositionedDirectional(
                    top: 4,
                    start: 4,
                    child: IconButton(
                      iconSize: 30,
                      icon: const Icon(Icons.close_rounded),
                      onPressed: _confirmExit,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RecBadge extends StatefulWidget {
  const _RecBadge({required this.label});

  final String label;

  @override
  State<_RecBadge> createState() => _RecBadgeState();
}

class _RecBadgeState extends State<_RecBadge>
    with SingleTickerProviderStateMixin {
  late final _blink = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _blink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.black54,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FadeTransition(
          opacity: _blink,
          child: const Icon(Icons.circle, color: AppColors.red, size: 12),
        ),
        const SizedBox(width: 6),
        Text(
          widget.label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Ready

class _ReadyView extends ConsumerWidget {
  const _ReadyView({required this.session, required this.s});

  final GameSession session;
  final AppStrings s;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = session.game;
    final team = game.currentTeamIndex;
    final style = TeamStyle.of(team);
    final landscape = isLandscape(context);

    final roundLabel = game.isSuddenDeath
        ? GameBanner(text: '⚡ ${s.suddenDeath}', color: AppColors.red)
        : Text(
            s.roundOf(game.currentRound, game.config.roundsPerTeam),
            style: const TextStyle(
              fontSize: 18,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w700,
            ),
          );
    final who = [
      PopIn(
        child: TeamAvatar(teamIndex: team, size: landscape ? 96 : 130),
      ),
      const SizedBox(height: 14),
      Text(
        s.turnOf(game.config.teamNames[team]),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: landscape ? 32 : 38,
          fontWeight: FontWeight.w900,
          color: style.color,
          shadows: const [
            Shadow(color: AppColors.outline, offset: Offset(0, 4)),
          ],
        ),
      ),
      const SizedBox(height: 4),
      Text(
        s.score(game.scoreOf(team)),
        style: const TextStyle(fontSize: 18, color: AppColors.textMuted),
      ),
    ];
    final howTo = CartoonCard(
      child: Text(
        session.isForehead ? s.foreheadHowTo : s.howToPlay,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 15,
          color: AppColors.ink,
          height: 1.7,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
    final start = CartoonButton(
      label: s.start,
      icon: '▶️',
      height: landscape ? 76 : 90,
      fontSize: 32,
      color: style.color,
      onPressed: () async {
        final ctrl = ref.read(gameControllerProvider.notifier);
        // iPhone browsers ask for motion access; it must start from a tap.
        if (session.isForehead) await requestMotionPermission();
        ctrl.startTurn();
      },
    );

    if (landscape) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
        child: Row(
          children: [
            Expanded(
              child: FillOrScroll(
                padding: const EdgeInsets.only(top: 36),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [roundLabel, const SizedBox(height: 10), ...who],
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: FillOrScroll(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [howTo, const SizedBox(height: 16), start],
                ),
              ),
            ),
          ],
        ),
      );
    }
    return FillOrScroll(
      padding: const EdgeInsets.fromLTRB(24, 56, 24, 20),
      child: Column(
        children: [
          roundLabel,
          const Spacer(),
          ...who,
          const Spacer(),
          howTo,
          const SizedBox(height: 24),
          start,
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Countdown

class _CountdownView extends StatelessWidget {
  const _CountdownView({required this.session, required this.s});

  final GameSession session;
  final AppStrings s;

  @override
  Widget build(BuildContext context) {
    final color = TeamStyle.of(session.game.currentTeamIndex).color;
    return Center(
      child: PopIn(
        key: ValueKey(session.countdown),
        child: Text(
          s.n(session.countdown),
          style: TextStyle(
            fontSize: isLandscape(context) ? 160 : 200,
            fontWeight: FontWeight.w900,
            color: color,
            shadows: const [
              Shadow(color: AppColors.outline, offset: Offset(0, 8)),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Play (team mode)

class _PlayView extends ConsumerWidget {
  const _PlayView({required this.session, required this.s});

  final GameSession session;
  final AppStrings s;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctrl = ref.read(gameControllerProvider.notifier);
    final word = session.currentWord;
    final team = session.game.currentTeamIndex;
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            children: [
              Row(
                children: [
                  TeamAvatar(teamIndex: team, size: 48),
                  const Spacer(),
                  TimerBadge(seconds: session.remainingSeconds, s: s),
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
                    child: CartoonCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 36,
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: Text(
                          word?.text ?? '—',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 48,
                            height: 1.35,
                            fontWeight: FontWeight.w900,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Text(
                session.canPass
                    ? s.passesLeft(session.passesLeft)
                    : s.noPassLeft,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: CartoonButton(
                      label: s.correct,
                      icon: '✅',
                      height: 120,
                      fontSize: 30,
                      color: AppColors.green,
                      onPressed: ctrl.markCorrect,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    flex: 2,
                    child: CartoonButton(
                      label: s.pass,
                      icon: '⏭️',
                      height: 120,
                      fontSize: 26,
                      color: AppColors.orange,
                      onPressed: session.canPass ? ctrl.markPass : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (session.paused)
          PausedOverlay(s: s, onResume: () => ctrl.setPaused(false)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Summary

class _SummaryView extends ConsumerWidget {
  const _SummaryView({required this.session, required this.s});

  final GameSession session;
  final AppStrings s;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctrl = ref.read(gameControllerProvider.notifier);
    final turn = session.lastTurn!;
    final color = TeamStyle.of(turn.teamIndex).color;
    return PhaseLayout(
      header: [
        Text(
          s.timeUp,
          style: const TextStyle(
            fontSize: 20,
            color: AppColors.textMuted,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          session.config.teamNames[turn.teamIndex],
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        PopIn(
          key: ValueKey(turn.score),
          child: Text(
            s.score(turn.score),
            style: const TextStyle(
              fontSize: 44,
              fontWeight: FontWeight.w900,
              color: AppColors.yellow,
              shadows: [Shadow(color: AppColors.outline, offset: Offset(0, 4))],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          s.tapToFix,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
        ),
        const SizedBox(height: 12),
      ],
      body: turn.results.isEmpty
          ? Center(
              child: Text(
                s.noWordsPlayed,
                style: const TextStyle(fontSize: 20),
              ),
            )
          : ListView.separated(
              itemCount: turn.results.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) => _ResultTile(
                result: turn.results[i],
                s: s,
                onTap: () => ctrl.toggleSummaryWord(i),
              ),
            ),
      actions: [
        _TurnShareRow(session: session, s: s, turn: turn),
        const SizedBox(height: 10),
        CartoonButton(
          label: s.continueLabel,
          color: AppColors.yellow,
          onPressed: ctrl.confirmSummary,
        ),
      ],
    );
  }
}

/// Score-card image for every turn, plus save/share of the recorded clip
/// when forehead-mode recording is on.
class _TurnShareRow extends ConsumerWidget {
  const _TurnShareRow({
    required this.session,
    required this.s,
    required this.turn,
  });

  final GameSession session;
  final AppStrings s;
  final TurnRecord turn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clip = ref.watch(roundClipsProvider)[session.game.turns.length - 1];
    Widget small(String label, String icon, Color color, VoidCallback onTap) =>
        Expanded(
          child: CartoonButton(
            label: label,
            icon: icon,
            height: 52,
            fontSize: 15,
            color: color,
            onPressed: onTap,
          ),
        );
    return Row(
      children: [
        small(s.shareCard, '🖼️', AppColors.cyan, () {
          showShareCardSheet(
            context,
            s: s,
            caption: s.shareCaption(turn.score),
            card: RoundShareCard(
              s: s,
              name: session.config.teamNames[turn.teamIndex],
              teamIndex: turn.teamIndex,
              turn: turn,
            ),
          );
        }),
        if (clip != null) ...[
          const SizedBox(width: 8),
          small(s.saveVideo, '💾', AppColors.card, () async {
            final ok = await saveVideoToGallery(clip);
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(ok ? s.videoSaved : s.videoSaveFailed)),
            );
          }),
          const SizedBox(width: 8),
          small(
            s.shareVideo,
            '🎬',
            AppColors.pink,
            () => shareVideo(clip, s.shareCaption(turn.score)),
          ),
        ],
      ],
    );
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({
    required this.result,
    required this.s,
    required this.onTap,
  });

  final WordResult result;
  final AppStrings s;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ok = result.isCorrect;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: ok ? AppColors.green : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.outline, width: 2.5),
        ),
        child: Row(
          children: [
            Text(ok ? '✅' : '❌', style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                result.word.text,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: ok ? AppColors.ink : AppColors.text,
                ),
              ),
            ),
            if (result.outcome == WordOutcome.timeout)
              Text(
                s.timedOutWord,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Scoreboard

class _ScoreboardView extends ConsumerStatefulWidget {
  const _ScoreboardView({required this.session, required this.s});

  final GameSession session;
  final AppStrings s;

  @override
  ConsumerState<_ScoreboardView> createState() => _ScoreboardViewState();
}

class _ScoreboardViewState extends ConsumerState<_ScoreboardView> {
  bool _busy = false;

  /// Between turns is the only interstitial slot. The ad manager skips
  /// silently when nothing is ready within ~3 s.
  Future<void> _next() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref.read(adManagerProvider).onTurnTransition();
    } finally {
      ref.read(gameControllerProvider.notifier).nextTurn();
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final s = widget.s;
    final game = session.game;
    final preview = game.advance();
    final enteringSuddenDeath =
        !preview.finished && preview.isSuddenDeath && !game.isSuddenDeath;
    final nextName = preview.finished
        ? null
        : game.config.teamNames[preview.currentTeamIndex];
    return PhaseLayout(
      header: [
        Text(
          s.scoreboard,
          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 16),
      ],
      body: _Standings(session: session, s: s),
      actions: [
        if (enteringSuddenDeath) ...[
          GameBanner(
            text: '⚡ ${s.suddenDeath} ${s.suddenDeathHint}',
            color: AppColors.red,
          ),
          const SizedBox(height: 12),
        ],
        CartoonButton(
          label: nextName == null ? s.seeResults : s.nextTurn(nextName),
          icon: nextName == null ? '🏆' : null,
          color: nextName == null
              ? AppColors.yellow
              : TeamStyle.of(preview.currentTeamIndex).color,
          onPressed: _busy ? null : _next,
        ),
      ],
    );
  }
}

/// Teams sorted by score with animated bars.
class _Standings extends StatelessWidget {
  const _Standings({required this.session, required this.s});

  final GameSession session;
  final AppStrings s;

  @override
  Widget build(BuildContext context) {
    final game = session.game;
    final ranking = game.ranking;
    final best = game.scoreOf(ranking.first);
    return ListView(
      padding: const EdgeInsets.only(top: 4),
      children: [
        for (final (rank, team) in ranking.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: PopIn(
              delay: Duration(milliseconds: 80 * rank),
              child: CartoonCard(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    TeamAvatar(teamIndex: team, size: 48),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            game.config.teamNames[team],
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(
                                begin: 0,
                                end: best == 0 ? 0 : game.scoreOf(team) / best,
                              ),
                              duration: const Duration(milliseconds: 700),
                              curve: Curves.easeOutCubic,
                              builder: (context, v, _) =>
                                  LinearProgressIndicator(
                                    value: v,
                                    minHeight: 12,
                                    color: TeamStyle.of(team).color,
                                    backgroundColor: AppColors.ink.withValues(
                                      alpha: 0.1,
                                    ),
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      s.n(game.scoreOf(team)),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Finished

class _FinishedView extends ConsumerWidget {
  const _FinishedView({
    required this.session,
    required this.s,
    required this.onHome,
  });

  final GameSession session;
  final AppStrings s;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = session.game;
    final leaders = game.leaders;
    final tie = leaders.length > 1;
    final landscape = isLandscape(context);
    return PhaseLayout(
      header: [
        Text(
          s.finalResults,
          style: const TextStyle(
            fontSize: 20,
            color: AppColors.textMuted,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        BouncyEmoji(tie ? '🤝' : '🏆', size: landscape ? 60 : 90),
        const SizedBox(height: 8),
        PopIn(
          child: Text(
            tie ? s.itsATie : s.winnerIs(game.config.teamNames[leaders.first]),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: landscape ? 28 : 34,
              fontWeight: FontWeight.w900,
              color: tie ? AppColors.yellow : TeamStyle.of(leaders.first).color,
              shadows: const [
                Shadow(color: AppColors.outline, offset: Offset(0, 4)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
      body: _Standings(session: session, s: s),
      actions: [
        CartoonButton(
          label: s.shareResult,
          icon: '📤',
          height: landscape ? 52 : 60,
          fontSize: 20,
          color: AppColors.cyan,
          onPressed: () => showShareCardSheet(
            context,
            s: s,
            caption: s.shareResultCaption,
            card: ResultShareCard(s: s, game: game),
          ),
        ),
        const SizedBox(height: 12),
        CartoonButton(
          label: s.playAgain,
          icon: '🔁',
          height: landscape ? 60 : 72,
          color: AppColors.green,
          onPressed: ref.read(gameControllerProvider.notifier).restart,
        ),
        const SizedBox(height: 12),
        CartoonButton(
          label: s.backHome,
          icon: '🏠',
          height: 56,
          fontSize: 20,
          color: AppColors.card,
          onPressed: onHome,
        ),
      ],
    );
  }
}

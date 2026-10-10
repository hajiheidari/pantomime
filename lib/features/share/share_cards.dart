import 'package:flutter/material.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/cartoon.dart';
import '../game/domain/game_state.dart';
import 'share_link.dart';

/// Frame shared by every share card: app name + call to action, so every
/// shared image advertises the game.
class _CardFrame extends StatelessWidget {
  const _CardFrame({required this.s, required this.child});

  final AppStrings s;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    width: 360,
    padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppColors.background, AppColors.backgroundDeep],
      ),
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: AppColors.yellow, width: 4),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎭', style: TextStyle(fontSize: 30)),
              const SizedBox(width: 8),
              Text(
                s.appName,
                style: const TextStyle(
                  fontFamily: appFontFamily,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.yellow,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        child,
        const SizedBox(height: 14),
        Text(
          s.downloadCta,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: appFontFamily,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          shareLinkLabel(s.languageCode),
          textDirection: TextDirection.ltr,
          style: const TextStyle(
            fontFamily: appFontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: AppColors.yellow,
          ),
        ),
      ],
    ),
  );
}

/// Score card of one turn: team/player, score, correct words.
class RoundShareCard extends StatelessWidget {
  const RoundShareCard({
    super.key,
    required this.s,
    required this.name,
    required this.teamIndex,
    required this.turn,
  });

  final AppStrings s;
  final String name;
  final int teamIndex;
  final TurnRecord turn;

  @override
  Widget build(BuildContext context) {
    final correct = [
      for (final r in turn.results)
        if (r.isCorrect) r.word.text,
    ];
    return _CardFrame(
      s: s,
      child: Column(
        children: [
          TeamAvatar(teamIndex: teamIndex, size: 64),
          const SizedBox(height: 6),
          Text(
            name,
            style: TextStyle(
              fontFamily: appFontFamily,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: TeamStyle.of(teamIndex).color,
            ),
          ),
          Text(
            s.score(turn.score),
            style: const TextStyle(
              fontFamily: appFontFamily,
              fontSize: 40,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          if (correct.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              s.cardCorrectWords,
              style: const TextStyle(
                fontFamily: appFontFamily,
                fontSize: 14,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final w in correct.take(14))
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.green,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.outline, width: 2),
                    ),
                    child: Text(
                      w,
                      style: const TextStyle(
                        fontFamily: appFontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Final result: winner + all team scores.
class ResultShareCard extends StatelessWidget {
  const ResultShareCard({super.key, required this.s, required this.game});

  final AppStrings s;
  final GameState game;

  @override
  Widget build(BuildContext context) {
    final leaders = game.leaders;
    final tie = leaders.length > 1;
    return _CardFrame(
      s: s,
      child: Column(
        children: [
          Text(tie ? '🤝' : '🏆', style: const TextStyle(fontSize: 54)),
          Text(
            tie ? s.itsATie : s.winnerIs(game.config.teamNames[leaders.first]),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: appFontFamily,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: tie ? AppColors.yellow : TeamStyle.of(leaders.first).color,
            ),
          ),
          const SizedBox(height: 10),
          for (final team in game.ranking)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.outline, width: 2.5),
                ),
                child: Row(
                  children: [
                    TeamAvatar(teamIndex: team, size: 36),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        game.config.teamNames[team],
                        style: const TextStyle(
                          fontFamily: appFontFamily,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    Text(
                      s.n(game.scoreOf(team)),
                      style: const TextStyle(
                        fontFamily: appFontFamily,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

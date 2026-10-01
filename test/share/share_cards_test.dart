import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantomime/core/l10n/app_strings.dart';
import 'package:pantomime/features/game/domain/game_config.dart';
import 'package:pantomime/features/game/domain/game_state.dart';
import 'package:pantomime/features/share/share_cards.dart';
import 'package:pantomime/features/words/domain/word_models.dart';

WordResult r(String w, {bool ok = true}) => WordResult(
  WordEntry(text: w, categoryId: 'c', difficulty: Difficulty.easy),
  ok ? WordOutcome.correct : WordOutcome.passed,
);

Widget host(Widget child) => MaterialApp(
  home: Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      body: SingleChildScrollView(child: Center(child: child)),
    ),
  ),
);

void main() {
  const s = FaStrings();

  testWidgets('round card lists correct words only, no overflow', (t) async {
    final turn = TurnRecord(
      teamIndex: 1,
      round: 1,
      suddenDeath: false,
      results: [
        for (var i = 0; i < 20; i++) r('کلمه شماره $i'),
        r('پاس شده', ok: false),
      ],
    );
    await t.pumpWidget(
      host(RoundShareCard(s: s, name: 'تیم ۲', teamIndex: 1, turn: turn)),
    );
    expect(find.text('۲۰ امتیاز'), findsOneWidget);
    expect(find.text('پاس شده'), findsNothing);
    expect(find.text(s.appName), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('result card shows winner and every team', (t) async {
    var g = GameState.start(
      const GameConfig(teamNames: ['الف', 'ب', 'ج', 'د'], roundsPerTeam: 3),
    );
    while (!g.finished) {
      g = g.completeTurn([
        for (var i = 0; i <= g.currentTeamIndex; i++) r('w$i'),
      ]).advance();
    }
    await t.pumpWidget(host(ResultShareCard(s: s, game: g)));
    expect(find.text('د برنده شد!'), findsOneWidget);
    for (final name in ['الف', 'ب', 'ج', 'د']) {
      expect(find.text(name), findsOneWidget);
    }
    expect(t.takeException(), isNull);
  });
}

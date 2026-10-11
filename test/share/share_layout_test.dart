import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantomime/core/l10n/app_strings.dart';
import 'package:pantomime/core/store/app_store.dart';
import 'package:pantomime/core/widgets/cartoon.dart';
import 'package:pantomime/features/game/domain/game_state.dart';
import 'package:pantomime/features/share/share_cards.dart';
import 'package:pantomime/features/share/share_link.dart';
import 'package:pantomime/features/share/share_sheet.dart';
import 'package:pantomime/features/words/domain/word_models.dart';

WordResult r(String w) => WordResult(
  WordEntry(text: w, categoryId: 'c', difficulty: Difficulty.easy),
  WordOutcome.correct,
);

void main() {
  const s = FaStrings();

  testWidgets('landscape share sheet: share button fully on screen', (t) async {
    t.view.physicalSize = const Size(932, 430);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => showShareCardSheet(
                    context,
                    s: s,
                    caption: 'x',
                    card: RoundShareCard(
                      s: s,
                      name: 'بازیکن ۱',
                      teamIndex: 0,
                      turn: TurnRecord(
                        teamIndex: 0,
                        round: 1,
                        suddenDeath: false,
                        results: [
                          r('ضبط صوت'),
                          r('دست بالای دست بسیار است'),
                          r('جزیره گنج'),
                        ],
                      ),
                    ),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
    final button = t.getRect(find.widgetWithText(CartoonButton, s.share));
    expect(button.bottom, lessThanOrEqualTo(430));
    expect(button.top, greaterThanOrEqualTo(0));
    expect(find.text('pantomime.espadna.com'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('three stacked share buttons fit a narrow row', (t) async {
    await t.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: Center(
              child: SizedBox(
                width: 330,
                child: Row(
                  children: [
                    for (final (l, i) in [
                      (s.shareCard, '🖼️'),
                      (s.saveVideo, '💾'),
                      (s.shareVideo, '🎬'),
                    ])
                      Expanded(
                        child: CartoonButton(
                          label: l,
                          icon: i,
                          height: 72,
                          fontSize: 15,
                          stacked: true,
                          onPressed: () {},
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    for (final l in [s.shareCard, s.saveVideo, s.shareVideo]) {
      final text = t.widget<Text>(find.text(l));
      expect(text.overflow, isNull, reason: 'no ellipsis for $l');
    }
    expect(t.takeException(), isNull);
  });

  test('share links per store and language', () {
    expect(
      shareLink('fa', AppStore.bazaar),
      'https://pantomime.espadna.ir/?lang=fa',
    );
    expect(
      shareLink('ar', AppStore.play),
      'https://pantomime.espadna.com/?lang=ar',
    );
    expect(shareLinkLabel('en', AppStore.ios), 'pantomime.espadna.com');
    expect(shareLinkLabel('fa', AppStore.myket), 'pantomime.espadna.ir');
    expect(
      withShareLink('hi', 'en', AppStore.ios),
      'hi\nhttps://pantomime.espadna.com/?lang=en',
    );
    expect(
      appPageLink('fa', AppStore.bazaar),
      'https://espadna.ir/pantomime-app/fa/',
    );
    expect(
      appPageLink('en', AppStore.ios),
      'https://espadna.com/pantomime-app/',
    );
  });
}

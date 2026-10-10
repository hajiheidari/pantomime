import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantomime/core/widgets/tablet_scale.dart';

void main() {
  test('phones are not scaled, tablets 1.2–1.4', () {
    expect(tabletScaleFor(const Size(430, 932)), 1);
    expect(tabletScaleFor(const Size(932, 430)), 1);
    expect(tabletScaleFor(const Size(744, 1133)), closeTo(1.24, 0.01));
    expect(tabletScaleFor(const Size(1366, 1024)), 1.4);
  });

  testWidgets('tablet: layout size shrinks, taps still land', (t) async {
    t.view.physicalSize = const Size(1024, 1366);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    var taps = 0;
    late Size seen;
    await t.pumpWidget(
      MaterialApp(
        builder: (context, child) => TabletScale(child: child!),
        home: Builder(
          builder: (context) {
            seen = MediaQuery.sizeOf(context);
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => taps++,
                  child: const Text('go'),
                ),
              ),
            );
          },
        ),
      ),
    );
    expect(seen.width, closeTo(1024 / 1.4, 0.5));
    await t.tap(find.text('go'));
    expect(taps, 1);
  });
}

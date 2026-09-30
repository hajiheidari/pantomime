import 'package:flutter_test/flutter_test.dart';
import 'package:pantomime/features/game/domain/tilt_detector.dart';

Duration ms(int v) => Duration(milliseconds: v);

/// Feeds [pitch] every 20 ms from [from] to [to]; returns actions seen.
List<TiltAction> feed(TiltDetector d, double pitch, int from, int to) => [
  for (var t = from; t < to; t += 20) ?d.addPitch(pitch, ms(t)),
];

void main() {
  test('pitch from accelerometer: vertical, face down, face up', () {
    expect(pitchDegrees(9.8, 0, 0), closeTo(0, 0.01));
    expect(pitchDegrees(-9.8, 0, 0), closeTo(0, 0.01));
    expect(pitchDegrees(0, 0, -9.8), closeTo(-90, 0.01));
    expect(pitchDegrees(0, 0, 9.8), closeTo(90, 0.01));
    expect(pitchDegrees(6.93, 0, -6.93), closeTo(-45, 0.1));
  });

  test('nod down = correct, tip back = pass', () {
    final d = TiltDetector(smoothing: 1);
    expect(feed(d, 0, 0, 200), isEmpty);
    expect(feed(d, -60, 200, 400), [TiltAction.down]);
    expect(feed(d, 0, 400, 1200), isEmpty);
    expect(feed(d, 60, 1200, 1400), [TiltAction.up]);
  });

  test('one long nod counts once (needs neutral before next action)', () {
    final d = TiltDetector(smoothing: 1);
    expect(feed(d, -70, 0, 3000), [TiltAction.down]);
  });

  test('neutral must be held, a brief pass through does not re-arm', () {
    final d = TiltDetector(smoothing: 1);
    feed(d, -60, 0, 100);
    // Bounce: 100 ms neutral (< 250 ms hold) then down again.
    feed(d, 0, 1000, 1100);
    expect(feed(d, -60, 1100, 1300), isEmpty);
    // Proper neutral hold re-arms.
    feed(d, 0, 1300, 1700);
    expect(feed(d, -60, 1700, 1900), [TiltAction.down]);
  });

  test('cooldown prevents rapid double actions', () {
    final d = TiltDetector(smoothing: 1, cooldown: ms(1000));
    expect(feed(d, -60, 0, 60), [TiltAction.down]);
    feed(d, 0, 60, 600); // neutral long enough, but still cooling down
    expect(d.isArmed, isFalse);
    feed(d, 0, 600, 1100);
    expect(d.isArmed, isTrue);
  });

  test('small wobbles never trigger', () {
    final d = TiltDetector(smoothing: 1);
    final actions = <TiltAction>[];
    for (var t = 0; t < 3000; t += 20) {
      final p = (t ~/ 100).isEven ? 25.0 : -25.0;
      final a = d.addPitch(p, ms(t));
      if (a != null) actions.add(a);
    }
    expect(actions, isEmpty);
  });

  test('works relative to the calibrated baseline', () {
    // Player's head is naturally tipped back 20°.
    final d = TiltDetector(smoothing: 1, baseline: 20);
    expect(feed(d, 50, 0, 200), isEmpty); // only +30 relative
    expect(feed(d, -25, 200, 400), [TiltAction.down]); // -45 relative
  });

  test('low-pass filter ignores a single spike', () {
    final d = TiltDetector();
    feed(d, 0, 0, 200);
    expect(d.addPitch(-80, ms(200)), isNull);
    expect(feed(d, 0, 220, 400), isEmpty);
  });

  group('calibration', () {
    test('succeeds after holding still and upright', () {
      final c = CalibrationTracker(hold: ms(500));
      double? baseline;
      for (var t = 0; t <= 600 && baseline == null; t += 20) {
        baseline = c.addPitch(10 + (t % 40 == 0 ? 2 : -2), ms(t));
      }
      expect(baseline, closeTo(10, 2));
    });

    test('restarts when moved or not upright', () {
      final c = CalibrationTracker(hold: ms(500));
      for (var t = 0; t < 400; t += 20) {
        expect(c.addPitch(0, ms(t)), isNull);
      }
      expect(c.progress, greaterThan(0.5));
      expect(c.addPitch(30, ms(400)), isNull); // jumped > 8°
      expect(c.progress, 0);
      expect(c.addPitch(80, ms(420)), isNull); // lying flat
      expect(c.progress, 0);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:pantomime/features/game/application/motion.dart';

void main() {
  test('gravitySign: spec readings → +1, inverted (iOS) → -1', () {
    // Upright portrait: spec says +y ≈ 9.8.
    expect(gravitySign(0, 0.3, 9.6), 1);
    expect(gravitySign(0, 0.3, -9.6), -1);
    // Landscape on the forehead, either way round.
    expect(gravitySign(90, 9.7, 0.5), 1);
    expect(gravitySign(90, -9.7, 0.5), -1);
    expect(gravitySign(270, -9.7, 0.5), 1);
    expect(gravitySign(270, 9.7, 0.5), -1);
    expect(gravitySign(180, 0, -9.7), 1);
  });

  test('gravitySign: unsure while tilted or lying flat', () {
    expect(gravitySign(90, 3, 1), isNull);
    expect(gravitySign(0, 0, 0.5), isNull);
    expect(gravitySign(45, 9.8, 0), isNull);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:pantomime/core/utils/persian_text.dart';

void main() {
  test('normalizes Arabic letters, ZWNJ, spaces and diacritics', () {
    expect(normalizePersian('يك'), normalizePersian('یک'));
    expect(normalizePersian('می‌رود'), normalizePersian('میرود'));
    expect(normalizePersian(' می  رود '), normalizePersian('میرود'));
    expect(normalizePersian('کَتاب'), normalizePersian('کتاب'));
    expect(normalizePersian('Shrek'), normalizePersian('shrek'));
    expect(normalizePersian('شیر'), isNot(normalizePersian('شتر')));
  });

  test('converts digits', () {
    expect(toPersianDigits('Team 12'), 'Team ۱۲');
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:pantomime/core/l10n/app_strings.dart';
import 'package:pantomime/features/photo/photo_date.dart';

void main() {
  test('Solar Hijri dates', () {
    expect(toJalali(DateTime(2026, 10, 13)), (1405, 7, 21));
    expect(toJalali(DateTime(2026, 3, 21)), (1405, 1, 1)); // Nowruz
    expect(toJalali(DateTime(2025, 3, 20)), (1403, 12, 30));
  });

  test('photo date per language', () {
    final d = DateTime(2026, 10, 13);
    expect(photoDate(const FaStrings(), d), '۲۱ مهر ۱۴۰۵');
    expect(photoDate(const EnStrings(), d), '13.10.2026');
  });
}

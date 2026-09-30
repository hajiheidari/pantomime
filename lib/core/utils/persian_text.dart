/// Helpers for comparing and displaying Persian text.
library;

const _zwnj = '‌';

/// Normalizes Persian text for comparison and de-duplication.
///
/// - Arabic Yeh/Alef Maksura → Persian Yeh (ی), Arabic Kaf → Persian Kaf (ک)
/// - Arabic Heh-with-Yeh / Teh Marbuta variants are left alone (they are real
///   spelling differences), but diacritics and tatweel are removed.
/// - ZWNJ (half-space) is removed so «می‌رود» == «میرود» == «می رود».
/// - Whitespace is collapsed and the string is trimmed and lower-cased
///   (for the English pack).
String normalizePersian(String input) {
  var s = input
      .replaceAll('ي', 'ی')
      .replaceAll('ى', 'ی')
      .replaceAll('ك', 'ک')
      .replaceAll('ـ', '') // tatweel
      .replaceAll(RegExp('[ً-ٰٟ]'), ''); // diacritics
  s = s.replaceAll(_zwnj, '').replaceAll(RegExp(r'\s+'), '');
  return s.trim().toLowerCase();
}

const _persianDigits = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];

/// Converts ASCII digits in [input] to Persian digits.
String toPersianDigits(String input) {
  final b = StringBuffer();
  for (final c in input.codeUnits) {
    if (c >= 0x30 && c <= 0x39) {
      b.write(_persianDigits[c - 0x30]);
    } else {
      b.writeCharCode(c);
    }
  }
  return b.toString();
}

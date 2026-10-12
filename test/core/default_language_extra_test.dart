import 'package:flutter_test/flutter_test.dart';
import 'package:pantomime/core/l10n/app_strings.dart';
import 'package:pantomime/core/l10n/default_language.dart';
import 'package:pantomime/core/store/app_store.dart';
import 'package:pantomime/features/settings/settings_controller.dart';

void main() {
  test('Russian and Turkish devices open in their language', () {
    expect(
      defaultLanguage(AppStore.ios, const DeviceLocale(locales: ['ru_RU'])),
      AppLanguage.ru,
    );
    expect(
      defaultLanguage(AppStore.play, const DeviceLocale(locales: ['tr-TR'])),
      AppLanguage.tr,
    );
    expect(
      defaultLanguage(AppStore.bazaar, const DeviceLocale(locales: ['ru'])),
      AppLanguage.fa,
    );
    expect(AppStrings.forLanguage('ru').languageCode, 'ru');
    expect(AppStrings.forLanguage('tr').languageCode, 'tr');
  });
}

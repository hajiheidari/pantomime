import 'package:flutter_test/flutter_test.dart';
import 'package:pantomime/core/l10n/default_language.dart';
import 'package:pantomime/core/store/app_store.dart';
import 'package:pantomime/features/settings/settings_controller.dart';

void main() {
  const london = DeviceLocale(locales: ['en_GB']);
  const tehranEnglish = DeviceLocale(
    locales: ['en_US'],
    utcOffset: Duration(hours: 3, minutes: 30),
  );

  test('Bazaar and Myket: always Persian', () {
    expect(defaultLanguage(AppStore.bazaar, london), AppLanguage.fa);
    expect(defaultLanguage(AppStore.myket, london), AppLanguage.fa);
  });

  test('Play, App Store, web: Persian-looking devices → Persian', () {
    for (final store in [AppStore.play, AppStore.ios, AppStore.web]) {
      expect(defaultLanguage(store, london), AppLanguage.en, reason: '$store');
      expect(
        defaultLanguage(store, const DeviceLocale(locales: ['de', 'fa_IR'])),
        AppLanguage.fa,
      );
      expect(
        defaultLanguage(store, const DeviceLocale(locales: ['en_IR'])),
        AppLanguage.fa,
      );
      expect(
        defaultLanguage(store, const DeviceLocale(locales: ['prs_AF'])),
        AppLanguage.fa,
      );
      expect(defaultLanguage(store, tehranEnglish), AppLanguage.fa);
    }
  });

  test('a ?lang= link wins on the web', () {
    const enLink = DeviceLocale(locales: ['fa_IR'], requested: AppLanguage.en);
    expect(defaultLanguage(AppStore.web, enLink), AppLanguage.en);
    expect(
      defaultLanguage(
        AppStore.web,
        const DeviceLocale(locales: ['en_US'], requested: AppLanguage.fa),
      ),
      AppLanguage.fa,
    );
  });
}

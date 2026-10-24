import 'package:flutter_test/flutter_test.dart';
import 'package:pantomime/core/store/app_store.dart';
import 'package:pantomime/core/store/iran_links.dart';
import 'package:pantomime/core/store/store_service.dart';

void main() {
  const pkg = 'com.example.pantomime';

  test('Cafe Bazaar: rating uses ACTION_EDIT on the Bazaar app', () {
    final rate = const StoreLinks(AppStore.bazaar, pkg).rate;
    expect(rate.uri, 'bazaar://details?id=$pkg');
    expect(rate.package, 'com.farsitel.bazaar');
    expect(rate.edit, isTrue);
    expect(rate.web, 'https://cafebazaar.ir/app/$pkg');
    expect(const StoreLinks(AppStore.bazaar, pkg).details.edit, isFalse);
  }, skip: !iranLinks);

  test('Myket: comment page for rating, details for update', () {
    const l = StoreLinks(AppStore.myket, pkg);
    expect(l.rate.uri, 'myket://comment?id=$pkg');
    expect(l.details.uri, 'myket://details?id=$pkg');
    expect(l.rate.package, 'ir.mservices.market');
    expect(l.details.web, 'https://myket.ir/app/$pkg');
  }, skip: !iranLinks);

  test('without IRAN_LINKS (iOS builds): no Iranian links at all', () {
    for (final st in AppStore.values) {
      final l = StoreLinks(st, pkg);
      for (final link in [l.rate, l.details]) {
        expect(link.uri, isNot(contains('.ir/')), reason: '$st');
        expect(link.web, isNot(contains('.ir/')), reason: '$st');
      }
    }
  }, skip: iranLinks);

  test('Google Play', () {
    const l = StoreLinks(AppStore.play, pkg);
    expect(l.rate.uri, 'market://details?id=$pkg');
    expect(l.rate.package, 'com.android.vending');
    expect(l.details.web, contains('play.google.com'));
  });

  test('iOS uses the App Store id', () {
    const l = StoreLinks(AppStore.ios, pkg);
    expect(l.rate.uri, startsWith('itms-apps://'));
    expect(l.rate.uri, endsWith('action=write-review'));
    expect(l.details.web, startsWith('https://apps.apple.com/app/id'));
  });

  test('store detection parses flavor names', () {
    expect(AppStore.tryParse('bazaar'), AppStore.bazaar);
    expect(AppStore.tryParse('myket'), AppStore.myket);
    expect(AppStore.tryParse('huawei'), isNull);
    expect(AppStore.bazaar.allowsGooglePlayServices, isFalse);
    expect(AppStore.play.allowsGooglePlayServices, isTrue);
  });
}

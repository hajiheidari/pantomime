import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../features/ads/ads_providers.dart';
import 'app_store.dart';

/// App Store id (numbers only), set at build time: --dart-define=IOS_APP_ID=…
const iosAppId = String.fromEnvironment('IOS_APP_ID');

/// A link into a store app, with a web fallback.
class StoreLink {
  const StoreLink({
    required this.uri,
    required this.web,
    this.package,
    this.edit = false,
  });

  final String uri;
  final String web;

  /// Android package that must handle [uri] (the store app).
  final String? package;

  /// Android: use ACTION_EDIT (Cafe Bazaar's rating page).
  final bool edit;
}

/// Store-specific links for "Rate app" and "Update available".
/// Pure, so the links are unit-tested per store.
class StoreLinks {
  const StoreLinks(this.store, this.packageName);

  final AppStore store;
  final String packageName;

  StoreLink get rate => switch (store) {
    AppStore.play => StoreLink(
      uri: 'market://details?id=$packageName',
      package: 'com.android.vending',
      web: 'https://play.google.com/store/apps/details?id=$packageName',
    ),
    AppStore.bazaar => StoreLink(
      uri: 'bazaar://details?id=$packageName',
      package: 'com.farsitel.bazaar',
      edit: true,
      web: 'https://cafebazaar.ir/app/$packageName',
    ),
    AppStore.myket => StoreLink(
      uri: 'myket://comment?id=$packageName',
      package: 'ir.mservices.market',
      web: 'https://myket.ir/app/$packageName',
    ),
    AppStore.ios => StoreLink(
      uri: 'itms-apps://itunes.apple.com/app/id$iosAppId?action=write-review',
      web: 'https://apps.apple.com/app/id$iosAppId?action=write-review',
    ),
    AppStore.direct => const StoreLink(
      uri: 'https://espadna.com/pantomime-app/',
      web: 'https://espadna.com/pantomime-app/',
    ),
    AppStore.web => StoreLink(
      uri: 'https://cafebazaar.ir/app/$packageName',
      web: 'https://cafebazaar.ir/app/$packageName',
    ),
  };

  StoreLink get details => switch (store) {
    AppStore.play => StoreLink(
      uri: 'market://details?id=$packageName',
      package: 'com.android.vending',
      web: 'https://play.google.com/store/apps/details?id=$packageName',
    ),
    AppStore.bazaar => StoreLink(
      uri: 'bazaar://details?id=$packageName',
      package: 'com.farsitel.bazaar',
      web: 'https://cafebazaar.ir/app/$packageName',
    ),
    AppStore.myket => StoreLink(
      uri: 'myket://details?id=$packageName',
      package: 'ir.mservices.market',
      web: 'https://myket.ir/app/$packageName',
    ),
    AppStore.ios => StoreLink(
      uri: 'itms-apps://itunes.apple.com/app/id$iosAppId',
      web: 'https://apps.apple.com/app/id$iosAppId',
    ),
    AppStore.direct => const StoreLink(
      uri: 'https://espadna.com/pantomime-app/',
      web: 'https://espadna.com/pantomime-app/',
    ),
    AppStore.web => StoreLink(
      uri: 'https://cafebazaar.ir/app/$packageName',
      web: 'https://cafebazaar.ir/app/$packageName',
    ),
  };
}

/// Opens store pages. Kept behind an interface so store-specific code stays
/// in one place.
abstract interface class StoreService {
  Future<void> openRating();
  Future<void> openDetails();
}

class DefaultStoreService implements StoreService {
  DefaultStoreService(this.store);

  final AppStore store;
  static const _channel = MethodChannel('pantomime/store');

  /// The web build has no package name of its own: link to the Android app.
  static const _androidPackage = 'com.espadna.pantomime';

  Future<StoreLinks> _links() async => StoreLinks(
    store,
    kIsWeb ? _androidPackage : (await PackageInfo.fromPlatform()).packageName,
  );

  Future<void> _open(StoreLink link) async {
    try {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        final ok = await _channel.invokeMethod<bool>('openIntent', {
          'action': link.edit ? 'edit' : 'view',
          'uri': link.uri,
          'package': link.package,
        });
        if (ok ?? false) return;
      } else if (await launchUrl(
        Uri.parse(link.uri),
        mode: LaunchMode.externalApplication,
      )) {
        return;
      }
    } catch (e) {
      debugPrint('store link: $e');
    }
    // Store app missing → web page.
    await launchUrl(
      Uri.parse(link.web),
      mode: LaunchMode.externalApplication,
    ).catchError((_) => false);
  }

  @override
  Future<void> openRating() async => _open((await _links()).rate);

  @override
  Future<void> openDetails() async => _open((await _links()).details);
}

final storeServiceProvider = Provider<StoreService>(
  (ref) => DefaultStoreService(ref.watch(appStoreProvider)),
);

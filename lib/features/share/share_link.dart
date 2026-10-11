import 'package:flutter/foundation.dart';

import '../../core/store/app_store.dart';

/// Links sent with every shared invite, image or video: the web game itself
/// (pantomime.espadna.com), so a friend can play right away; its install bar
/// leads to the app page with every store ([appPageLink]).
///
/// Bazaar / Myket builds (and the web game on espadna.ir) are used in Iran:
/// the espadna.ir copy opens there even on the national internet.
bool _inIran(AppStore s) =>
    s == AppStore.bazaar ||
    s == AppStore.myket ||
    (kIsWeb && Uri.base.host.endsWith('espadna.ir'));

String shareLink(String languageCode, [AppStore? store]) {
  final s = store ?? AppStore.detect();
  final host = _inIran(s) ? 'pantomime.espadna.ir' : 'pantomime.espadna.com';
  return 'https://$host/?lang=$languageCode';
}

/// The app's page on the studio site (description + all store links).
String appPageLink(String languageCode, [AppStore? store]) {
  final s = store ?? AppStore.detect();
  if (_inIran(s)) return 'https://espadna.ir/pantomime-app/fa/';
  return switch (languageCode) {
    'fa' => 'https://espadna.com/pantomime-app/fa/',
    'ar' => 'https://espadna.com/pantomime-app/ar/',
    _ => 'https://espadna.com/pantomime-app/',
  };
}

/// The link as printed on images: just the host.
String shareLinkLabel(String languageCode, [AppStore? store]) =>
    Uri.parse(shareLink(languageCode, store)).host;

/// This install's invite code (set at startup, see invite.dart): shared
/// links carry it as i=<code> so a friend's visit can be counted.
String? inviteCode;

/// [url] with the invite code, if there is one.
String withInviteCode(String url) => inviteCode == null
    ? url
    : '$url${url.contains('?') ? '&' : '?'}i=$inviteCode';

/// Caption text followed by the link on its own line.
String withShareLink(String caption, String languageCode, [AppStore? store]) =>
    '$caption\n${withInviteCode(shareLink(languageCode, store))}';

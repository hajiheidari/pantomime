import '../../core/store/app_store.dart';

/// Landing page (description + download links) sent with every shared
/// image or video, so whoever receives it can install the game.
///
/// Bazaar / Myket builds are used in Iran: the espadna.ir copy opens there
/// even on the national internet. Everyone else gets espadna.com in their
/// language.
String shareLink(String languageCode, [AppStore? store]) {
  final s = store ?? AppStore.detect();
  if (s == AppStore.bazaar || s == AppStore.myket) {
    return 'https://espadna.ir/pantomime-app/fa/';
  }
  return switch (languageCode) {
    'fa' => 'https://espadna.com/pantomime-app/fa/',
    'ar' => 'https://espadna.com/pantomime-app/ar/',
    _ => 'https://espadna.com/pantomime-app/',
  };
}

/// The link as printed on images: no scheme, no trailing slash.
String shareLinkLabel(String languageCode, [AppStore? store]) => shareLink(
  languageCode,
  store,
).replaceFirst(RegExp('^https://'), '').replaceFirst(RegExp(r'/$'), '');

/// This install's invite code (set at startup, see invite.dart): shared
/// links carry it as ?i=<code> so a friend's visit can be counted.
String? inviteCode;

/// [url] with the invite code, if there is one.
String withInviteCode(String url) =>
    inviteCode == null ? url : '$url?i=$inviteCode';

/// Caption text followed by the landing page link on its own line.
String withShareLink(String caption, String languageCode, [AppStore? store]) =>
    '$caption\n${withInviteCode(shareLink(languageCode, store))}';

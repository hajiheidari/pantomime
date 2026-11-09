/// Iranian hosts and stores (our Iranian mirror, Cafe Bazaar, Myket) for the
/// Android and web builds. None of them is written in the source: they come
/// from `--dart-define-from-file=tool/iran_links.json`, which only Android
/// and web builds pass (tool/release.sh, tool/build_web.sh). The iOS binary
/// must not contain them (App Review guideline 5, US sanctions); the iOS CI
/// also scans the built app for them and stops if any is found.
library;

const iranLinks = bool.fromEnvironment('IRAN_LINKS');
const irHost = String.fromEnvironment('IR_HOST');
const irApi = String.fromEnvironment('IR_API');
const irConfigUrl = String.fromEnvironment('IR_CONFIG_URL');
const irMirrorUrl = String.fromEnvironment('IR_MIRROR_URL');
const irGameHost = String.fromEnvironment('IR_GAME_HOST');
const irAppPage = String.fromEnvironment('IR_APP_PAGE');
const bazaarScheme = String.fromEnvironment('BAZAAR_SCHEME');
const bazaarPackage = String.fromEnvironment('BAZAAR_PKG');
const bazaarWeb = String.fromEnvironment('BAZAAR_WEB');
const myketScheme = String.fromEnvironment('MYKET_SCHEME');
const myketPackage = String.fromEnvironment('MYKET_PKG');
const myketWeb = String.fromEnvironment('MYKET_WEB');

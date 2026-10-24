/// Iranian hosts and stores (espadna.ir, Cafe Bazaar, Myket, gabia.ir) are
/// compiled in only when the build passes `--dart-define=IRAN_LINKS=true`
/// (Android and web: tool/release.sh, tool/build_web.sh). The iOS binary
/// must not contain them: App Review rejects apps linking to embargoed
/// regions (guideline 5). Every use sits behind this constant, so the AOT
/// compiler drops the strings when it is false.
const iranLinks = bool.fromEnvironment('IRAN_LINKS');

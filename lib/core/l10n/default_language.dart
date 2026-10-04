import '../../features/settings/settings_controller.dart';
import '../store/app_store.dart';

/// What the device tells us about its user, read once at start.
class DeviceLocale {
  const DeviceLocale({
    this.locales = const [],
    this.utcOffset = Duration.zero,
    this.requested,
  });

  /// Preferred locales, e.g. `['en_IR', 'fa']` (language[_COUNTRY]).
  final List<String> locales;

  /// Current time-zone offset.
  final Duration utcOffset;

  /// Web: language asked for by the link (`/play/?lang=en`).
  final AppLanguage? requested;
}

/// Language used until the player picks one in settings:
/// - Bazaar / Myket builds: always Persian.
/// - Elsewhere (Google Play, App Store, web): the first device language we
///   have (Persian, Arabic or English). Many Iranians keep their phone in
///   English, so an Iranian or Afghan region or time zone also means Persian.
///   Anything else: English.
AppLanguage defaultLanguage(AppStore store, DeviceLocale device) {
  if (store == AppStore.bazaar || store == AppStore.myket) {
    return AppLanguage.fa;
  }
  if (device.requested != null) return device.requested!;
  for (final l in device.locales) {
    final parts = l.toLowerCase().split(RegExp('[-_]'));
    if (parts.first == 'fa' || parts.first == 'prs') return AppLanguage.fa;
    if (parts.length > 1 && (parts.last == 'ir' || parts.last == 'af')) {
      return AppLanguage.fa;
    }
    if (parts.first == 'ar') return AppLanguage.ar;
  }
  const tehran = Duration(hours: 3, minutes: 30);
  const kabul = Duration(hours: 4, minutes: 30);
  if (device.utcOffset == tehran || device.utcOffset == kabul) {
    return AppLanguage.fa;
  }
  return AppLanguage.en;
}

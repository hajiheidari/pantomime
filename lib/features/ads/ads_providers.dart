import 'dart:async';
import 'dart:math';

import 'package:ads_core/ads_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/store/app_store.dart';
import '../game/application/game_controller.dart';
import 'ad_keys.dart';
import 'ad_manager.dart';
import 'config/remote_config.dart';
import 'config/remote_config_service.dart';
import 'generated/ad_providers.g.dart';

final appStoreProvider = Provider<AppStore>((ref) => AppStore.detect());

/// Random id generated once per install; only used to assign an A/B bucket.
/// Never sent anywhere.
final installIdProvider = Provider<String>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  const key = 'install_id';
  final existing = prefs.getString(key);
  if (existing != null) return existing;
  final rnd = Random.secure();
  final id = List.generate(
    16,
    (_) => rnd.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
  prefs.setString(key, id);
  return id;
});

/// Networks compiled into this build (see tool/store.dart).
final compiledAdProvidersProvider =
    Provider<Map<String, AdProvider Function()>>(
      (ref) => compiledAdProviders(),
    );

final remoteConfigServiceProvider = Provider<RemoteConfigService>(
  (ref) => RemoteConfigService(
    prefs: ref.watch(sharedPreferencesProvider),
    loadBundled: () =>
        rootBundle.loadString('assets/config/default_config.json'),
  ),
);

/// Current remote config; updates when a newer one is fetched.
final remoteConfigProvider =
    NotifierProvider<RemoteConfigNotifier, RemoteConfig>(
      RemoteConfigNotifier.new,
    );

class RemoteConfigNotifier extends Notifier<RemoteConfig> {
  @override
  RemoteConfig build() {
    final service = ref.watch(remoteConfigServiceProvider);
    final sub = service.changes.listen((c) => state = c);
    ref.onDispose(sub.cancel);
    return service.current;
  }

  void refreshFromService() =>
      state = ref.read(remoteConfigServiceProvider).current;
}

final adManagerProvider = Provider<AdManager>((ref) {
  final service = ref.watch(remoteConfigServiceProvider);
  final ios = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
  return AdManager(
    store: ref.watch(appStoreProvider),
    installId: ref.watch(installIdProvider),
    factories: ref.watch(compiledAdProvidersProvider),
    config: () => service.current,
    localIds: (p) => LocalAdKeys.forProvider(p, ios: ios),
    isIos: ios,
    isGameplayActive: () {
      final phase = ref.read(gameControllerProvider)?.phase;
      return phase == GamePhase.playing ||
          phase == GamePhase.countdown ||
          phase == GamePhase.calibrating;
    },
  );
});

/// Starts ads without ever delaying app start: local config first, network
/// refresh in the background, SDK init a moment after the first frame.
Future<void> startAds(ProviderContainer container) async {
  try {
    final service = container.read(remoteConfigServiceProvider);
    await service.loadLocal();
    container.read(remoteConfigProvider.notifier).refreshFromService();
    unawaited(service.refresh());
    await Future<void>.delayed(const Duration(seconds: 2));
    await container.read(adManagerProvider).warmUp();
  } catch (e) {
    debugPrint('ads start: $e');
  }
}

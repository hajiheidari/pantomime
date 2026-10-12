import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers.dart';
import '../../core/store/store_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/cartoon.dart';
import '../ads/ads_providers.dart';
import '../ads/config/remote_config.dart';
import '../game/domain/game_config.dart';
import '../game/presentation/setup_screen.dart';
import '../recording/recording_offer.dart';
import '../settings/settings_screen.dart';
import '../share/share_link.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    return Scaffold(
      body: DecoratedBox(
        decoration: appBackground,
        child: SafeArea(
          child: FillOrScroll(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                // Hidden with ?screenshot=1 (store screenshots of the web build).
                if (kIsWeb && Uri.base.queryParameters['screenshot'] != '1')
                  const _InstallBar(),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: IconButton(
                    tooltip: s.settings,
                    iconSize: 32,
                    icon: const Icon(Icons.settings_rounded),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    ),
                  ),
                ),
                const Spacer(),
                const BouncyEmoji.widget(AppLogo(size: 110)),
                const SizedBox(height: 8),
                Text(
                  s.appName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                    color: AppColors.yellow,
                    shadows: [
                      Shadow(color: AppColors.outline, offset: Offset(0, 4)),
                    ],
                  ),
                ),
                Text(
                  s.tagline,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                PopIn(
                  child: CartoonButton(
                    label: s.classicGame,
                    subtitle: s.classicGameHint,
                    icon: '👥',
                    height: 90,
                    fontSize: 28,
                    color: AppColors.yellow,
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            const SetupScreen(mode: GameMode.classic),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                PopIn(
                  delay: const Duration(milliseconds: 80),
                  child: CartoonButton(
                    label: s.teamGame,
                    subtitle: s.teamGameHint,
                    icon: '⚡',
                    height: 90,
                    fontSize: 28,
                    color: AppColors.orange,
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const SetupScreen(mode: GameMode.teams),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                PopIn(
                  delay: const Duration(milliseconds: 160),
                  child: CartoonButton(
                    label: s.foreheadMode,
                    subtitle: s.foreheadModeHint,
                    icon: '🤳',
                    height: 90,
                    fontSize: 28,
                    color: AppColors.pink,
                    onPressed: () async {
                      await offerRecordingOnce(context, ref);
                      if (!context.mounted) return;
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              const SetupScreen(mode: GameMode.forehead),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                const _Notice(),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Web game only: leads to the app page, where every store is listed.
class _InstallBar extends ConsumerWidget {
  const _InstallBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: GestureDetector(
        onTap: () => launchUrl(
          Uri.parse(appPageLink(s.languageCode)),
          webOnlyWindowName: '_blank',
        ),
        child: CartoonCard(
          color: AppColors.green,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              const Text('📲', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  s.installApp,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
              ),
              const Icon(Icons.open_in_new_rounded, color: AppColors.ink),
            ],
          ),
        ),
      ),
    );
  }
}

final _appVersionProvider = FutureProvider<String>(
  (ref) async => (await PackageInfo.fromPlatform()).version,
);

/// Optional message from remote config, or an "update available" hint when
/// this version is older than `min_supported_version`. Never blocks.
class _Notice extends ConsumerWidget {
  const _Notice();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final config = ref.watch(remoteConfigProvider);
    final version = ref.watch(_appVersionProvider).value;
    final outdated =
        version != null &&
        compareVersions(version, config.minSupportedVersion) < 0;
    final text = config.message ?? (outdated ? s.updateAvailable : null);
    if (text == null) return const SizedBox.shrink();
    final card = CartoonCard(
      color: AppColors.yellow,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Text(outdated ? '⬆️' : '📣', style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
    if (!outdated) return card;
    return GestureDetector(
      onTap: () => ref.read(storeServiceProvider).openDetails(),
      child: card,
    );
  }
}

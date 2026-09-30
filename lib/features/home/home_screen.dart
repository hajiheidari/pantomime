import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/cartoon.dart';
import '../game/domain/game_config.dart';
import '../game/presentation/setup_screen.dart';
import '../settings/settings_screen.dart';

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
                const BouncyEmoji('🎭', size: 96),
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
                    label: s.teamGame,
                    subtitle: s.teamGameHint,
                    icon: '👥',
                    height: 96,
                    fontSize: 28,
                    color: AppColors.yellow,
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const SetupScreen(mode: GameMode.teams),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                PopIn(
                  delay: const Duration(milliseconds: 120),
                  child: CartoonButton(
                    label: s.foreheadMode,
                    subtitle: s.foreheadModeHint,
                    icon: '🤳',
                    height: 96,
                    fontSize: 28,
                    color: AppColors.pink,
                    // Forehead mode arrives in M2.
                    onPressed: () => ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(SnackBar(content: Text(s.comingSoon))),
                  ),
                ),
                const Spacer(),
                // Reserved for the small home banner ad (M3).
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

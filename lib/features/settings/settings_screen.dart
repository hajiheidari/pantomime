import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/cartoon.dart';
import '../../core/store/store_service.dart';
import '../recording/recording_offer.dart';
import '../gamecenter/game_center.dart';
import 'settings_controller.dart';

/// Privacy policy page (espadna.com redirects it to the config Worker's
/// `/privacy`, server/src/privacy.js). Override with --dart-define=PRIVACY_URL=….
const privacyPolicyUrl = String.fromEnvironment(
  'PRIVACY_URL',
  defaultValue: 'https://espadna.com/pantomime-app/privacy',
);

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final settings = ref.watch(settingsProvider);
    final ctrl = ref.read(settingsProvider.notifier);

    Widget toggle(
      String emoji,
      String title,
      bool value,
      ValueChanged<bool>? onChanged, {
      String? subtitle,
    }) {
      return _Row(
        emoji: emoji,
        title: title,
        subtitle: subtitle,
        trailing: Switch(value: value, onChanged: onChanged),
        onTap: onChanged == null ? null : () => onChanged(!value),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(s.settings)),
      extendBodyBehindAppBar: true,
      body: DecoratedBox(
        decoration: appBackground,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              CartoonCard(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  children: [
                    toggle('🔊', s.sound, settings.soundOn, ctrl.setSound),
                    // Browsers: no haptics through Flutter, and recording
                    // is unreliable (spec 9c), so both are app-only.
                    if (!kIsWeb) ...[
                      const _Divider(),
                      toggle(
                        '📳',
                        s.vibration,
                        settings.vibrationOn,
                        ctrl.setVibration,
                      ),
                      const _Divider(),
                      toggle(
                        '🎥',
                        s.recording,
                        settings.recordingOn,
                        (on) => _setRecording(context, ref, on),
                        subtitle: s.recordingHint,
                      ),
                    ],
                  ],
                ),
              ),
              SectionTitle(s.language),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final l in AppLanguage.values)
                    CartoonChip(
                      label: switch (l) {
                        AppLanguage.fa => 'فارسی',
                        AppLanguage.en => 'English',
                        AppLanguage.ar => 'العربية',
                        AppLanguage.ru => 'Русский',
                        AppLanguage.tr => 'Türkçe',
                      },
                      selected: ref.watch(languageCodeProvider) == l.name,
                      onTap: () => ctrl.setLanguage(l),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              CartoonCard(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  children: [
                    if (ref.read(gameCenterProvider).enabled) ...[
                      _Row(
                        emoji: '🏆',
                        title: s.leaderboards,
                        onTap: () => ref.read(gameCenterProvider).show(),
                      ),
                      const _Divider(),
                    ],
                    if (!kIsWeb) ...[
                      _Row(
                        emoji: '⭐',
                        title: s.rateApp,
                        onTap: () =>
                            ref.read(storeServiceProvider).openRating(),
                      ),
                      const _Divider(),
                    ],
                    _Row(
                      emoji: '🔒',
                      title: s.privacyPolicy,
                      onTap: () => _info(
                        context,
                        s.privacyPolicy,
                        '${s.privacyBody}\n\n$privacyPolicyUrl',
                        s.close,
                      ),
                    ),
                    const _Divider(),
                    _Row(
                      emoji: '🎭',
                      title: s.about,
                      onTap: () =>
                          _info(context, s.about, s.aboutBody, s.close),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Recording is off by default. Turning it on explains why camera and
  /// microphone are needed, then lets the OS ask for permission.
  Future<void> _setRecording(
    BuildContext context,
    WidgetRef ref,
    bool on,
  ) async {
    final ctrl = ref.read(settingsProvider.notifier);
    if (!on) {
      ctrl.setRecording(false);
      return;
    }
    await askToEnableRecording(context, ref);
  }

  void _info(BuildContext context, String title, String body, String close) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(body)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              close,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: AppColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.emoji,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final String emoji;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.ink.withValues(alpha: 0.6),
                    ),
                  ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    ),
  );
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) => Divider(
    height: 1,
    indent: 16,
    endIndent: 16,
    color: AppColors.ink.withValues(alpha: 0.12),
  );
}

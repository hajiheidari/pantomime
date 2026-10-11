import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../settings/settings_controller.dart';
import 'round_recorder.dart';

const _offeredKey = 'recording.offered';

/// Explains recording (camera + microphone, videos stay on the phone) and,
/// if the player agrees, lets the OS ask for permission and turns it on.
/// Returns whether recording is on afterwards.
Future<bool> askToEnableRecording(
  BuildContext context,
  WidgetRef ref, {
  bool firstTime = false,
}) async {
  final s = ref.read(stringsProvider);
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(s.recordingExplainTitle),
      content: Text(s.recordingExplainBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            firstTime ? s.notNow : s.cancel,
            style: const TextStyle(color: AppColors.ink),
          ),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.green,
            foregroundColor: AppColors.ink,
          ),
          onPressed: () => Navigator.pop(context, true),
          child: Text(
            s.allow,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      ],
    ),
  );
  if (ok != true) return false;
  // Opening the camera triggers the OS camera + microphone prompts.
  final recorder = ref.read(roundRecorderFactoryProvider)();
  final granted = await recorder.prepare();
  await recorder.dispose();
  ref.read(settingsProvider.notifier).setRecording(granted);
  if (!granted && context.mounted) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(s.recordingDenied)));
  }
  return granted;
}

/// The first time forehead mode is picked (recording off, not on the web),
/// suggest turning recording on. Asked only once; settings can change it.
Future<void> offerRecordingOnce(BuildContext context, WidgetRef ref) async {
  if (kIsWeb || ref.read(settingsProvider).recordingOn) return;
  final prefs = ref.read(sharedPreferencesProvider);
  if (prefs.getBool(_offeredKey) ?? false) return;
  await prefs.setBool(_offeredKey, true);
  if (!context.mounted) return;
  await askToEnableRecording(context, ref, firstTime: true);
}

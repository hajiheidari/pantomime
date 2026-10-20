import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../settings/settings_controller.dart';
import 'round_recorder.dart';

const _offeredKey = 'recording.offered';

/// The player turned recording on: explains it (camera + microphone, videos
/// stay on the phone), then lets the OS ask for permission. App Review
/// (5.1.1): a message shown before a permission request has a single
/// "Continue" button that always leads to the request; the player decides
/// in the system prompt. Returns whether recording is on afterwards.
Future<bool> askToEnableRecording(BuildContext context, WidgetRef ref) async {
  final s = ref.read(stringsProvider);
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => PopScope(
      canPop: false,
      child: AlertDialog(
        title: Text(s.recordingExplainTitle),
        content: Text(s.recordingExplainBody),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.green,
              foregroundColor: AppColors.ink,
            ),
            onPressed: () => Navigator.pop(context),
            child: Text(
              s.continueLabel,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    ),
  );
  if (!context.mounted) return false;
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
/// mention that recording can be turned on in Settings. Shown once; it asks
/// for no permission.
Future<void> offerRecordingOnce(BuildContext context, WidgetRef ref) async {
  if (kIsWeb || ref.read(settingsProvider).recordingOn) return;
  final prefs = ref.read(sharedPreferencesProvider);
  if (prefs.getBool(_offeredKey) ?? false) return;
  await prefs.setBool(_offeredKey, true);
  if (!context.mounted) return;
  final s = ref.read(stringsProvider);
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(s.recordingExplainTitle),
      content: Text(s.recordingTip),
      actions: [
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.green,
            foregroundColor: AppColors.ink,
          ),
          onPressed: () => Navigator.pop(context),
          child: Text(
            s.gotIt,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      ],
    ),
  );
}

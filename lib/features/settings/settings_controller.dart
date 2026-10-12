import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';

enum AppLanguage { fa, en, ar, ru, tr }

class AppSettings {
  const AppSettings({
    this.soundOn = true,
    this.vibrationOn = true,
    this.recordingOn = false,
    this.language,
  });

  final bool soundOn;
  final bool vibrationOn;
  final bool recordingOn;

  /// The player's choice; null = automatic (see defaultLanguage).
  final AppLanguage? language;

  AppSettings copyWith({
    bool? soundOn,
    bool? vibrationOn,
    bool? recordingOn,
    AppLanguage? language,
  }) => AppSettings(
    soundOn: soundOn ?? this.soundOn,
    vibrationOn: vibrationOn ?? this.vibrationOn,
    recordingOn: recordingOn ?? this.recordingOn,
    language: language ?? this.language,
  );
}

final settingsProvider = NotifierProvider<SettingsController, AppSettings>(
  SettingsController.new,
);

class SettingsController extends Notifier<AppSettings> {
  static const _kSound = 'settings.sound';
  static const _kVibration = 'settings.vibration';
  static const _kRecording = 'settings.recording';
  static const _kLanguage = 'settings.language';

  @override
  AppSettings build() {
    final p = ref.watch(sharedPreferencesProvider);
    return AppSettings(
      soundOn: p.getBool(_kSound) ?? true,
      vibrationOn: p.getBool(_kVibration) ?? true,
      recordingOn: p.getBool(_kRecording) ?? false,
      language: AppLanguage.values
          .where((l) => l.name == p.getString(_kLanguage))
          .firstOrNull,
    );
  }

  void setSound(bool on) {
    state = state.copyWith(soundOn: on);
    ref.read(sharedPreferencesProvider).setBool(_kSound, on);
  }

  void setVibration(bool on) {
    state = state.copyWith(vibrationOn: on);
    ref.read(sharedPreferencesProvider).setBool(_kVibration, on);
  }

  void setRecording(bool on) {
    state = state.copyWith(recordingOn: on);
    ref.read(sharedPreferencesProvider).setBool(_kRecording, on);
  }

  void setLanguage(AppLanguage language) {
    state = state.copyWith(language: language);
    ref.read(sharedPreferencesProvider).setString(_kLanguage, language.name);
  }
}

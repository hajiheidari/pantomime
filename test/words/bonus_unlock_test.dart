import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantomime/core/providers.dart';
import 'package:pantomime/features/words/words_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('special categories open for 24 hours, across restarts', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    var now = DateTime(2026, 10, 12, 23, 0);
    ProviderContainer app() => ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        clockProvider.overrideWithValue(() => now),
      ],
    );

    final c = app();
    final bonus = c.read(bonusUnlockProvider.notifier);
    expect(bonus.isOpen, isFalse);
    bonus.openForADay();
    expect(bonus.isOpen, isTrue);
    expect(bonus.remaining, const Duration(hours: 24));

    // Restart the app 18 hours later: still open, 6 hours left.
    now = now.add(const Duration(hours: 18));
    final again = app().read(bonusUnlockProvider.notifier);
    expect(again.remaining, const Duration(hours: 6));

    // A day later: closed.
    now = now.add(const Duration(hours: 7));
    expect(app().read(bonusUnlockProvider.notifier).isOpen, isFalse);
  });
}

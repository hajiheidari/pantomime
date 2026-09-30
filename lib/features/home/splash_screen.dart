import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/cartoon.dart';
import '../words/domain/word_models.dart';
import '../words/words_providers.dart';
import 'home_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Warm up the word pack while the logo shows; never wait more than ~1.6s.
    Future.wait([
          ref
              .read(wordCategoriesProvider.future)
              .catchError((_) => const <WordCategory>[]),
          Future<void>.delayed(const Duration(milliseconds: 1400)),
        ])
        .timeout(const Duration(milliseconds: 1600), onTimeout: () => [])
        .then((_) {
          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 400),
              pageBuilder: (_, _, _) => const HomeScreen(),
              transitionsBuilder: (_, a, _, child) =>
                  FadeTransition(opacity: a, child: child),
            ),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    return Scaffold(
      body: DecoratedBox(
        decoration: appBackground,
        child: Center(
          child: PopIn(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const BouncyEmoji('🎭', size: 110),
                const SizedBox(height: 16),
                Text(
                  s.appName,
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: AppColors.yellow,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

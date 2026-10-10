import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/tablet_scale.dart';
import 'features/home/splash_screen.dart';

class PantomimeApp extends ConsumerWidget {
  const PantomimeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
    return MaterialApp(
      title: strings.appName,
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      locale: Locale(strings.languageCode),
      supportedLocales: const [Locale('fa'), Locale('en'), Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => TabletScale(child: child!),
      home: const SplashScreen(),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/splash/presentation/pages/splash_screen.dart';

void main() {
  runApp(const ProviderScope(child: FindStackApp()));
}

class FindStackApp extends StatelessWidget {
  const FindStackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FindStack',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const SplashScreen(),
    );
  }
}

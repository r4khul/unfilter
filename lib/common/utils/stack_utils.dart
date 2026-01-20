library;

import 'package:flutter/material.dart';

Color getStackColor(String stack, bool isDark) {
  switch (stack.toLowerCase()) {
    case 'flutter':
      return isDark ? const Color(0xFF5CACEE) : const Color(0xFF1E88E5);
    case 'react native':
      return isDark ? const Color(0xFF61DAFB) : const Color(0xFF00ACC1);
    case 'kotlin':
      return isDark ? const Color(0xFFB388FF) : const Color(0xFF7C4DFF);
    case 'jetpack compose':
    case 'jetpack':
      return isDark ? const Color(0xFF42D08D) : const Color(0xFF00C853);
    case 'java':
      return isDark ? const Color(0xFFEF9A9A) : const Color(0xFFE53935);
    case 'pwa':
      return isDark ? const Color(0xFFB39DDB) : const Color(0xFF7E57C2);
    case 'ionic':
      return isDark ? const Color(0xFF90CAF9) : const Color(0xFF42A5F5);
    case 'cordova':
      return isDark ? const Color(0xFFB0BEC5) : const Color(0xFF78909C);
    case 'xamarin':
      return isDark ? const Color(0xFF81D4FA) : const Color(0xFF29B6F6);
    case 'nativescript':
      return isDark ? const Color(0xFF80CBC4) : const Color(0xFF26A69A);
    case 'unity':
      return isDark ? const Color(0xFFEDEDED) : const Color(0xFF424242);
    case 'godot':
      return isDark ? const Color(0xFF81D4FA) : const Color(0xFF039BE5);
    case 'corona':
      return isDark ? const Color(0xFFFFCC80) : const Color(0xFFEF6C00);
    default:
      return isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32);
  }
}

String getStackIconPath(String stack) {
  final stackLower = stack.toLowerCase();
  switch (stackLower) {
    case 'flutter':
      return 'assets/vectors/icon_flutter.svg';
    case 'react native':
      return 'assets/vectors/icon_react.svg';
    case 'kotlin':
      return 'assets/vectors/icon_kotlin.svg';
    case 'jetpack compose':
    case 'jetpack':
      return 'assets/vectors/icon_jetpack.svg';
    case 'java':
      return 'assets/vectors/icon_java.svg';
    case 'pwa':
      return 'assets/vectors/icon_pwa.svg';
    case 'ionic':
      return 'assets/vectors/icon_ionic.svg';
    case 'cordova':
      return 'assets/vectors/icon_cordova.svg';
    case 'xamarin':
      return 'assets/vectors/icon_xamarin.svg';
    case 'nativescript':
      return 'assets/vectors/icon_nativescript.svg';
    case 'unity':
      return 'assets/vectors/icon_unity.svg';
    case 'godot':
      return 'assets/vectors/icon_godot.svg';
    case 'corona':
      return 'assets/vectors/icon_corona.svg';
    default:
      return 'assets/vectors/icon_native.svg';
  }
}

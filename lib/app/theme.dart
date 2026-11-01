import 'package:flutter/material.dart';

ThemeData buildLightTheme() => ThemeData(
      useMaterial3: true,
      fontFamily: 'Inter',
      scaffoldBackgroundColor: const Color(0xFFF5F3FF),
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6257D9), brightness: Brightness.light, surface: const Color(0xFFF5F3FF)),
      cardTheme: CardThemeData(color: Colors.white.withValues(alpha: .68), surfaceTintColor: Colors.transparent, elevation: 0, margin: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22), side: const BorderSide(color: Color(0x66FFFFFF)))),
      navigationBarTheme: const NavigationBarThemeData(height: 78, backgroundColor: Colors.white, indicatorColor: Color(0xFFE9E6FF), labelTextStyle: WidgetStatePropertyAll(TextStyle(fontWeight: FontWeight.w700, fontSize: 11)),),
      inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: Colors.white.withValues(alpha: .9), contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
    );

ThemeData buildDarkTheme() => ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'Inter',
      scaffoldBackgroundColor: const Color(0xFF080B18),
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF7C6BFF), brightness: Brightness.dark, surface: const Color(0xFF080B18)),
      cardTheme: CardThemeData(color: const Color(0xFF172039).withValues(alpha: .68), surfaceTintColor: Colors.transparent, elevation: 0, margin: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22), side: const BorderSide(color: Color(0x334F6190)))),
      navigationBarTheme: const NavigationBarThemeData(height: 78, backgroundColor: Color(0xCC0D1325), indicatorColor: Color(0x664F3DCC), labelTextStyle: WidgetStatePropertyAll(TextStyle(fontWeight: FontWeight.w700, fontSize: 11)),),
      inputDecorationTheme: const InputDecorationTheme(filled: true, fillColor: Color(0x66172039), contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 16), border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(16)), borderSide: BorderSide(color: Color(0x334F6190)))),
    );

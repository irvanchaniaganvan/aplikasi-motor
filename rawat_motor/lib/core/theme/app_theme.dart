import 'package:flutter/material.dart';

const ink = Color(0xFF20352C);
const green = Color(0xFF286348);
const cream = Color(0xFFF5F2EB);
const muted = Color(0xFF68756E);
const line = Color(0xFFE6E8E2);
const danger = Color(0xFF9B3D31);
const warning = Color(0xFF94651C);
const sage = Color(0xFFE4EBDD);
const pale = Color(0xFFFBFAF6);
const surfaceSoft = Color(0xFFF4F6F1);
const dangerSoft = Color(0xFFF8E7E2);
const warningSoft = Color(0xFFFBF1DD);
const safeSoft = Color(0xFFEAF0E4);

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: cream,
    colorScheme: ColorScheme.fromSeed(
      seedColor: green,
      primary: green,
      surface: pale,
      error: danger,
    ),
    fontFamily: 'Roboto',
    textTheme: const TextTheme(
      headlineSmall: TextStyle(
        color: ink,
        fontSize: 28,
        height: 1.15,
        fontWeight: FontWeight.w800,
      ),
      titleLarge: TextStyle(
        color: ink,
        fontSize: 19,
        height: 1.25,
        fontWeight: FontWeight.w800,
      ),
      titleMedium: TextStyle(
        color: ink,
        fontSize: 15,
        height: 1.35,
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: TextStyle(color: ink, fontSize: 14, height: 1.5),
      bodyMedium: TextStyle(color: ink, fontSize: 13, height: 1.45),
      bodySmall: TextStyle(color: muted, fontSize: 12, height: 1.45),
      labelSmall: TextStyle(
        color: muted,
        fontSize: 10,
        letterSpacing: 1.1,
        fontWeight: FontWeight.w800,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: pale,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: green, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: danger, width: 1.5),
      ),
      labelStyle: const TextStyle(color: muted, fontSize: 13),
      hintStyle: const TextStyle(color: muted, fontSize: 13),
      errorStyle: const TextStyle(fontSize: 12),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(0, 50)),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 18),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        backgroundColor: const WidgetStatePropertyAll(green),
        foregroundColor: const WidgetStatePropertyAll(Colors.white),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(0, 46)),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 16),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        side: const WidgetStatePropertyAll(BorderSide(color: line)),
        foregroundColor: const WidgetStatePropertyAll(green),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(0, 42)),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 12),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        foregroundColor: const WidgetStatePropertyAll(green),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 68,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      indicatorColor: sage,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          color: selected ? green : muted,
          fontSize: 11,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(color: selected ? green : muted, size: 22);
      }),
    ),
    dividerTheme: const DividerThemeData(color: line, thickness: 1, space: 1),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}

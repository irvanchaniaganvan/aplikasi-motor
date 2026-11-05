import 'package:flutter/material.dart';

import 'app_tokens.dart';

export 'app_tokens.dart';

// Alias lama dipertahankan agar widget yang belum sempat disentuh tetap
// memakai token terpusat, bukan warna mentah. Widget baru sebaiknya langsung
// memakai AppPalette atau RawatinColors.of(context).
const ink = AppPalette.ink;
const inkSoft = AppPalette.inkSoft;
const green = AppPalette.primary;
const cream = AppPalette.canvas;
const muted = AppPalette.muted;
const line = AppPalette.line;
const danger = AppPalette.due;
const warning = AppPalette.soon;
const sage = AppPalette.primarySoft;
const pale = AppPalette.surface;
const surface = AppPalette.surface;
const surfaceSoft = AppPalette.surfaceSoft;
const dangerSoft = AppPalette.dueSoft;
const warningSoft = AppPalette.soonSoft;
const safeSoft = AppPalette.safeSoft;
const primary = AppPalette.primary;
const primarySoft = AppPalette.primarySoft;
const accent = AppPalette.accent;
const white = AppPalette.white;

/// Warna semantik yang bisa berganti saat dark mode ditambahkan.
///
/// Widget mengambil warna status lewat [RawatinColors.of] sehingga nanti
/// cukup menyiapkan satu varian gelap tanpa menyentuh widget satu per satu.
@immutable
class RawatinColors extends ThemeExtension<RawatinColors> {
  const RawatinColors({
    required this.primary,
    required this.primaryDark,
    required this.primarySoft,
    required this.accent,
    required this.accentSoft,
    required this.onAccent,
    required this.ink,
    required this.inkSoft,
    required this.muted,
    required this.canvas,
    required this.surface,
    required this.surfaceSoft,
    required this.line,
    required this.safe,
    required this.safeSoft,
    required this.soon,
    required this.soonSoft,
    required this.due,
    required this.dueSoft,
    required this.check,
    required this.checkSoft,
    required this.white,
    required this.shadow,
    required this.checkered,
  });

  final Color primary;
  final Color primaryDark;
  final Color primarySoft;
  final Color accent;
  final Color accentSoft;
  final Color onAccent;
  final Color ink;
  final Color inkSoft;
  final Color muted;
  final Color canvas;
  final Color surface;
  final Color surfaceSoft;
  final Color line;
  final Color safe;
  final Color safeSoft;
  final Color soon;
  final Color soonSoft;
  final Color due;
  final Color dueSoft;
  final Color check;
  final Color checkSoft;
  final Color white;
  final Color shadow;
  final Color checkered;

  static const light = RawatinColors(
    primary: AppPalette.primary,
    primaryDark: AppPalette.primaryDark,
    primarySoft: AppPalette.primarySoft,
    accent: AppPalette.accent,
    accentSoft: AppPalette.accentSoft,
    onAccent: AppPalette.onAccent,
    ink: AppPalette.ink,
    inkSoft: AppPalette.inkSoft,
    muted: AppPalette.muted,
    canvas: AppPalette.canvas,
    surface: AppPalette.surface,
    surfaceSoft: AppPalette.surfaceSoft,
    line: AppPalette.line,
    safe: AppPalette.safe,
    safeSoft: AppPalette.safeSoft,
    soon: AppPalette.soon,
    soonSoft: AppPalette.soonSoft,
    due: AppPalette.due,
    dueSoft: AppPalette.dueSoft,
    check: AppPalette.check,
    checkSoft: AppPalette.checkSoft,
    white: AppPalette.white,
    shadow: AppPalette.shadow,
    checkered: AppPalette.checkered,
  );

  static RawatinColors of(BuildContext context) =>
      Theme.of(context).extension<RawatinColors>() ?? light;

  @override
  RawatinColors copyWith({
    Color? primary,
    Color? primaryDark,
    Color? primarySoft,
    Color? accent,
    Color? accentSoft,
    Color? onAccent,
    Color? ink,
    Color? inkSoft,
    Color? muted,
    Color? canvas,
    Color? surface,
    Color? surfaceSoft,
    Color? line,
    Color? safe,
    Color? safeSoft,
    Color? soon,
    Color? soonSoft,
    Color? due,
    Color? dueSoft,
    Color? check,
    Color? checkSoft,
    Color? white,
    Color? shadow,
    Color? checkered,
  }) => RawatinColors(
    primary: primary ?? this.primary,
    primaryDark: primaryDark ?? this.primaryDark,
    primarySoft: primarySoft ?? this.primarySoft,
    accent: accent ?? this.accent,
    accentSoft: accentSoft ?? this.accentSoft,
    onAccent: onAccent ?? this.onAccent,
    ink: ink ?? this.ink,
    inkSoft: inkSoft ?? this.inkSoft,
    muted: muted ?? this.muted,
    canvas: canvas ?? this.canvas,
    surface: surface ?? this.surface,
    surfaceSoft: surfaceSoft ?? this.surfaceSoft,
    line: line ?? this.line,
    safe: safe ?? this.safe,
    safeSoft: safeSoft ?? this.safeSoft,
    soon: soon ?? this.soon,
    soonSoft: soonSoft ?? this.soonSoft,
    due: due ?? this.due,
    dueSoft: dueSoft ?? this.dueSoft,
    check: check ?? this.check,
    checkSoft: checkSoft ?? this.checkSoft,
    white: white ?? this.white,
    shadow: shadow ?? this.shadow,
    checkered: checkered ?? this.checkered,
  );

  @override
  RawatinColors lerp(ThemeExtension<RawatinColors>? other, double t) {
    if (other is! RawatinColors) return this;
    return RawatinColors(
      primary: Color.lerp(primary, other.primary, t)!,
      primaryDark: Color.lerp(primaryDark, other.primaryDark, t)!,
      primarySoft: Color.lerp(primarySoft, other.primarySoft, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      inkSoft: Color.lerp(inkSoft, other.inkSoft, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      canvas: Color.lerp(canvas, other.canvas, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceSoft: Color.lerp(surfaceSoft, other.surfaceSoft, t)!,
      line: Color.lerp(line, other.line, t)!,
      safe: Color.lerp(safe, other.safe, t)!,
      safeSoft: Color.lerp(safeSoft, other.safeSoft, t)!,
      soon: Color.lerp(soon, other.soon, t)!,
      soonSoft: Color.lerp(soonSoft, other.soonSoft, t)!,
      due: Color.lerp(due, other.due, t)!,
      dueSoft: Color.lerp(dueSoft, other.dueSoft, t)!,
      check: Color.lerp(check, other.check, t)!,
      checkSoft: Color.lerp(checkSoft, other.checkSoft, t)!,
      white: Color.lerp(white, other.white, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      checkered: Color.lerp(checkered, other.checkered, t)!,
    );
  }
}

ThemeData buildAppTheme({
  RawatinColors colors = RawatinColors.light,
  Brightness brightness = Brightness.light,
}) {
  final scheme = ColorScheme.fromSeed(
    seedColor: colors.primary,
    brightness: brightness,
    primary: colors.primary,
    onPrimary: colors.white,
    secondary: colors.accent,
    onSecondary: colors.onAccent,
    surface: colors.surface,
    onSurface: colors.ink,
    error: colors.due,
    outline: colors.line,
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    brightness: brightness,
    scaffoldBackgroundColor: colors.canvas,
    fontFamily: bodyFontFamily,
    splashFactory: InkSparkle.splashFactory,
    visualDensity: VisualDensity.standard,
    extensions: [colors],
  );

  final textTheme = base.textTheme.copyWith(
    displayLarge: AppType.km.copyWith(color: colors.ink),
    displayMedium: AppType.km.copyWith(fontSize: 44, color: colors.ink),
    displaySmall: AppType.km.copyWith(fontSize: 34, color: colors.ink),
    headlineLarge: TextStyle(
      fontFamily: bodyFontFamily,
      color: colors.ink,
      fontSize: 28,
      height: 1.15,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
    ),
    headlineMedium: TextStyle(
      fontFamily: bodyFontFamily,
      color: colors.ink,
      fontSize: 24,
      height: 1.2,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2,
    ),
    headlineSmall: TextStyle(
      fontFamily: bodyFontFamily,
      color: colors.ink,
      fontSize: 20,
      height: 1.2,
      fontWeight: FontWeight.w700,
    ),
    titleLarge: TextStyle(
      fontFamily: bodyFontFamily,
      color: colors.ink,
      fontSize: 18,
      height: 1.25,
      fontWeight: FontWeight.w700,
    ),
    titleMedium: TextStyle(
      fontFamily: bodyFontFamily,
      color: colors.ink,
      fontSize: 16,
      height: 1.25,
      fontWeight: FontWeight.w600,
    ),
    titleSmall: TextStyle(
      fontFamily: bodyFontFamily,
      color: colors.ink,
      fontSize: 14,
      height: 1.25,
      fontWeight: FontWeight.w600,
    ),
    bodyLarge: TextStyle(color: colors.ink, fontSize: 15, height: 1.5),
    bodyMedium: TextStyle(color: colors.ink, fontSize: 13.5, height: 1.45),
    bodySmall: TextStyle(color: colors.muted, fontSize: 12, height: 1.4),
    labelLarge: AppType.button.copyWith(color: colors.ink),
    labelMedium: TextStyle(
      fontFamily: bodyFontFamily,
      color: colors.inkSoft,
      fontSize: 12,
      height: 1.2,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.3,
    ),
    labelSmall: AppType.eyebrow.copyWith(color: colors.muted),
  );

  return base.copyWith(
    textTheme: textTheme,
    iconTheme: IconThemeData(color: colors.inkSoft, size: 22),
    dividerTheme: DividerThemeData(color: colors.line, thickness: 1, space: 1),
    appBarTheme: AppBarTheme(
      backgroundColor: colors.surface,
      foregroundColor: colors.ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: colors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        side: BorderSide(color: colors.line),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colors.surface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: 15,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        borderSide: BorderSide(color: colors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        borderSide: BorderSide(color: colors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        borderSide: BorderSide(color: colors.primary, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        borderSide: BorderSide(color: colors.due),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        borderSide: BorderSide(color: colors.due, width: 1.6),
      ),
      labelStyle: TextStyle(color: colors.muted, fontSize: 13),
      hintStyle: TextStyle(color: colors.muted, fontSize: 13),
      errorStyle: TextStyle(color: colors.due, fontSize: 12),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(0, 48)),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
        ),
        textStyle: const WidgetStatePropertyAll(AppType.button),
        backgroundColor: WidgetStatePropertyAll(colors.primary),
        foregroundColor: WidgetStatePropertyAll(colors.white),
        overlayColor: WidgetStatePropertyAll(
          colors.white.withValues(alpha: 0.12),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(0, 42)),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
        ),
        side: WidgetStatePropertyAll(BorderSide(color: colors.line)),
        foregroundColor: WidgetStatePropertyAll(colors.primaryDark),
        textStyle: const WidgetStatePropertyAll(AppType.button),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(0, 38)),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: AppSpacing.md),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.sm),
          ),
        ),
        foregroundColor: WidgetStatePropertyAll(colors.primaryDark),
        textStyle: WidgetStatePropertyAll(
          AppType.button.copyWith(fontSize: 13),
        ),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 68,
      backgroundColor: colors.surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: colors.primarySoft,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontFamily: displayFontFamily,
          color: selected ? colors.primaryDark : colors.muted,
          fontSize: 12,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          letterSpacing: 0.3,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? colors.primary : colors.muted,
          size: 23,
        );
      }),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: colors.surface,
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: colors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: colors.ink,
      contentTextStyle: TextStyle(color: colors.white, fontSize: 13),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: colors.primary,
      linearTrackColor: colors.line,
      circularTrackColor: colors.line,
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: colors.surfaceSoft,
      side: BorderSide(color: colors.line),
      labelStyle: TextStyle(
        fontFamily: displayFontFamily,
        color: colors.inkSoft,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

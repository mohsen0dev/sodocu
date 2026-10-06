import 'package:flutter/material.dart';

import 'sudoku_colors.dart';

/// تم سراسری سودوکو.
///
/// فقط ظاهر کامپوننت‌ها (شکل، فاصله، سطح رنگ) را یکدست می‌کند؛
/// هیچ رنگ/رفتار مربوط به خودِ بازی (بوردر نارنجی، بوردر سبز
/// اعتبارسنجی فوری، هایلایت‌ها) از اینجا عبور نمی‌کند.
abstract final class SudokuAppTheme {
  /// تم پیش‌فرض (تیره) — همان حالتی که اپ با آن اجرا می‌شود.
  static ThemeData get dark => _build(Brightness.dark);

  /// تم روشن؛ برای محیط‌هایی که `ThemeMode.light` انتخاب می‌شود.
  static ThemeData get light => _build(Brightness.light);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: SudokuColors.primary,
      brightness: brightness,
    );

    // پس‌زمینهٔ اسکفولد در حالت تیره کمی آبی‌فام تا سطح‌ها از هم
    // تفکیک شوند (به‌جای مشکی خالص).
    final scaffoldBg = isDark ? const Color(0xFF0E131C) : scheme.surface;

    const radiusMd = 12.0;
    const radiusLg = 16.0;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffoldBg,
      splashFactory: InkSparkle.splashFactory,

      // ── سربرگ ──
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: scaffoldBg,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
          color: scheme.onSurface,
        ),
        iconTheme: IconThemeData(color: scheme.onSurfaceVariant),
      ),

      // ── کارت‌ها ──
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: scheme.surfaceContainerHigh.withValues(alpha: isDark ? 0.55 : 1),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),

      // ── دیالوگ‌ها ──
      dialogTheme: DialogThemeData(
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        backgroundColor: isDark ? const Color(0xFF1A2130) : scheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
        contentTextStyle: TextStyle(
          fontSize: 14.5,
          height: 1.5,
          color: scheme.onSurfaceVariant,
        ),
      ),

      // ── شیت‌های پایینی ──
      bottomSheetTheme: BottomSheetThemeData(
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        backgroundColor: isDark ? const Color(0xFF151B28) : scheme.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),

      // ── دکمه‌ها ──
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          side: BorderSide(color: scheme.outline),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),

      // ── فهرست‌ها و جداکننده‌ها ──
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),

      // ── بازخوردها ──
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 2,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: TextStyle(color: scheme.onInverseSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(4),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: scheme.inverseSurface,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: TextStyle(color: scheme.onInverseSurface, fontSize: 12),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: scheme.primary,
        selectionColor: scheme.primary.withValues(alpha: 0.35),
        selectionHandleColor: scheme.primary,
      ),
    );
  }
}

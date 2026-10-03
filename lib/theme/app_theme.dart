import 'package:flutter/material.dart';
import 'package:sodocu/theme/app_fonts.dart';

import 'app_radii.dart';
import 'sudoku_colors.dart';

/// Light theme for the app.
ThemeData get lightTheme => ThemeData(
  useMaterial3: true,
  fontFamily: AppFonts.vazirmatn,
  brightness: Brightness.light,
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.blue,
    brightness: Brightness.light,
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(),
    bodyMedium: TextStyle(),
    bodySmall: TextStyle(),
    headlineSmall: TextStyle(),
    labelMedium: TextStyle(),
  ),
  extensions: const [SudokuColors.light],
  appBarTheme: AppBarTheme(
    centerTitle: true,
    elevation: 0,
    backgroundColor: ColorScheme.fromSeed(seedColor: Colors.blue).surface,
    foregroundColor: ColorScheme.fromSeed(seedColor: Colors.blue).onSurface,
    titleTextStyle: const TextStyle(
      fontWeight: FontWeight.w700,
      fontSize: 20,
      height: 1.2,
    ),
  ),
  cardTheme: CardThemeData(
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.card),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      padding: EdgeInsets.symmetric(
        vertical: AppRadii.medium,
        horizontal: AppRadii.medium,
      ),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      padding: EdgeInsets.symmetric(
        vertical: AppRadii.medium,
        horizontal: AppRadii.medium,
      ),
    ),
  ),
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: Colors.transparent,
    elevation: 0,
    shape: RoundedRectangleBorder(),
  ),
  dialogTheme: DialogThemeData(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.card),
    ),
  ),
  snackBarTheme: SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.card),
    ),
  ),
);

/// Dark theme for the app.
ThemeData get darkTheme => ThemeData(
  useMaterial3: true,
  fontFamily: AppFonts.vazirmatn,
  brightness: Brightness.dark,
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.blue,
    brightness: Brightness.dark,
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(),
    bodyMedium: TextStyle(),
    bodySmall: TextStyle(),
    headlineSmall: TextStyle(),
    labelMedium: TextStyle(),
  ),
  extensions: const [SudokuColors.dark],
  appBarTheme: AppBarTheme(
    centerTitle: true,
    elevation: 0,
    backgroundColor: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.dark,
    ).surface,
    foregroundColor: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.dark,
    ).onSurface,
    titleTextStyle: const TextStyle(
      fontWeight: FontWeight.w700,
      fontSize: 20,
      height: 1.2,
    ),
  ),
  cardTheme: CardThemeData(
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.card),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      padding: EdgeInsets.symmetric(
        vertical: AppRadii.medium,
        horizontal: AppRadii.medium,
      ),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      padding: EdgeInsets.symmetric(
        vertical: AppRadii.medium,
        horizontal: AppRadii.medium,
      ),
    ),
  ),
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: Colors.transparent,
    elevation: 0,
    shape: RoundedRectangleBorder(),
  ),
  dialogTheme: DialogThemeData(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.card),
    ),
  ),
  snackBarTheme: SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.card),
    ),
  ),
);

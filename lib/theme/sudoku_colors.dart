import 'package:flutter/material.dart';
import 'package:sodocu/home/game_types.dart';

/// Semantic color tokens for Sudoku app themes.
///
/// Use [SudokuColors.light] and [SudokuColors.dark] inside each
/// [ThemeData.extensions] list. Access these colors inside widgets
/// via [SudokuColors.of(context)].
class SudokuColors extends ThemeExtension<SudokuColors> {
  const SudokuColors({
    required this.gridLine,
    required this.boxLine,
    required this.boardBorder,
    required this.fixedText,
    required this.userText,
    required this.correctText,
    required this.wrongText,
    required this.completedText,
    required this.selectedCell,
    required this.selectedNumber,
    required this.peerHighlight,
    required this.sameNumber,
    required this.completedUnit,
    required this.success,
    required this.danger,
    required this.warning,
    required this.hint,
    required this.daily,
    required this.classic,
    required this.timed,
    required this.noHints,
    required this.record,
  });

  /// Light theme color tokens.
  static const SudokuColors light = SudokuColors(
    gridLine: Color(0x59000000),
    boxLine: Color(0x8C000000),
    boardBorder: Color(0x8C000000),
    fixedText: Color(0xFF6B7280),
    userText: Color(0xFF1E3A8A),
    correctText: Color(0xFF1D4ED8),
    wrongText: Color(0xFF991B1B),
    completedText: Color(0xFF9CA3AF),
    selectedCell: Color(0xFFBFDBFE),
    selectedNumber: Color(0xFF1E40AF),
    peerHighlight: Color(0xFFEFF6FF),
    sameNumber: Color(0xFFDBEAFE),
    completedUnit: Color(0xFF5EEAD4),
    success: Color(0xFF0F766E),
    danger: Color(0xFF7F1D1D),
    warning: Color(0xFF9A3412),
    hint: Color(0xFF92400E),
    daily: Color(0xFF0F766E),
    classic: Color(0xFF1E3A8A),
    timed: Color(0xFF9A3412),
    noHints: Color(0xFF6B21A8),
    record: Color(0xFFB45309),
  );

  /// Dark theme color tokens.
  static const SudokuColors dark = SudokuColors(
    gridLine: Color(0x66FFFFFF),
    boxLine: Color(0xB3FFFFFF),
    boardBorder: Color(0xB3FFFFFF),
    fixedText: Color(0xFFD1D5DB),
    userText: Color(0xFF7DD3FC),
    correctText: Color(0xFF93C5FD),
    wrongText: Color(0xFFFF78A9),
    completedText: Color(0xFF6B7280),
    selectedCell: Color(0x40FDE68A),
    selectedNumber: Color(0xFFFDE68A),
    peerHighlight: Color(0x33BFDBFE),
    sameNumber: Color(0x4093C5FD),
    completedUnit: Color(0xFF5EEAD4),
    success: Color(0xFF2DD4BF),
    danger: Color(0xFFFF78A9),
    warning: Color(0xFFFFB74D),
    hint: Color(0xFFFFD166),
    daily: Color(0xFF2DD4BF),
    classic: Color(0xFF7DD3FC),
    timed: Color(0xFFFFB74D),
    noHints: Color(0xFFC4B5FD),
    record: Color(0xFFFFD166),
  );

  final Color gridLine;
  final Color boxLine;
  final Color boardBorder;
  final Color fixedText;
  final Color userText;
  final Color correctText;
  final Color wrongText;
  final Color completedText;
  final Color selectedCell;
  final Color selectedNumber;
  final Color peerHighlight;
  final Color sameNumber;
  final Color completedUnit;
  final Color success;
  final Color danger;
  final Color warning;
  final Color hint;
  final Color daily;
  final Color classic;
  final Color timed;
  final Color noHints;
  final Color record;

  /// Resolve colors from a [BuildContext].
  ///
  /// اگر تمِ برنامه ثبت نشده باشد (مثلاً در ویجت‌تست‌هایی که با
  /// GetMaterialApp پیش‌فرض پمپ می‌شوند) به تم روشن برمی‌گردد.
  static SudokuColors of(BuildContext context) {
    return Theme.of(context).extension<SudokuColors>() ?? SudokuColors.light;
  }

  /// رنگ تم [mode] در این تم (برای نوارها و برچسب‌های حالت بازی).
  Color modeColor(GameMode mode) => switch (mode) {
    GameMode.classic => classic,
    GameMode.timed => timed,
    GameMode.noHints => noHints,
    GameMode.daily => daily,
    GameMode.record => record,
  };

  @override
  SudokuColors copyWith({
    Color? gridLine,
    Color? boxLine,
    Color? boardBorder,
    Color? fixedText,
    Color? userText,
    Color? correctText,
    Color? wrongText,
    Color? completedText,
    Color? selectedCell,
    Color? selectedNumber,
    Color? peerHighlight,
    Color? sameNumber,
    Color? completedUnit,
    Color? success,
    Color? danger,
    Color? warning,
    Color? hint,
    Color? daily,
    Color? classic,
    Color? timed,
    Color? noHints,
    Color? record,
  }) {
    return SudokuColors(
      gridLine: gridLine ?? this.gridLine,
      boxLine: boxLine ?? this.boxLine,
      boardBorder: boardBorder ?? this.boardBorder,
      fixedText: fixedText ?? this.fixedText,
      userText: userText ?? this.userText,
      correctText: correctText ?? this.correctText,
      wrongText: wrongText ?? this.wrongText,
      completedText: completedText ?? this.completedText,
      selectedCell: selectedCell ?? this.selectedCell,
      selectedNumber: selectedNumber ?? this.selectedNumber,
      peerHighlight: peerHighlight ?? this.peerHighlight,
      sameNumber: sameNumber ?? this.sameNumber,
      completedUnit: completedUnit ?? this.completedUnit,
      success: success ?? this.success,
      danger: danger ?? this.danger,
      warning: warning ?? this.warning,
      hint: hint ?? this.hint,
      daily: daily ?? this.daily,
      classic: classic ?? this.classic,
      timed: timed ?? this.timed,
      noHints: noHints ?? this.noHints,
      record: record ?? this.record,
    );
  }

  @override
  ThemeExtension<SudokuColors> lerp(
    covariant ThemeExtension<SudokuColors>? other,
    double t,
  ) {
    if (other is! SudokuColors) return this;
    return SudokuColors(
      gridLine: Color.lerp(gridLine, other.gridLine, t)!,
      boxLine: Color.lerp(boxLine, other.boxLine, t)!,
      boardBorder: Color.lerp(boardBorder, other.boardBorder, t)!,
      fixedText: Color.lerp(fixedText, other.fixedText, t)!,
      userText: Color.lerp(userText, other.userText, t)!,
      correctText: Color.lerp(correctText, other.correctText, t)!,
      wrongText: Color.lerp(wrongText, other.wrongText, t)!,
      completedText: Color.lerp(completedText, other.completedText, t)!,
      selectedCell: Color.lerp(selectedCell, other.selectedCell, t)!,
      selectedNumber: Color.lerp(selectedNumber, other.selectedNumber, t)!,
      peerHighlight: Color.lerp(peerHighlight, other.peerHighlight, t)!,
      sameNumber: Color.lerp(sameNumber, other.sameNumber, t)!,
      completedUnit: Color.lerp(completedUnit, other.completedUnit, t)!,
      success: Color.lerp(success, other.success, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      hint: Color.lerp(hint, other.hint, t)!,
      daily: Color.lerp(daily, other.daily, t)!,
      classic: Color.lerp(classic, other.classic, t)!,
      timed: Color.lerp(timed, other.timed, t)!,
      noHints: Color.lerp(noHints, other.noHints, t)!,
      record: Color.lerp(record, other.record, t)!,
    );
  }
}

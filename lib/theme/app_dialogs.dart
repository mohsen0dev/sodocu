import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'sudoku_colors.dart';

/// دیالوگ‌های تأیید یکدستِ سودوکو.
///
/// همهٔ دیالوگ‌های «بله/نه» اپ از همین تابع عبور می‌کنند تا شکل، فاصله و
/// رنگ دکمه‌ها یکسان باشد. متن دکمه‌ها را فراخواننده تعیین می‌کند (قرارداد
/// تستی: «حذف»، «پاک کردن» و …) و مدیریت `Get.back()` هم داخل `onConfirm`
/// فراخواننده می‌ماند تا رفتار قبلی عوض نشود.
void showConfirmDialog({
  required String title,
  required String message,
  required String confirmLabel,
  required VoidCallback onConfirm,
  String cancelLabel = 'انصراف',
  Color accent = SudokuColors.primary,
}) {
  final theme = Get.context?.theme ?? ThemeData(useMaterial3: true);
  final scheme = theme.colorScheme;

  Get.defaultDialog(
    title: title,
    titleStyle: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: accent,
    ),
    middleText: message,
    middleTextStyle: TextStyle(
      fontSize: 14.5,
      height: 1.5,
      color: scheme.onSurfaceVariant,
    ),
    textCancel: cancelLabel,
    textConfirm: confirmLabel,
    backgroundColor: theme.dialogTheme.backgroundColor ?? scheme.surface,
    radius: 24,
    buttonColor: accent,
    confirmTextColor: Colors.white,
    cancelTextColor: scheme.onSurfaceVariant,
    contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
    onConfirm: onConfirm,
  );
}

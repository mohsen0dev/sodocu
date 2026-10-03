import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sodocu/theme/app_radii.dart';
import 'package:sodocu/theme/app_sizes.dart';
import 'package:sodocu/theme/sudoku_colors.dart';

import '../home_controller.dart';
import 'board_animations.dart';

/// جدول اصلی سودوکو (۹ در ۹ با شبکهٔ پیوستهٔ کلاسیک).
///
/// - خطوط نازک بین خانه‌ها، خطوط ضخیم بین بلوک‌ها و قاب بیرونی همگی
///   با یک CustomPaint روی خانه‌ها کشیده می‌شوند تا پیوسته و یکدست باشند.
/// - هایلایت‌ها: خانهٔ انتخاب‌شده، هم‌خانه‌ها (ردیف/ستون/بلوک) و
///   خانه‌هایی با عدد یکسان.
///
/// [onCellTap] با مختصات `(row, col, globalPosition)` فراخوانی می‌شود
/// تا والد تصمیم بگیرد picker باز شود یا عدد مستقیماً ثبت شود.
class SudokuGrid extends StatelessWidget {
  const SudokuGrid({
    required this.controller,
    this.onCellTap,
    super.key,
  });

  final HomeController controller;

  /// callback برای لمس خانه‌های قابل ویرایش.
  /// [row] و [col] مختصات خانه و [globalPosition] موقعیت لمس روی صفحه.
  final void Function(int row, int col, Offset globalPosition)? onCellTap;

  @override
  Widget build(BuildContext context) {
    final colors = SudokuColors.of(context);
    final theme = Theme.of(context);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: AppSizes.maxBoardWidth),
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadii.board),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withValues(alpha: 0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.board),
            child: Stack(
            children: [
              Positioned.fill(
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 9,
                  ),
                  itemCount: 81,
                  itemBuilder: (context, index) {
                    final row = index ~/ 9;
                    final col = index % 9;

                    // خانه‌های ثابت (پازل اولیه)
                    if (controller.puzzle != null &&
                        controller.puzzle![row][col] != 0) {
                      return _FixedCell(
                        row: row,
                        col: col,
                        controller: controller,
                        colors: colors,
                      );
                    }

                    // خانه‌های قابل ویرایش
                    return _EditableCell(
                      row: row,
                      col: col,
                      controller: controller,
                      colors: colors,
                      onTap: onCellTap,
                    );
                  },
                ),
              ),
              // خطوط پیوستهٔ جدول (روی خانه‌ها؛ بدون تعامل با لمس)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _BoardLinesPainter(
                      gridLine: colors.gridLine,
                      boxLine: colors.boxLine,
                      boardBorder: colors.boardBorder,
                    ),
                  ),
                ),
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
//  رنگ‌های مشترک خانه‌ها (همه از توکن‌های تم)
// ---------------------------------------------------------------------------

/// رنگ پس‌زمینهٔ خانهٔ `[row],[col]` بر اساس انتخاب‌ها و هایلایت‌ها.
Color? _cellBackground(
  SudokuColors colors,
  HomeController controller,
  int row,
  int col,
) {
  final selectedRow = controller.selectedRow.value;
  final selectedCol = controller.selectedCol.value;
  final value = controller.cells[row][col].value;

  // عدد انتخاب‌شده در نوار اعداد (یا عدد خانهٔ انتخاب‌شده) پررنگ‌ترین هایلایت است.
  final int activeNumber;
  if (controller.selectedNumber.value != 0) {
    activeNumber = controller.selectedNumber.value;
  } else if (selectedRow != null && selectedCol != null) {
    activeNumber = controller.cells[selectedRow][selectedCol].value;
  } else {
    activeNumber = 0;
  }

  if (selectedRow != null && selectedCol != null) {
    if (row == selectedRow && col == selectedCol) {
      return colors.selectedCell;
    }
    if (value != 0 && value == activeNumber) {
      return colors.sameNumber;
    }
    final isPeer =
        row == selectedRow ||
        col == selectedCol ||
        (row ~/ 3 == selectedRow ~/ 3 && col ~/ 3 == selectedCol ~/ 3);
    if (isPeer) return colors.peerHighlight;
    return null;
  }

  if (value != 0 && value == activeNumber) {
    return colors.sameNumber;
  }
  return null;
}

/// رنگ عدد خانهٔ `[row],[col]` از توکن‌های تم.
Color _cellTextColor(
  BuildContext context,
  SudokuColors colors,
  HomeController controller,
  int row,
  int col,
) {
  final cell = controller.cells[row][col];
  final value = cell.value;
  if (value == 0) return Colors.transparent;
  if (controller.isNumberFullyPlaced(value)) return colors.completedText;
  if (cell.isFixed) return colors.fixedText;
  if (!controller.isActive.value && !controller.isRecordMode) {
    return colors.userText;
  }
  return controller.isCorrect(row, col, value)
      ? colors.correctText
      : colors.wrongText;
}

// ---------------------------------------------------------------------------
//  خانهٔ ثابت (پازل اولیه — قابل تغییر نیست)
// ---------------------------------------------------------------------------

class _FixedCell extends StatelessWidget {
  const _FixedCell({
    required this.row,
    required this.col,
    required this.controller,
    required this.colors,
  });

  final int row;
  final int col;
  final HomeController controller;
  final SudokuColors colors;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Obx(() {
        final cellValue = controller.cells[row][col].value;
        return AnimatedCellContainer(
          row: row,
          col: col,
          ctrl: controller,
          backgroundColor: _cellBackground(colors, controller, row, col),
          child: cellValue == 0
              ? null
              : Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: AnimatedBoardNumber(
                      number: cellValue,
                      celebratingNumber: controller.celebratingNumber.value,
                      celebrateRegion: controller.isCellCelebrating(row, col),
                      regionCelebrationToken:
                          controller.celebrationToken.value,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: _cellTextColor(
                        context,
                        colors,
                        controller,
                        row,
                        col,
                      ),
                    ),
                  ),
                ),
        );
      }),
    );
  }
}

// ---------------------------------------------------------------------------
//  خانهٔ قابل ویرایش
// ---------------------------------------------------------------------------

class _EditableCell extends StatelessWidget {
  const _EditableCell({
    required this.row,
    required this.col,
    required this.controller,
    required this.colors,
    this.onTap,
  });

  final int row;
  final int col;
  final HomeController controller;
  final SudokuColors colors;
  final void Function(int row, int col, Offset globalPosition)? onTap;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GestureDetector(
        key: ValueKey('cell-$row-$col'),
        onTapUp: (details) {
          controller.selectCell(row, col);
          if (controller.isShow.value) {
            // حالت ورود مستقیم؛ در حالت یادداشت فقط کاندیدا تغییر می‌کند.
            if (controller.noteMode.value) {
              controller.setCellNote(row, col);
            } else {
              controller.setCellValue(row, col);
              // اگر عدد به حداکثر استفاده رسید، انتخاب را بردار
              if (controller.selectedNumber.value != 0 &&
                  controller.numberUsage[controller.selectedNumber.value] ==
                      9) {
                controller.selectedNumber.value = 0;
              }
            }
          } else {
            onTap?.call(row, col, details.globalPosition);
          }
        },
        child: RepaintBoundary(
          child: Obx(() {
            final hasNotes = controller.cells[row][col].notes.isNotEmpty;
            final value = controller.cells[row][col].value;

            return AnimatedCellContainer(
              row: row,
              col: col,
              ctrl: controller,
              mistakeFlashToken: controller.mistakeFlashToken.value,
              isMistake: controller.isMistakeCell(row, col),
              backgroundColor: _cellBackground(colors, controller, row, col),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (value != 0)
                    Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: AnimatedBoardNumber(
                          number: value,
                          celebratingNumber:
                              controller.celebratingNumber.value,
                          celebrateRegion: controller.isCellCelebrating(
                            row,
                            col,
                          ),
                          regionCelebrationToken:
                              controller.celebrationToken.value,
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          color: _cellTextColor(
                            context,
                            colors,
                            controller,
                            row,
                            col,
                          ),
                        ),
                      ),
                    )
                  else if (hasNotes)
                    _buildNotesGrid(
                      context,
                      controller.cells[row][col].notes,
                    ),
                  if (hasNotes)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Tooltip(
                        message: 'حذف همه یادداشت‌ها',
                        child: InkWell(
                          onTap: () => controller.clearNotes(row, col),
                          child: Padding(
                            padding: const EdgeInsets.all(1),
                            child: Icon(
                              Icons.clear_all,
                              size: 13,
                              color: colors.danger,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildNotesGrid(BuildContext context, Set<int> notes) {
    return GridView.count(
      crossAxisCount: 3,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      children: List.generate(9, (index) {
        final number = index + 1;
        return Center(
          child: Text(
            notes.contains(number) ? number.toString() : '',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        );
      }),
    );
  }
}

// ---------------------------------------------------------------------------
//  خطوط پیوستهٔ جدول
// ---------------------------------------------------------------------------

/// خطوط نازک بین خانه‌ها، خطوط ضخیم بین بلوک‌ها و قاب بیرونی جدول.
class _BoardLinesPainter extends CustomPainter {
  const _BoardLinesPainter({
    required this.gridLine,
    required this.boxLine,
    required this.boardBorder,
  });

  final Color gridLine;
  final Color boxLine;
  final Color boardBorder;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / 9;

    final thin = Paint()
      ..color = gridLine
      ..strokeWidth = 1;
    final thick = Paint()
      ..color = boxLine
      ..strokeWidth = 2;

    // خطوط نازک داخلی (بین خانه‌های هر بلوک)
    for (var i = 1; i < 9; i++) {
      if (i % 3 == 0) continue;
      final p = i * cell;
      canvas.drawLine(Offset(p, 0), Offset(p, size.height), thin);
      canvas.drawLine(Offset(0, p), Offset(size.width, p), thin);
    }

    // خطوط ضخیم (مرز بلوک‌های ۳×۳)
    for (var i = 3; i <= 6; i += 3) {
      final p = i * cell;
      canvas.drawLine(Offset(p, 0), Offset(p, size.height), thick);
      canvas.drawLine(Offset(0, p), Offset(size.width, p), thick);
    }

    // قاب بیرونی (داخل مرز تا تمام ۲ پیکسل دیده شود)
    final outline = Paint()
      ..color = boardBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(1, 1, size.width - 2, size.height - 2),
        Radius.circular(AppRadii.board - 1),
      ),
      outline,
    );
  }

  @override
  bool shouldRepaint(_BoardLinesPainter oldDelegate) =>
      oldDelegate.gridLine != gridLine ||
      oldDelegate.boxLine != boxLine ||
      oldDelegate.boardBorder != boardBorder;
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../home_controller.dart';
import 'board_animations.dart';

/// جدول اصلی سودوکو (۹ بلوک ۳×۳).
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
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 460),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        itemCount: 9,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, bigIdx) {
          return Obx(() {
            return Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: controller.isActive.value
                      ? Colors.green
                      : Theme.of(context).colorScheme.outlineVariant,
                  width: 1.5,
                ),
              ),
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                ),
                itemCount: 9,
                itemBuilder: (context, smallIdx) {
                  final row = (bigIdx ~/ 3) * 3 + (smallIdx ~/ 3);
                  final col = (bigIdx % 3) * 3 + (smallIdx % 3);

                  // خانه‌های ثابت (پازل اولیه)
                  if (controller.puzzle != null &&
                      controller.puzzle![row][col] != 0) {
                    return _FixedCell(
                      row: row,
                      col: col,
                      controller: controller,
                    );
                  }

                  // خانه‌های قابل ویرایش
                  return _EditableCell(
                    row: row,
                    col: col,
                    controller: controller,
                    onTap: onCellTap,
                  );
                },
              ),
            );
          });
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
//  خانهٔ ثابت (پازل اولیه — قابل تغییر نیست)
// ---------------------------------------------------------------------------

class _FixedCell extends StatelessWidget {
  const _FixedCell({
    required this.row,
    required this.col,
    required this.controller,
  });

  final int row;
  final int col;
  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Obx(() {
        final cellValue = controller.cells[row][col].value;
        final highlight = controller.selectedNumber.value == cellValue;
        return RepaintBoundary(
          child: AnimatedCellContainer(
            row: row,
            col: col,
            ctrl: controller,
            borderColor: highlight ? Colors.orange : Colors.grey.shade500,
            borderWidth: highlight ? 3 : 0.5,
            backgroundColor: highlight
                ? Colors.orange.withValues(alpha: 0.2)
                : null,
            child: Center(
              child: AnimatedBoardNumber(
                number: cellValue,
                celebratingNumber: controller.celebratingNumber.value,
                celebrateRegion: controller.isCellCelebrating(row, col),
                regionCelebrationToken: controller.celebrationToken.value,
                fontSize: 28,
                fontWeight: FontWeight.w500,
                color: controller.getCellTextColor(row, col),
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
    this.onTap,
  });

  final int row;
  final int col;
  final HomeController controller;
  final void Function(int row, int col, Offset globalPosition)? onTap;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GestureDetector(
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
            final isSelectedCell =
                controller.selectedRow == row &&
                controller.selectedCol == col;
            final isSelectedNumber =
                value != 0 && controller.selectedNumber.value == value;

            return AnimatedCellContainer(
              row: row,
              col: col,
              ctrl: controller,
              mistakeFlashToken: controller.mistakeFlashToken.value,
              isMistake: controller.isMistakeCell(row, col),
              borderColor: controller.selectedNumber.value == value
                  ? Colors.orange
                  : Colors.grey.shade300,
              borderWidth: controller.selectedNumber.value == value
                  ? 1.5
                  : 1,
              backgroundColor: isSelectedCell
                  ? Colors.amber.withValues(alpha: 0.12)
                  : isSelectedNumber
                  ? Colors.blue.withValues(alpha: 0.18)
                  : null,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (value != 0)
                    Center(
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
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        color: controller.getCellTextColor(row, col),
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
                          onTap: () =>
                              controller.clearNotes(row, col),
                          child: const Padding(
                            padding: EdgeInsets.all(1),
                            child: Icon(
                              Icons.clear_all,
                              size: 13,
                              color: Colors.redAccent,
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

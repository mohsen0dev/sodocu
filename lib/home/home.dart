import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sodocu/abute/abute_page.dart';
import 'home_controller.dart';

class SudokuBoard extends StatefulWidget {
  const SudokuBoard({super.key});

  @override
  State<SudokuBoard> createState() => _SudokuBoardState();
}

class _SudokuBoardState extends State<SudokuBoard> {
  final HomeController ctrl = Get.find<HomeController>();
  Offset? _pickerPosition;
  bool _showPicker = false;
  int? _selectedRow, _selectedCol;

  @override
  void initState() {
    super.initState();
    ctrl.newGame();
  }

  void _updateCell(int row, int col, int value) {
    ctrl.placeMainNumber(row, col, value);
    setState(() {
      _showPicker = false;
    });
  }

  void _showNumberPicker(
    BuildContext context,
    Offset position,
    int row,
    int col,
  ) {
    if (ctrl.cells[row][col].isFixed) {
      ctrl.showError('این خانه قابل تغییر نیست!');
      return;
    }

    final media = MediaQuery.of(context);
    const pickerSize = 140.0;
    double left = position.dx;
    double top = position.dy - 40;

    if (left + pickerSize > media.size.width) {
      left = position.dx - pickerSize;
    }
    if (top + pickerSize > media.size.height) {
      top = position.dy - pickerSize - 10;
    }

    setState(() {
      _pickerPosition = Offset(left, top);
      _showPicker = true;
      _selectedRow = row;
      _selectedCol = col;
    });
  }

  void _confirmNewGame() {
    Get.defaultDialog(
      title: 'شروع بازی جدید',
      titleStyle: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.blue,
      ),
      middleText: 'آیا مطمئن هستید؟ جدول فعلی پاک می‌شود.',
      textCancel: 'نه',
      textConfirm: 'بله',
      buttonColor: Colors.blue,
      onConfirm: () {
        ctrl.newGame();
        Get.back();
        setState(() {});
      },
    );
  }

  void _confirmChangeDifficulty(Difficulty newDiff) {
    Get.defaultDialog(
      title: 'تغییر سطح',
      titleStyle: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.blueAccent,
      ),
      middleText:
          'آیا می‌خواهید سطح را به "${_diffText(newDiff)}" تغییر دهید؟\nجدول فعلی حذف می‌شود',
      textCancel: 'نه',
      textConfirm: 'بله',
      buttonColor: Colors.blueAccent,
      onConfirm: () {
        ctrl.difficulty.value = newDiff;
        Get.back();
        setState(() {});
      },
    );
  }

  String _diffText(Difficulty d) => {
    Difficulty.easy: 'آسان',
    Difficulty.medium: 'متوسط',
    Difficulty.hard: 'سخت',
  }[d]!;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('سودوکو'),
        centerTitle: true,
        elevation: 0,
        actions: [
          Obx(
            () => IconButton(
              onPressed: ctrl.canRedo.value ? ctrl.redo : null,
              icon: const Icon(Icons.undo),
              tooltip: 'بازگردانی',
            ),
          ),
          Obx(
            () => IconButton(
              onPressed: ctrl.canUndo.value ? ctrl.undo : null,
              icon: const Icon(Icons.redo),
              tooltip: 'بازگشت',
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(8.0),
            child: FilledButton.icon(
              onPressed: _confirmNewGame,
              label: const Text('بازی جدید'),
              icon: const Icon(Icons.gamepad_outlined),
            ),
          ),
        ],
        leading: IconButton(
          onPressed: () => Get.to(const AboutPage()),
          icon: const Icon(Icons.info_outline),
        ),
      ),
      body: Obx(() {
        if (ctrl.isLoading.value) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('در حال تولید پازل...'),
              ],
            ),
          );
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (_showPicker) {
              setState(() => _showPicker = false);
            }
          },
          child: Stack(
            textDirection: TextDirection.rtl,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Column(
                    spacing: 20,
                    children: [
                      _difficultyWidget(),
                      _boardWidget(),
                      _numberConstWidget(),
                      _menuWidget(),
                    ],
                  ),
                ),
              ),
              if (_showPicker && _pickerPosition != null) _numberPickerWidget(),
            ],
          ),
        );
      }),
    );
  }

  Widget _difficultyWidget() {
    return Obx(
      () => SegmentedButton<Difficulty>(
        segments: Difficulty.values.map((d) {
          return ButtonSegment<Difficulty>(value: d, label: Text(_diffText(d)));
        }).toList(),
        selected: {ctrl.difficulty.value},
        onSelectionChanged: (Set<Difficulty> newSelection) {
          final selected = newSelection.first;
          if (selected != ctrl.difficulty.value) {
            _confirmChangeDifficulty(selected);
          }
        },
      ),
    );
  }

  /// ویجت نمایش اعداد 1 تا 9 با دکمه حذف (عدد 0)
  Widget _numberConstWidget() {
    return Obx(() {
      if (!ctrl.isShow.value) {
        return const SizedBox(height: 31);
      }

      return ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460, minWidth: 400),
        child: LayoutBuilder(
          builder: (context, constraints) {
            double totalWidth = constraints.maxWidth;
            double cellSize = (totalWidth - (10 * 6)) / 9.5;

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(10, (index) {
                final number = index; // 0 تا 9
                final used = ctrl.numberUsage[number] ?? 0;
                final isSelected = ctrl.selectedNumber.value == number;

                // عدد 9 برای دکمه حذف (آیکون)
                if (number == 0) {
                  return GestureDetector(
                    onTap: () {
                      ctrl.setNumber(0); // انتخاب حالت حذف
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: cellSize.clamp(30.0, 45.0),
                      height: cellSize.clamp(30.0, 45.0),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.red.shade200
                            : Colors.transparent,
                        border: Border.all(
                          color: isSelected ? Colors.red : Colors.white,
                          width: 0.5,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.delete_outline,
                        color: isSelected ? Colors.red : Colors.red.shade300,
                        size: cellSize.clamp(20.0, 28.0),
                      ),
                    ),
                  );
                }

                // اعداد 1 تا 9
                final isDisabled = used >= 9;

                return GestureDetector(
                  onTap: isDisabled
                      ? null
                      : () {
                          ctrl.setNumber(number);
                        },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: cellSize.clamp(30.0, 45.0),
                    height: cellSize.clamp(30.0, 45.0),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.blue.shade200
                          : Colors.transparent,
                      border: Border.all(
                        color: isDisabled
                            ? Colors.grey.shade800
                            : isSelected
                            ? Colors.blue
                            : Colors.white,
                        width: 0.5,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: 2,
                          right: 4,
                          child: Text(
                            used.toString(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: isSelected
                                  ? Colors.blue.shade800
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ),
                        Center(
                          child: Text(
                            number.toString(),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w500,
                              color: isDisabled
                                  ? Colors.grey.shade800
                                  : isSelected
                                  ? Colors.blue.shade800
                                  : Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            );
          },
        ),
      );
    });
  }

  Widget _boardWidget() {
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
                  color: ctrl.isActive.value ? Colors.green : Colors.white,
                  width: 1.5,
                ),
              ),
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                ),
                itemCount: 9,
                itemBuilder: (context, smallIdx) {
                  int row = (bigIdx ~/ 3) * 3 + (smallIdx ~/ 3);
                  int col = (bigIdx % 3) * 3 + (smallIdx % 3);

                  // خانه‌های ثابت (پازل اولیه)
                  if (ctrl.puzzle != null && ctrl.puzzle![row][col] != 0) {
                    return Obx(
                      () => Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color:
                                ctrl.selectedNumber.value ==
                                    int.tryParse(ctrl.getCellValue(row, col))
                                ? Colors.orange
                                : Colors.grey.shade500,
                            width:
                                ctrl.selectedNumber.value ==
                                    int.tryParse(ctrl.getCellValue(row, col))
                                ? 3
                                : 0.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            ctrl.getCellValue(row, col),
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w500,
                              color: ctrl.getCellTextColor(row, col),
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  // خانه‌های قابل ویرایش
                  return GestureDetector(
                    onTapDown: (details) {
                      if (ctrl.isShow.value) {
                        // حالت انتخاب عدد از پد اعداد
                        ctrl.setCellValue(row, col);
                        // اگر عدد به حداکثر استفاده رسید، انتخاب را بردار
                        if (ctrl.selectedNumber.value != 0 &&
                            ctrl.numberUsage[ctrl.selectedNumber.value] == 9) {
                          ctrl.selectedNumber.value = 0;
                        }
                      } else {
                        // حالت پیکر
                        _showNumberPicker(
                          context,
                          details.globalPosition,
                          row,
                          col,
                        );
                      }
                    },
                    child: Obx(() {
                      final hasNotes = ctrl.cells[row][col].notes.isNotEmpty;
                      final value = ctrl.cells[row][col].value;
                      final isSelectedCell =
                          ctrl.selectedRow == row && ctrl.selectedCol == col;

                      return Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: ctrl.selectedNumber.value == value
                                ? Colors.orange
                                : Colors.grey.shade300,
                            width: ctrl.selectedNumber.value == value ? 3 : 1,
                          ),
                          color: isSelectedCell ? Colors.yellow.shade50 : null,
                        ),
                        child: value != 0
                            ? Center(
                                child: Text(
                                  value.toString(),
                                  style: TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w700,
                                    color: ctrl.getCellTextColor(row, col),
                                  ),
                                ),
                              )
                            : hasNotes
                            ? _buildNotesGrid(ctrl.cells[row][col].notes)
                            : null,
                      );
                    }),
                  );
                },
              ),
            );
          });
        },
      ),
    );
  }

  Widget _buildNotesGrid(Set<int> notes) {
    return GridView.count(
      crossAxisCount: 3,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      children: List.generate(9, (index) {
        final number = index + 1;
        return Center(
          child: Text(
            notes.contains(number) ? number.toString() : '',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Colors.grey,
            ),
          ),
        );
      }),
    );
  }

  Widget _menuWidget() {
    return Center(
      child: Column(
        children: [
          Obx(
            () => InkWell(
              onTap: ctrl.currentHelperUses.value >= ctrl.maxHelperUses
                  ? null
                  : () {
                      ctrl.useHelper();
                    },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ctrl.currentHelperUses.value != ctrl.maxHelperUses
                      ? Row(
                          children: [
                            Text('شما  '),
                            Text(
                              '${ctrl.maxHelperUses - ctrl.currentHelperUses.value}',
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                            Text('  کمک در اختیار دارید'),
                          ],
                        )
                      : Text('از تمام کمک ها استفاده کردید'),
                  Icon(
                    size: 28,
                    ctrl.currentHelperUses.value >= ctrl.maxHelperUses
                        ? Icons.lightbulb_outline
                        : Icons.lightbulb,
                    color: ctrl.currentHelperUses.value >= ctrl.maxHelperUses
                        ? Colors.grey.shade400
                        : Colors.blue,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Obx(
            () => Container(
              width: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: SwitchListTile(
                title: const Text('اعتبارسنجی فوری'),
                value: ctrl.isActive.value,
                onChanged: (v) => ctrl.isActive.value = v,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Obx(
            () => Container(
              width: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: SwitchListTile(
                title: const Text('نمایش اعداد ثابت'),
                value: ctrl.isShow.value,
                onChanged: (v) {
                  ctrl.isShow.value = v;
                  ctrl.recalculateNumberUsage();
                  ctrl.selectedNumber.value = 0;
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          Obx(
            () => Container(
              width: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: SwitchListTile(
                title: const Text('نمایش یادداشت'),
                value: ctrl.noteMode.value,
                onChanged: (v) => ctrl.toggleNoteMode(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _numberPickerWidget() {
    final row = _selectedRow!;
    final col = _selectedCol!;
    final allowed = ctrl.allowedNumbers(row, col);
    final currentValue = ctrl.cells[row][col].value;

    return Positioned(
      left: _pickerPosition!.dx,
      top: _pickerPosition!.dy,
      child: Material(
        elevation: 12,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 140,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 1,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                ),
                itemCount: 9,
                itemBuilder: (context, idx) {
                  final number = idx + 1;
                  final enabled = allowed.contains(number);

                  return GestureDetector(
                    onTap: enabled
                        ? () {
                            _updateCell(row, col, number);
                          }
                        : null,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        border: Border.all(
                          color: enabled ? Colors.blue : Colors.grey.shade300,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          number.toString(),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: enabled ? Colors.blue : Colors.grey.shade400,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              if (currentValue != 0) ...[
                const SizedBox(height: 8),
                const Divider(),
                GestureDetector(
                  onTap: () {
                    ctrl.clearCell(row, col);
                    setState(() {
                      _showPicker = false;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.delete_outline, color: Colors.red, size: 18),
                        SizedBox(width: 4),
                        Text('پاک کردن', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

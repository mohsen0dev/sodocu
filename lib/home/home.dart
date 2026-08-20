import 'dart:math' show pi, sin;

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

  void _selectNumber(int number) {
    ctrl.setNumber(number);
    // بازسازی مستقیم والد، مستقل از زمان‌بندی واکنش‌گر GetX.
    if (mounted) setState(() {});
  }

  void _updateCell(int row, int col, int value) {
    if (ctrl.noteMode.value) {
      ctrl.toggleNote(row, col, value);
      // در حالت یادداشت، انتخابگر باز می‌ماند تا چند کاندیدا پشت‌سرهم ثبت شود.
      setState(() {});
      return;
    }

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

  void _confirmCleanInvalidNotes(int invalidCount) {
    Get.defaultDialog(
      title: 'پاک‌سازی یادداشت‌ها',
      titleStyle: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.orange,
      ),
      middleText:
          '$invalidCount یادداشت نامعتبر پیدا شد.\nآیا می‌خواهید همهٔ آن‌ها پاک شوند؟',
      textCancel: 'انصراف',
      textConfirm: 'پاک‌سازی',
      buttonColor: Colors.orange,
      onConfirm: () {
        Get.back();
        ctrl.cleanInvalidNotes();
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
              if (_showPicker && _pickerPosition != null)
                Obx(() => _numberPickerWidget()),
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
                return Obx(() {
                  final number = index; // 0 تا 9
                final used = ctrl.numberUsage[number] ?? 0;
                final isSelected = ctrl.selectedNumber.value == number;

                // عدد 9 برای دکمه حذف (آیکون)
                if (number == 0) {
                  return GestureDetector(
                    onTap: () {
                      _selectNumber(0); // انتخاب حالت حذف
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
                          _selectNumber(number);
                        },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: cellSize.clamp(30.0, 45.0),
                    height: cellSize.clamp(30.0, 45.0),
                    key: ValueKey('number-button-$number'),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.blue.shade700
                            : Colors.transparent,
                        border: Border.all(
                          color: isDisabled
                              ? Colors.grey.shade800
                              : isSelected
                              ? Colors.lightBlueAccent
                              : Colors.white,
                          width: isSelected ? 2 : 0.5,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Colors.blue.withValues(alpha: 0.45),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
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
                                  ? Colors.white70
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
                                  ? Colors.white
                                  : Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
                });
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
                    return Obx(() {
                      final cellValue = int.parse(ctrl.getCellValue(row, col));
                      final highlight = ctrl.selectedNumber.value == cellValue;                        return _AnimatedCellContainer(
                          row: row,
                          col: col,
                          ctrl: ctrl,
                          borderColor: highlight
                              ? Colors.orange
                              : Colors.grey.shade500,
                          borderWidth: highlight ? 3 : 0.5,
                          backgroundColor: highlight
                              ? Colors.orange.withValues(alpha: 0.2)
                              : null,
                          child: Center(

                          child: _AnimatedBoardNumber(
                            number: cellValue,
                            celebratingNumber: ctrl.celebratingNumber.value,
                            celebrateRegion: ctrl.isCellCelebrating(row, col),
                            regionCelebrationToken: ctrl.celebrationToken.value,
                            fontSize: 28,
                            fontWeight: FontWeight.w500,
                            color: ctrl.getCellTextColor(row, col),
                          ),
                        ),
                      );
                    });
                  }

                  // خانه‌های قابل ویرایش
                  return GestureDetector(
                    onTapUp: (details) {
                      ctrl.selectCell(row, col);
                      if (ctrl.isShow.value) {
                        // حالت ورود مستقیم؛ در حالت یادداشت فقط کاندیدا تغییر می‌کند.
                        if (ctrl.noteMode.value) {
                          ctrl.setCellNote(row, col);
                        } else {
                          ctrl.setCellValue(row, col);
                          // اگر عدد به حداکثر استفاده رسید، انتخاب را بردار
                          if (ctrl.selectedNumber.value != 0 &&
                              ctrl.numberUsage[ctrl.selectedNumber.value] ==
                                  9) {
                            ctrl.selectedNumber.value = 0;
                          }
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
                      final isSelectedNumber =
                          value != 0 && ctrl.selectedNumber.value == value;

                      return _AnimatedCellContainer(
                        row: row,
                        col: col,
                        ctrl: ctrl,
                        borderColor: ctrl.selectedNumber.value == value
                            ? Colors.orange
                            : Colors.grey.shade300,
                        borderWidth: ctrl.selectedNumber.value == value
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
                                child: _AnimatedBoardNumber(
                                  number: value,
                                  celebratingNumber:
                                      ctrl.celebratingNumber.value,
                                  celebrateRegion: ctrl.isCellCelebrating(
                                    row,
                                    col,
                                  ),
                                  regionCelebrationToken:
                                      ctrl.celebrationToken.value,
                                  fontSize: 30,
                                  fontWeight: FontWeight.w700,
                                  color: ctrl.getCellTextColor(row, col),
                                ),
                              )
                            else if (hasNotes)
                              _buildNotesGrid(ctrl.cells[row][col].notes),
                            if (hasNotes)
                              Positioned(
                                top: 0,
                                right: 0,
                                child: Tooltip(
                                  message: 'حذف همه یادداشت‌ها',
                                  child: InkWell(
                                    onTap: () => ctrl.clearNotes(row, col),
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
                title: const Text('حالت یادداشت'),
                value: ctrl.noteMode.value,
                onChanged: (v) => ctrl.toggleNoteMode(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Obx(() {
            final invalidCount = ctrl.invalidNotesCount();
            return SizedBox(
              width: 300,
              child: OutlinedButton.icon(
                onPressed: invalidCount == 0
                    ? null
                    : () => _confirmCleanInvalidNotes(invalidCount),
                icon: const Icon(Icons.cleaning_services_outlined),
                label: Text(
                  invalidCount == 0
                      ? 'یادداشت نامعتبر وجود ندارد'
                      : 'پاک‌سازی یادداشت‌های نامعتبر ($invalidCount)',
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _numberPickerWidget() {
    final row = _selectedRow!;
    final col = _selectedCol!;
    final allowed = ctrl.allowedNumbers(row, col);
    final notes = ctrl.cells[row][col].notes;
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
              if (ctrl.noteMode.value)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    'حالت یادداشت',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
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
                  final isNote = notes.contains(number);
                  final enabled =
                      currentValue == 0 &&
                      (allowed.contains(number) ||
                          (ctrl.noteMode.value && isNote));

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
                            color: !enabled
                                ? Colors.grey.shade400
                                : ctrl.noteMode.value && isNote
                                ? Colors.orange
                                : Colors.blue,
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
              if (notes.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Divider(),
                GestureDetector(
                  onTap: () {
                    ctrl.clearNotes(row, col);
                    setState(() {
                      _showPicker = false;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.clear_all, color: Colors.orange, size: 18),
                        SizedBox(width: 4),
                        Text(
                          'حذف یادداشت‌ها',
                          style: TextStyle(color: Colors.orange),
                        ),
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

class _AnimatedBoardNumber extends StatefulWidget {
  const _AnimatedBoardNumber({
    required this.number,
    required this.celebratingNumber,
    required this.celebrateRegion,
    required this.regionCelebrationToken,
    required this.fontSize,
    required this.fontWeight,
    required this.color,
  });

  final int number;
  final int? celebratingNumber;
  final bool celebrateRegion;
  final int regionCelebrationToken;
  final double fontSize;
  final FontWeight fontWeight;
  final Color color;

  @override
  State<_AnimatedBoardNumber> createState() => _AnimatedBoardNumberState();
}

class _AnimatedBoardNumberState extends State<_AnimatedBoardNumber>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  int _lastRegionToken = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1, end: 1.45), weight: 35),
      TweenSequenceItem(tween: Tween<double>(begin: 1.45, end: 1), weight: 65),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  void _runCelebration() {
    _controller.forward(from: 0);
  }

  @override
  void didUpdateWidget(_AnimatedBoardNumber oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.celebratingNumber == widget.number &&
        oldWidget.celebratingNumber != widget.number) {
      _runCelebration();
    }
    if (widget.celebrateRegion &&
        widget.regionCelebrationToken != _lastRegionToken) {
      _lastRegionToken = widget.regionCelebrationToken;
      _runCelebration();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = _controller.value;
        final shake =
            sin(progress * pi * 12) * 5 * (1 - progress.clamp(0.0, 1.0));
        final isAnimating = _controller.isAnimating;

        return Transform.translate(
          offset: Offset(shake, 0),
          child: Transform.scale(
            scale: _scale.value,
            child: Text(
              widget.number.toString(),
              style: TextStyle(
                fontSize: widget.fontSize,
                fontWeight: widget.fontWeight,
                color: isAnimating ? const Color(0xFFFFD700) : widget.color,
                shadows: isAnimating
                    ? [
                        Shadow(
                          color: Colors.amber.shade700.withValues(alpha: 0.6),
                          blurRadius: 8,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AnimatedCellContainer extends StatefulWidget {
  const _AnimatedCellContainer({
    required this.row,
    required this.col,
    required this.ctrl,
    required this.borderColor,
    required this.borderWidth,
    this.backgroundColor,
    required this.child,
  });

  final int row;
  final int col;
  final HomeController ctrl;
  final Color borderColor;
  final double borderWidth;
  final Color? backgroundColor;
  final Widget? child;

  @override
  State<_AnimatedCellContainer> createState() => _AnimatedCellContainerState();
}

class _AnimatedCellContainerState extends State<_AnimatedCellContainer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  int _lastRegionToken = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  Color _persistentBackground() {
    final completed = widget.ctrl.getCompletedUnitBackground(
      widget.row,
      widget.col,
    );
    final base = widget.backgroundColor;
    if (completed == null) {
      return base ?? Colors.transparent;
    }
    if (base == null) return completed;
    return Color.lerp(base, completed, 0.75) ?? completed;
  }

  Color _peakBackground() {
    return widget.ctrl.getCompletedUnitPeakBackground(widget.row, widget.col);
  }

  Color _celebrationColor(double progress) {
    final persistent = _persistentBackground();
    final peak = _peakBackground();
    final pulse = sin(progress * pi);
    return Color.lerp(persistent, peak, pulse * 0.95) ?? persistent;
  }

  @override
  void didUpdateWidget(_AnimatedCellContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.ctrl.isCellCelebrating(widget.row, widget.col) &&
        widget.ctrl.celebrationToken.value != _lastRegionToken) {
      _lastRegionToken = widget.ctrl.celebrationToken.value;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = _controller.value;
        final isCelebrating = widget.ctrl.isCellCelebrating(
          widget.row,
          widget.col,
        );
        final bgColor = _controller.isAnimating || isCelebrating
            ? _celebrationColor(progress)
            : _persistentBackground();

        return Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: widget.borderColor,
              width: widget.borderWidth,
            ),
            color: bgColor == Colors.transparent ? null : bgColor,
            boxShadow: _controller.isAnimating
                ? [
                    BoxShadow(
                      color: Colors.amber.withValues(
                        alpha: 0.35 * (1 - progress),
                      ),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: widget.child,
        );
      },
    );
  }
}

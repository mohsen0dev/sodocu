import 'dart:math' show pi, sin;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sodocu/abute/abute_page.dart';
import 'home_controller.dart';
import 'records_page.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeGame());
  }

  @override
  void dispose() {
    ctrl.stopGameTimer();
    super.dispose();
  }

  Future<void> _initializeGame() async {
    final hasPreviousGame = await ctrl.initialize();
    if (!mounted) return;

    if (hasPreviousGame) {
      final continueGame = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('ادامه بازی قبلی؟'),
          content: Text(
            'یک بازی ذخیره‌شده پیدا شد. زمان سپری‌شده: '
            '${ctrl.formatDuration(ctrl.elapsedSeconds.value)}',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('بازی جدید'),
            ),
            FilledButton(
              onPressed: () => Get.back(result: true),
              child: const Text('ادامه'),
            ),
          ],
        ),
        barrierDismissible: false,
      );

      if (mounted && continueGame != true) {
        await ctrl.newGame();
      }
    }

    if (mounted && !ctrl.onboardingSeen) {
      await _showOnboarding();
    }
  }

  Future<void> _showOnboarding() async {
    if (Get.testMode) return;
    await Get.dialog<void>(
      AlertDialog(
        title: const Text('به سودوکو خوش آمدید 👋'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _onboardingItem(
              Icons.edit_note,
              'حالت یادداشت',
              'کاندیداهای هر خانه را بدون ثبت عدد نهایی یادداشت کنید.',
            ),
            const SizedBox(height: 12),
            _onboardingItem(
              Icons.lightbulb,
              'راهنما',
              'در حالت‌های عادی تا ۳ بار یک خانهٔ خالی را برایتان پر می‌کند.',
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () {
              ctrl.markOnboardingSeen();
              Get.back();
            },
            child: const Text('شروع'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  Widget _onboardingItem(IconData icon, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.blue, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
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
    if (_showPicker && _selectedRow == row && _selectedCol == col) {
      setState(() {
        _showPicker = false;
        _pickerPosition = null;
        _selectedRow = null;
        _selectedCol = null;
      });
      return;
    }

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
          IconButton(
            tooltip: 'رکوردها',
            onPressed: () => Get.to(const RecordsPage()),
            icon: const Icon(Icons.emoji_events_outlined),
          ),
          Obx(
            () => IconButton(
              onPressed: ctrl.canUndo.value ? ctrl.undo : null,
              icon: const Icon(Icons.undo),
              tooltip: 'بازگشت',
            ),
          ),
          Obx(
            () => IconButton(
              onPressed: ctrl.canRedo.value ? ctrl.redo : null,
              icon: const Icon(Icons.redo),
              tooltip: 'بازگردانی',
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
                      _gameInfoWidget(),
                      _modeWidget(),
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

  Widget _gameInfoWidget() {
    return Obx(
      () => ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Row(
          children: [
            Expanded(
              child: _infoCard(
                icon: Icons.timer_outlined,
                title: ctrl.gameMode.value == GameMode.timed
                    ? 'زمان باقی‌مانده'
                    : 'زمان بازی',
                value: ctrl.gameMode.value == GameMode.timed
                    ? ctrl.formatDuration(ctrl.remainingSeconds.value)
                    : ctrl.formatDuration(ctrl.elapsedSeconds.value),
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            if (ctrl.isRecordMode) ...[
              Expanded(
                child: _infoCard(
                  icon: Icons.error_outline,
                  title: 'خطاهای باقی‌مانده',
                  valueWidget: _BounceOnChange(
                    key: ValueKey('mistake-counter-${ctrl.mistakes.value}'),
                    value:
                        '${HomeController.maxMistakes - ctrl.mistakes.value} از ${HomeController.maxMistakes}',
                    announcement:
                        'خطاهای باقی‌مانده: ${HomeController.maxMistakes - ctrl.mistakes.value} از ${HomeController.maxMistakes}',
                  ),
                  color: ctrl.mistakes.value >= HomeController.maxMistakes - 1
                      ? Colors.red
                      : Colors.deepOrange,
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: _infoCard(
                icon: Icons.emoji_events_outlined,
                title: 'بهترین زمان',
                value: ctrl.bestTimes[ctrl.recordKey] == null
                    ? '--:--'
                    : ctrl.formatDuration(ctrl.bestTimes[ctrl.recordKey]!),
                color: Colors.amber,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String title,
    String? value,
    Widget? valueWidget,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 12)),
              valueWidget ??
                  Text(
                    value!,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _modeWidget() {
    return Obx(() {
      final selected = ctrl.gameMode.value;
      return ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 430 ? 3 : 2;
            const spacing = 8.0;
            final cellWidth =
                (constraints.maxWidth - spacing * (columns - 1)) / columns;
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (final mode in GameMode.values)
                  _modeCard(mode, selected, cellWidth),
              ],
            );
          },
        ),
      );
    });
  }

  Widget _modeCard(GameMode mode, GameMode selected, double width) {
    final color = HomeController.gameModeColor(mode);
    final isSelected = mode == selected;
    final dailyDisabled = mode == GameMode.daily && ctrl.dailyAttemptUsed;

    return Semantics(
      button: true,
      selected: isSelected,
      enabled: !dailyDisabled,
      label:
          '${HomeController.gameModeLabel(mode)}. '
          '${HomeController.gameModeDescription(mode)}',
      child: Opacity(
        opacity: dailyDisabled ? 0.45 : 1,
        child: Material(
          color: isSelected ? color.withValues(alpha: 0.16) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: dailyDisabled ? null : () => ctrl.changeMode(mode),
            child: Container(
              width: width,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? color : color.withValues(alpha: 0.35),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        HomeController.gameModeIcon(mode),
                        color: color,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          HomeController.gameModeLabel(mode),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? color : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isSelected)
                        Icon(Icons.check_circle, color: color, size: 16),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dailyDisabled
                        ? 'انجام شده — فردا دوباره'
                        : HomeController.gameModeDescription(mode),
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.3,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _difficultyWidget() {
    return Obx(() {
      // در چالش روزانه پازل ثابت است؛ سطح را نمی‌توان تغییر داد.
      if (ctrl.isDailyMode) {
        return Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: Colors.teal,
                ),
                const SizedBox(width: 6),
                Text(
                  ctrl.dailyDateLabel,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'سطح: ${_diffText(HomeController.dailyDifficulty)} (ثابت) — یک تلاش در روز',
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        );
      }
      return SegmentedButton<Difficulty>(
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
      );
    });
  }

  /// ویجت نمایش اعداد 1 تا 9 با دکمه حذف (عدد 0)
  Widget _numberConstWidget() {
    return Obx(() {
      if (!ctrl.isShow.value) {
        return const SizedBox(height: 31);
      }

      final theme = Theme.of(context);
      return ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Card(
          margin: EdgeInsets.zero,
          elevation: 0,
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: LayoutBuilder(
              builder: (context, constraints) {
                const gap = 6.0;
                final cellSize = ((constraints.maxWidth - gap * 9) / 10)
                    .clamp(28.0, 46.0);

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(10, (index) {
                    return Obx(() {
                      final number = index; // 0 تا 9
                      final used = ctrl.numberUsage[number] ?? 0;
                      final isSelected = ctrl.selectedNumber.value == number;
                      final isDisabled = number != 0 && used >= 9;
                      final isDelete = number == 0;

                      final accent = isDelete ? Colors.red : Colors.blue;
                      final tileColor = isSelected
                          ? (isDelete
                                ? Colors.red.shade700
                                : Colors.blue.shade700)
                          : theme.colorScheme.surfaceContainerHigh.withValues(
                              alpha: 0.4,
                            );
                      final borderColor = isSelected
                          ? (isDelete ? Colors.redAccent : Colors.lightBlueAccent)
                          : theme.colorScheme.outlineVariant;

                      return GestureDetector(
                        onTap: isDisabled ? null : () => _selectNumber(number),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: cellSize,
                          height: cellSize,
                          key: ValueKey('number-button-$number'),
                          decoration: BoxDecoration(
                            color: tileColor,
                            border: Border.all(
                              color: borderColor,
                              width: isSelected ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: accent.withValues(alpha: 0.45),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : null,
                          ),
                          child: isDelete
                              ? Icon(
                                  Icons.delete_outline,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.red.shade300,
                                  size: cellSize.clamp(18.0, 26.0),
                                )
                              : Stack(
                                  children: [
                                    Positioned(
                                      top: 2,
                                      right: 3,
                                      child: Text(
                                        used.toString(),
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w600,
                                          color: isSelected
                                              ? Colors.white70
                                              : theme.colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                    Center(
                                      child: Text(
                                        number.toString(),
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w600,
                                          color: isDisabled
                                              ? theme.colorScheme.onSurface
                                                  .withValues(alpha: 0.38)
                                              : isSelected
                                              ? Colors.white
                                              : theme.colorScheme.onSurface,
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
          ),
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
                      final cellValue = ctrl.cells[row][col].value;
                      final highlight = ctrl.selectedNumber.value == cellValue;
                      return _AnimatedCellContainer(
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
                        mistakeFlashToken: ctrl.mistakeFlashToken.value,
                        isMistake: ctrl.isMistakeCell(row, col),
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
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _helperCard(),
            const SizedBox(height: 12),
            _settingsCard(),
            const SizedBox(height: 12),
            _cleanNotesButton(),
          ],
        ),
      ),
    );
  }

  Widget _helperCard() {
    return Obx(() {
      final theme = Theme.of(context);
      final disabled = !ctrl.hintsEnabled;
      final usedUp = ctrl.currentHelperUses.value >= ctrl.maxHelperUses;
      final remaining = ctrl.maxHelperUses - ctrl.currentHelperUses.value;
      final muted = disabled || usedUp;

      return Material(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.5,
        ),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: muted ? null : ctrl.useHelper,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(
                  muted ? Icons.lightbulb_outline : Icons.lightbulb,
                  color: muted
                      ? theme.colorScheme.onSurfaceVariant
                      : Colors.amber,
                  size: 26,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'راهنما',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: muted ? theme.colorScheme.onSurfaceVariant : null,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        disabled
                            ? 'در این حالت غیرفعال است'
                            : usedUp
                            ? 'از تمام کمک‌ها استفاده کردید'
                            : 'یک خانهٔ خالی را برایتان پر می‌کند',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!muted)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$remaining',
                      style: const TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _settingsCard() {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Obx(
            () => _settingTile(
              icon: Icons.bolt_outlined,
              title: 'اعتبارسنجی فوری',
              subtitle: 'اعداد نادرست را بلافاصله قرمز نشان می‌دهد',
              value: ctrl.isActive.value,
              onChanged: (v) => ctrl.isActive.value = v,
            ),
          ),
          _settingsDivider(theme),
          Obx(
            () => _settingTile(
              icon: Icons.keyboard_alt_outlined,
              title: 'نمایش اعداد ثابت',
              subtitle: 'نوار اعداد و ورود سریع در پایین صفحه',
              value: ctrl.isShow.value,
              onChanged: (v) {
                ctrl.isShow.value = v;
                ctrl.recalculateNumberUsage();
                ctrl.selectedNumber.value = 0;
              },
            ),
          ),
          _settingsDivider(theme),
          Obx(
            () => _settingTile(
              icon: Icons.edit_note,
              title: 'حالت یادداشت',
              subtitle: 'یادداشت کاندیداها در خانه‌ها',
              value: ctrl.noteMode.value,
              onChanged: (v) => ctrl.toggleNoteMode(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingsDivider(ThemeData theme) {
    return Divider(
      height: 1,
      indent: 16,
      endIndent: 16,
      color: theme.colorScheme.outlineVariant,
    );
  }

  Widget _settingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);
    return SwitchListTile(
      secondary: Icon(icon, color: theme.colorScheme.primary, size: 24),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      value: value,
      onChanged: onChanged,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }

  Widget _cleanNotesButton() {
    return Obx(() {
      final invalidCount = ctrl.invalidNotesCount();
      return OutlinedButton.icon(
        onPressed: invalidCount == 0
            ? null
            : () => _confirmCleanInvalidNotes(invalidCount),
        icon: const Icon(Icons.cleaning_services_outlined),
        label: Text(
          invalidCount == 0
              ? 'یادداشت نامعتبر وجود ندارد'
              : 'پاک‌سازی یادداشت‌های نامعتبر ($invalidCount)',
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      );
    });
  }

  Widget _numberPickerWidget() {
    final row = _selectedRow!;
    final col = _selectedCol!;
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
                  final enabled = ctrl.isPickerNumberEnabled(row, col, number);

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
    this.mistakeFlashToken = 0,
    this.isMistake = false,
    required this.child,
  });

  final int row;
  final int col;
  final HomeController ctrl;
  final Color borderColor;
  final double borderWidth;
  final Color? backgroundColor;
  final int mistakeFlashToken;
  final bool isMistake;
  final Widget? child;

  @override
  State<_AnimatedCellContainer> createState() => _AnimatedCellContainerState();
}

class _AnimatedCellContainerState extends State<_AnimatedCellContainer>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final AnimationController _mistakeController;
  int _lastRegionToken = 0;
  int _lastMistakeToken = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _mistakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
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
    if (widget.isMistake && widget.mistakeFlashToken != _lastMistakeToken) {
      _lastMistakeToken = widget.mistakeFlashToken;
      if (!MediaQuery.of(context).disableAnimations) {
        _mistakeController.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _mistakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_controller, _mistakeController]),
      builder: (context, child) {
        final progress = _controller.value;
        final mistakeProgress = _mistakeController.value;
        final isCelebrating = widget.ctrl.isCellCelebrating(
          widget.row,
          widget.col,
        );
        final isMistakeAnimating = _mistakeController.isAnimating;

        final persistent = _persistentBackground();
        final base = persistent == Colors.transparent ? null : persistent;
        final bgColor = isMistakeAnimating
            ? Color.lerp(
                base ?? Colors.transparent,
                Colors.red,
                0.35 * (1 - mistakeProgress),
              )
            : (_controller.isAnimating || isCelebrating
                ? _celebrationColor(progress)
                : persistent);

        final shake = isMistakeAnimating
            ? sin(mistakeProgress * pi * 8) * 6 * (1 - mistakeProgress)
            : 0.0;

        return Transform.translate(
          offset: Offset(shake, 0),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: isMistakeAnimating ? Colors.red : widget.borderColor,
                width: isMistakeAnimating ? 2 : widget.borderWidth,
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
          ),
        );
      },
    );
  }
}

/// نمایش عددی که هنگام تغییر، یک پرش کوتاه دارد و برای screen reader
/// از طریق ناحیهٔ زنده اعلام می‌شود.
class _BounceOnChange extends StatefulWidget {
  const _BounceOnChange({
    required this.value,
    this.announcement,
    super.key,
  });

  final String value;
  final String? announcement;

  @override
  State<_BounceOnChange> createState() => _BounceOnChangeState();
}

class _BounceOnChangeState extends State<_BounceOnChange>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.35), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.35, end: 1.0), weight: 60),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(_BounceOnChange oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value &&
        !MediaQuery.of(context).disableAnimations) {
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
    return Semantics(
      liveRegion: true,
      label: widget.announcement ?? widget.value,
      child: ScaleTransition(
        scale: _scale,
        child: Text(
          widget.value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

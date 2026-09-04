import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sodocu/home/records_page.dart';

import 'home_controller.dart';
import 'widgets/board_animations.dart';
import 'widgets/mode_bottom_sheet.dart';
import 'widgets/number_bar.dart';
import 'widgets/settings_sheet.dart';
import 'widgets/sudoku_grid.dart';

/// صفحهٔ اصلی بازی سودوکو.
///
/// این ویجت فقط مسئول چیدمان (Scaffold + AppBar + body) و مدیریت
/// lifecycle بازی (initialization, onboarding) است. ویجت‌های فرعی
/// جدول، نوار اعداد، شیت‌ها و انیمیشن‌ها همگی در دایرکتوری
/// `widgets/` استخراج شده‌اند.
class SudokuBoard extends StatefulWidget {
  const SudokuBoard({super.key});

  @override
  State<SudokuBoard> createState() => _SudokuBoardState();
}

class _SudokuBoardState extends State<SudokuBoard> {
  final HomeController ctrl = Get.find<HomeController>();

  // ── state مربوط به number picker ──
  Offset? _pickerPosition;
  bool _showPicker = false;
  int? _selectedRow, _selectedCol;

  // ==================== Lifecycle ====================

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

  // ==================== Number Picker ====================

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

  void _updateCell(int row, int col, int value) {
    if (ctrl.noteMode.value) {
      ctrl.toggleNote(row, col, value);
      setState(() {}); // picker در حالت یادداشت باز می‌ماند
      return;
    }

    ctrl.placeMainNumber(row, col, value);
    setState(() {
      _showPicker = false;
    });
  }

  // ==================== Build ====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('سودوکو'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'شروع بازی جدید',
            onPressed: () => confirmNewGameDialog(context, ctrl),
            icon: const Icon(Icons.gamepad_outlined),
          ),
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
        ],
        leading: IconButton(
          tooltip: 'تنظیمات',
          onPressed: () => showSettingsSheet(context, ctrl),
          icon: const Icon(Icons.settings_outlined),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: NumberBar(controller: ctrl),
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
                      _progressBarWidget(),
                      ModeQuickButton(
                        controller: ctrl,
                        onPressed: () =>
                            showModeSheet(context, ctrl),
                      ),
                      SudokuGrid(
                        controller: ctrl,
                        onCellTap: (row, col, pos) =>
                            _showNumberPicker(context, pos, row, col),
                      ),
                    ],
                  ),
                ),
              ),
              if (_showPicker && _pickerPosition != null)
                _numberPickerWidget(),
            ],
          ),
        );
      }),
    );
  }

  // ==================== UI Sub-widgets (local) ====================

  Widget _onboardingItem(IconData icon, String title, String subtitle) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
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
                  valueWidget: BounceOnChange(
                    key: ValueKey('mistake-counter-${ctrl.mistakes.value}'),
                    value:
                        '${HomeController.maxMistakes - ctrl.mistakes.value} از ${HomeController.maxMistakes}',
                    announcement:
                        'خطاهای باقی‌مانده: ${HomeController.maxMistakes - ctrl.mistakes.value} از ${HomeController.maxMistakes}',
                  ),
                  color:
                      ctrl.mistakes.value >= HomeController.maxMistakes - 1
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

  Widget _progressBarWidget() {
    return Obx(() {
      final completed = ctrl.completedCells.value;
      const total = 81;
      final percentage = total > 0 ? (completed / total) * 100 : 0;
      final theme = Theme.of(context);

      return ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$completed از $total خانه پر شده  (${percentage.toStringAsFixed(1)}%)',
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    });
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

  // ==================== Number Picker Widget ====================

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
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).colorScheme.primary),
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
                      ctrl.isPickerNumberEnabled(row, col, number);
                  final theme = Theme.of(context);

                  return GestureDetector(
                    onTap: enabled
                        ? () => _updateCell(row, col, number)
                        : null,
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHigh,
                        border: Border.all(
                          color: enabled
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outlineVariant,
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
                                ? theme.colorScheme.onSurface
                                      .withValues(alpha: 0.38)
                                : ctrl.noteMode.value && isNote
                                ? Colors.orange
                                : theme.colorScheme.primary,
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
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.delete_outline,
                          color: Theme.of(context).colorScheme.error,
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'پاک کردن',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
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
                      color: Colors.orange.withValues(alpha: 0.15),
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

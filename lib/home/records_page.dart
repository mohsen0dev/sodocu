import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'home_controller.dart';

/// صفحهٔ نمایش رکوردهای محلی (بهترین زمان) برای هر حالت و سطح دشواری.
class RecordsPage extends StatelessWidget {
  const RecordsPage({super.key});

  static const Map<GameMode, IconData> _modeIcons = {
    GameMode.classic: Icons.gamepad_outlined,
    GameMode.timed: Icons.timer_outlined,
    GameMode.noHints: Icons.lightbulb_outline,
    GameMode.daily: Icons.calendar_today_outlined,
    GameMode.record: Icons.emoji_events_outlined,
  };

  static const Map<GameMode, Color> _modeColors = {
    GameMode.classic: Colors.blue,
    GameMode.timed: Colors.deepOrange,
    GameMode.noHints: Colors.purple,
    GameMode.daily: Colors.teal,
    GameMode.record: Colors.amber,
  };

  String _diffText(Difficulty d) => switch (d) {
    Difficulty.easy => 'آسان',
    Difficulty.medium => 'متوسط',
    Difficulty.hard => 'سخت',
  };

  /// بهترین (کمترین) زمان ثبت‌شده در یک حالت؛ برای هایلایت رکورد برتر.
  int? _bestInMode(HomeController ctrl, GameMode mode) {
    int? best;
    for (final diff in Difficulty.values) {
      final time = ctrl.bestTimeFor(mode, diff);
      if (time != null && (best == null || time < best)) best = time;
    }
    return best;
  }

  void _confirmDelete(HomeController ctrl, GameMode mode, Difficulty diff) {
    Get.defaultDialog(
      title: 'حذف رکورد',
      titleStyle: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.red,
      ),
      middleText:
          'رکورد «${HomeController.gameModeLabel(mode)} — ${_diffText(diff)}» حذف شود؟',
      textCancel: 'انصراف',
      textConfirm: 'حذف',
      buttonColor: Colors.red,
      onConfirm: () {
        ctrl.clearBestTime(mode, diff);
        Get.back();
      },
    );
  }

  void _confirmResetAll(HomeController ctrl) {
    Get.defaultDialog(
      title: 'پاک کردن همه رکوردها',
      titleStyle: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.red,
      ),
      middleText: 'همهٔ بهترین زمان‌ها برای همیشه حذف شوند؟',
      textCancel: 'انصراف',
      textConfirm: 'پاک کردن',
      buttonColor: Colors.red,
      onConfirm: () {
        ctrl.clearAllBestTimes();
        Get.back();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<HomeController>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('رکوردها'),
        centerTitle: true,
        elevation: 0,
        actions: [
          Obx(
            () => IconButton(
              key: const ValueKey('reset-all'),
              tooltip: 'پاک کردن همه رکوردها',
              onPressed: ctrl.bestTimes.isEmpty
                  ? null
                  : () => _confirmResetAll(ctrl),
              icon: const Icon(Icons.delete_sweep_outlined),
            ),
          ),
        ],
      ),
      body: Obx(() {
        if (ctrl.bestTimes.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.emoji_events_outlined,
                    size: 72,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text('هنوز رکوردی ثبت نشده است', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    'یک بازی را در هر حالت و سطحی کامل کنید تا بهترین زمان شما در اینجا ذخیره شود.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final mode in GameMode.values) _modeSection(context, ctrl, mode),
          ],
        );
      }),
    );
  }

  Widget _modeSection(BuildContext context, HomeController ctrl, GameMode mode) {
    final color = _modeColors[mode]!;
    final best = _bestInMode(ctrl, mode);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  Icon(_modeIcons[mode], color: color, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      HomeController.gameModeLabel(mode),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            for (final diff in Difficulty.values)
              _recordRow(
                ctrl,
                mode,
                diff,
                isBest:
                    best != null && ctrl.bestTimeFor(mode, diff) == best,
              ),
            if (mode == GameMode.daily)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Text(
                  'در چالش روزانه فقط سطح متوسط قابل بازی است.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _recordRow(
    HomeController ctrl,
    GameMode mode,
    Difficulty diff, {
    required bool isBest,
  }) {
    final time = ctrl.bestTimeFor(mode, diff);
    final color = _modeColors[mode]!;

    return ListTile(
      key: ValueKey('record-${mode.name}-${diff.name}'),
      dense: true,
      title: Row(
        children: [
          Expanded(child: Text(_diffText(diff))),
          Text(
            time == null ? '--:--' : ctrl.formatDuration(time),
            style: TextStyle(
              fontWeight: isBest ? FontWeight.bold : FontWeight.normal,
              color: isBest ? Colors.amber : null,
              fontSize: isBest ? 18 : 16,
            ),
          ),
        ],
      ),
      trailing: IconButton(
        key: ValueKey('delete-${mode.name}-${diff.name}'),
        tooltip: 'حذف رکورد',
        onPressed: time == null
            ? null
            : () => _confirmDelete(ctrl, mode, diff),
        icon: Icon(
          Icons.delete_outline,
          size: 20,
          color: time == null
              ? Colors.grey.shade700
              : color.withValues(alpha: 0.9),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'home_controller.dart';

/// صفحهٔ نمایش رکوردهای محلی (بهترین زمان) برای هر حالت و سطح دشواری.
class RecordsPage extends StatelessWidget {
  const RecordsPage({super.key});

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
        final hasData = ctrl.bestTimes.isNotEmpty || ctrl.gamesCompleted.value > 0;
        if (!hasData) {
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
            _statsDashboard(context, ctrl),
            const SizedBox(height: 16),
            for (final mode in GameMode.values) _modeSection(context, ctrl, mode),
          ],
        );
      }),
    );
  }

  Widget _statsDashboard(BuildContext context, HomeController ctrl) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'خلاصهٔ عملکرد',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 420 ? 4 : 2;
                const spacing = 8.0;
                final width =
                    (constraints.maxWidth - spacing * (columns - 1)) / columns;
                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    _statCard(
                      context,
                      icon: Icons.flag_outlined,
                      label: 'بازی‌های تکمیل‌شده',
                      value: ctrl.gamesCompleted.value.toString(),
                      color: Colors.blue,
                      width: width,
                    ),
                    _statCard(
                      context,
                      icon: Icons.speed_outlined,
                      label: 'میانگین زمان',
                      value: ctrl.averageCompletedSeconds == null
                          ? '--:--'
                          : ctrl.formatDuration(ctrl.averageCompletedSeconds!),
                      color: Colors.deepOrange,
                      width: width,
                    ),
                    _statCard(
                      context,
                      icon: Icons.local_fire_department_outlined,
                      label: 'بهترین استریک',
                      value: ctrl.bestStreak.value.toString(),
                      color: Colors.teal,
                      width: width,
                    ),
                    _statCard(
                      context,
                      icon: Icons.emoji_events_outlined,
                      label: 'بهترین زمان',
                      value: ctrl.overallBestTime == null
                          ? '--:--'
                          : ctrl.formatDuration(ctrl.overallBestTime!),
                      color: Colors.amber,
                      width: width,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 8),
            Text(
              'استریک = تعداد روزهای متوالی که چالش روزانه را کامل کرده‌اید.',
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required double width,
  }) {
    final theme = Theme.of(context);
    return Container(
      width: width,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeSection(BuildContext context, HomeController ctrl, GameMode mode) {
    final color = HomeController.gameModeColor(mode);
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
                  Icon(HomeController.gameModeIcon(mode), color: color, size: 22),
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
    final color = HomeController.gameModeColor(mode);

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

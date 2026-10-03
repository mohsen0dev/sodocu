import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../home_controller.dart';

/// نمایش شیت انتخاب حالت بازی و سطح دشواری.
Future<void> showModeSheet(BuildContext context, HomeController ctrl) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    builder: (sheetContext) {
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // دکمهٔ شروع بازی جدید
              FilledButton.icon(
                onPressed: () => _confirmNewGame(context, ctrl),
                icon: const Icon(Icons.gamepad_outlined),
                label: const Text('شروع بازی جدید'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'حالت بازی',
                  style: Theme.of(sheetContext).textTheme.titleLarge,
                ),
              ),
              ModeSelector(controller: ctrl),
              const SizedBox(height: 12),
              DifficultySelector(controller: ctrl),
            ],
          ),
        ),
      );
    },
  );
}

// ---------------------------------------------------------------------------
//  دیالوگ تأیید بازی جدید (مشترک بین شیت و AppBar)
// ---------------------------------------------------------------------------

void _confirmNewGame(BuildContext context, HomeController ctrl) {
  Get.defaultDialog(
    title: 'شروع بازی جدید',
    titleStyle: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: Theme.of(context).colorScheme.primary,
    ),
    middleText: 'آیا مطمئن هستید؟ جدول فعلی پاک می‌شود.',
    textCancel: 'نه',
    textConfirm: 'بله',
    buttonColor: Colors.blue,
    onConfirm: () {
      ctrl.newGame();
      Get.back();
    },
  );
}

/// دیالوگ تأیید بازی جدید برای استفاده عمومی (مثلاً از AppBar).
void confirmNewGameDialog(BuildContext context, HomeController ctrl) {
  _confirmNewGame(context, ctrl);
}

// ---------------------------------------------------------------------------
//  انتخابگر حالت بازی
// ---------------------------------------------------------------------------

class ModeSelector extends StatelessWidget {
  const ModeSelector({required this.controller, super.key});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selected = controller.gameMode.value;
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
                  _ModeCard(
                    mode: mode,
                    selected: selected,
                    width: cellWidth,
                    controller: controller,
                  ),
              ],
            );
          },
        ),
      );
    });
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.mode,
    required this.selected,
    required this.width,
    required this.controller,
  });

  final GameMode mode;
  final GameMode selected;
  final double width;
  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final color = HomeController.gameModeColor(mode);
    final isSelected = mode == selected;
    final dailyDisabled = mode == GameMode.daily && controller.dailyAttemptUsed;

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
          color: isSelected
              ? color.withValues(alpha: 0.16)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: dailyDisabled
                ? null
                : () => controller.changeMode(mode),
            child: Container(
              width: width,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? color
                      : color.withValues(alpha: 0.35),
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
}

// ---------------------------------------------------------------------------
//  انتخابگر سطح دشواری
// ---------------------------------------------------------------------------

class DifficultySelector extends StatelessWidget {
  const DifficultySelector({required this.controller, super.key});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // در چالش روزانه پازل ثابت است؛ سطح را نمی‌توان تغییر داد.
      if (controller.isDailyMode) {
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
                  controller.dailyDateLabel,
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
              'سطح: ${diffText(HomeController.dailyDifficulty)} (ثابت) — یک تلاش در روز',
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        );
      }
      return SegmentedButton<Difficulty>(
        segments: Difficulty.values.map((d) {
          return ButtonSegment<Difficulty>(
            value: d,
            label: Text(diffText(d)),
          );
        }).toList(),
        selected: {controller.difficulty.value},
        onSelectionChanged: (Set<Difficulty> newSelection) {
          final selected = newSelection.first;
          if (selected != controller.difficulty.value) {
            _confirmChangeDifficulty(context, controller, selected);
          }
        },
      );
    });
  }
}

void _confirmChangeDifficulty(
  BuildContext context,
  HomeController ctrl,
  Difficulty newDiff,
) {
  Get.defaultDialog(
    title: 'تغییر سطح',
    titleStyle: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: Theme.of(context).colorScheme.primary,
    ),
    middleText:
        'آیا می‌خواهید سطح را به "${diffText(newDiff)}" تغییر دهید؟\nجدول فعلی حذف می‌شود',
    textCancel: 'نه',
    textConfirm: 'بله',
    buttonColor: Colors.blueAccent,
    onConfirm: () {
      ctrl.difficulty.value = newDiff;
      Get.back();
    },
  );
}

/// دکمهٔ فشردهٔ حالت فعلی؛ لمس آن شیت «حالت و سطح» را باز می‌کند.
class ModeQuickButton extends StatelessWidget {
  const ModeQuickButton({
    required this.controller,
    required this.onPressed,
    super.key,
  });

  final HomeController controller;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final mode = controller.gameMode.value;
      final color = HomeController.gameModeColor(mode);
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: OutlinedButton.icon(
              onPressed: onPressed,
              icon: Icon(HomeController.gameModeIcon(mode), size: 18),
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      controller.modeTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.arrow_drop_down, size: 20),
                ],
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: color,
                side: BorderSide(color: color.withValues(alpha: 0.5)),
              ),
            ),
          ),
        ),
      );
    });
  }
}

// ---------------------------------------------------------------------------
//  توابع کمکی مشترک
// ---------------------------------------------------------------------------

String diffText(Difficulty d) => switch (d) {
  Difficulty.easy => 'آسان',
  Difficulty.medium => 'متوسط',
  Difficulty.hard => 'سخت',
};

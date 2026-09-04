import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../home_controller.dart';

/// نوار اعداد ۱ تا ۹ با دکمه حذف (عدد ۰) در پایین صفحه.
///
/// تمام state مربوط به `selectedNumber` و `numberUsage` را از
/// [HomeController] می‌خواند و فقط callback `onNumberSelected`
/// را به والد برمی‌گرداند.
class NumberBar extends StatelessWidget {
  const NumberBar({required this.controller, super.key});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!controller.isShow.value) {
        return const SizedBox.shrink();
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
                final cellSize =
                    ((constraints.maxWidth - gap * 9) / 10).clamp(28.0, 46.0);

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(10, (index) {
                    return _NumberTile(
                      number: index,
                      controller: controller,
                      cellSize: cellSize,
                    );
                  }),
                );
              },
            ),
          ),
        ),
      );
    });
  }
}

/// تایل تکی هر عدد در نوار — با Obx جداگانه تا فقط همان تایل بازسازی شود.
class _NumberTile extends StatelessWidget {
  const _NumberTile({
    required this.number,
    required this.controller,
    required this.cellSize,
  });

  final int number;
  final HomeController controller;
  final double cellSize;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final used = controller.numberUsage[number] ?? 0;
      final isSelected = controller.selectedNumber.value == number;
      final isDisabled = number != 0 && used >= 9;
      final isDelete = number == 0;

      final theme = Theme.of(context);
      final accent = isDelete ? Colors.red : Colors.blue;
      final tileColor = isSelected
          ? (isDelete
                ? Colors.red.shade700
                : Colors.blue.shade700)
          : theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.4);
      final borderColor = isSelected
          ? (isDelete ? Colors.redAccent : Colors.lightBlueAccent)
          : theme.colorScheme.outlineVariant;

      return GestureDetector(
        onTap: isDisabled
            ? null
            : () => controller.setNumber(number),
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
                  color: isSelected ? Colors.white : Colors.red.shade300,
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
  }
}

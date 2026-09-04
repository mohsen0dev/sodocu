import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../home_controller.dart';
import '../../abute/abute_page.dart';

/// نمایش شیت تنظیمات (راهنما، سوییچ‌ها، پاک‌سازی یادداشت‌ها و درباره).
Future<void> showSettingsSheet(BuildContext context, HomeController ctrl) {
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
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'تنظیمات',
                  style: Theme.of(sheetContext).textTheme.titleLarge,
                ),
              ),
              HelperCard(controller: ctrl),
              const SizedBox(height: 12),
              SettingsCard(controller: ctrl),
              const SizedBox(height: 12),
              CleanNotesButton(controller: ctrl),
              const SizedBox(height: 4),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('دربارهٔ بازی'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  Get.to(const AboutPage());
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

// ---------------------------------------------------------------------------
//  کارت راهنما
// ---------------------------------------------------------------------------

class HelperCard extends StatelessWidget {
  const HelperCard({required this.controller, super.key});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final theme = Theme.of(context);
      final disabled = !controller.hintsEnabled;
      final usedUp =
          controller.currentHelperUses.value >= controller.maxHelperUses;
      final remaining =
          controller.maxHelperUses - controller.currentHelperUses.value;
      final muted = disabled || usedUp;

      return Material(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: muted ? null : controller.useHelper,
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
                          color: muted
                              ? theme.colorScheme.onSurfaceVariant
                              : null,
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
}

// ---------------------------------------------------------------------------
//  کارت تنظیمات (سوییچ‌ها)
// ---------------------------------------------------------------------------

class SettingsCard extends StatelessWidget {
  const SettingsCard({required this.controller, super.key});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
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
            () => _SettingTile(
              icon: Icons.bolt_outlined,
              title: 'اعتبارسنجی فوری',
              subtitle: 'اعداد نادرست را بلافاصله قرمز نشان می‌دهد',
              value: controller.isActive.value,
              onChanged: (v) => controller.isActive.value = v,
            ),
          ),
          _settingsDivider(theme),
          Obx(
            () => _SettingTile(
              icon: Icons.keyboard_alt_outlined,
              title: 'نمایش اعداد ثابت',
              subtitle: 'نوار اعداد و ورود سریع در پایین صفحه',
              value: controller.isShow.value,
              onChanged: (v) {
                controller.isShow.value = v;
                controller.recalculateNumberUsage();
                controller.selectedNumber.value = 0;
              },
            ),
          ),
          _settingsDivider(theme),
          Obx(
            () => _SettingTile(
              icon: Icons.edit_note,
              title: 'حالت یادداشت',
              subtitle: 'یادداشت کاندیداها در خانه‌ها',
              value: controller.noteMode.value,
              onChanged: (v) => controller.toggleNoteMode(),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _settingsDivider(ThemeData theme) {
  return Divider(
    height: 1,
    indent: 16,
    endIndent: 16,
    color: theme.colorScheme.outlineVariant,
  );
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
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
}

// ---------------------------------------------------------------------------
//  دکمهٔ پاک‌سازی یادداشت‌های نامعتبر
// ---------------------------------------------------------------------------

class CleanNotesButton extends StatelessWidget {
  const CleanNotesButton({required this.controller, super.key});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final invalidCount = controller.invalidNotesCount();
      return OutlinedButton.icon(
        onPressed: invalidCount == 0
            ? null
            : () => _confirmCleanInvalidNotes(context, controller, invalidCount),
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
}

void _confirmCleanInvalidNotes(
  BuildContext context,
  HomeController ctrl,
  int invalidCount,
) {
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

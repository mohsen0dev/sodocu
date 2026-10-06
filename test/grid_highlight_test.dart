import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sodocu/home/home_controller.dart';
import 'package:sodocu/home/widgets/board_animations.dart';
import 'package:sodocu/main.dart';

/// قفلِ رفتارهای بصری جدول که نباید عوض شوند:
///
///  1. خانهٔ همان عددِ انتخاب‌شده بوردر **نارنجی** دارد (حالت عادی).
///  2. با روشن شدن «اعتبارسنجی فوری» بوردر بلوک‌ها **سبز** می‌شود.
///  3. هیچ هایلایتی برای خانه‌های همجوار/هم‌ردیف/هم‌بلوک وجود ندارد.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('بوردر نارنجی برای عدد انتخاب‌شده (خانهٔ ثابت و قابل ویرایش)', (
    WidgetTester tester,
  ) async {
    final ctrl = await _pumpLoadedApp(tester);

    final cells = _allCells(tester);
    expect(cells, isNotEmpty);

    // خانهٔ ثابت با عدد غیرصفر
    final fixed = cells.firstWhere((c) => ctrl.puzzle![c.row][c.col] != 0);
    final value = ctrl.cells[fixed.row][fixed.col].value;
    expect(value, isNot(0));

    ctrl.selectedNumber.value = value;
    await tester.pump();

    final fixedShown = _cellAt(tester, fixed.row, fixed.col);
    expect(fixedShown.borderColor, Colors.orange);
    expect(fixedShown.borderWidth, 3);

    // همان عدد را در یک خانهٔ قابل ویرایش قرار می‌دهیم
    final empty = cells.firstWhere(
      (c) =>
          ctrl.puzzle![c.row][c.col] == 0 &&
          ctrl.cells[c.row][c.col].value == 0,
    );
    ctrl.cells[empty.row][empty.col].value = value;
    ctrl.cells.refresh(); // همان‌طور که کنترلر بعد از هر تغییر انجام می‌دهد
    await tester.pump();

    final editableShown = _cellAt(tester, empty.row, empty.col);
    expect(editableShown.borderColor, Colors.orange);
    expect(editableShown.borderWidth, 1.5);
    // هایلایت «همان عدد» (پس‌زمینهٔ آبی) رفتار موجود است.
    expect(editableShown.backgroundColor, Colors.blue.withValues(alpha: 0.18));

    await _disposeApp(tester);
  });

  testWidgets('هیچ هایلایتی روی خانه‌های همجوار/هم‌ردیف اضافه نمی‌شود', (
    WidgetTester tester,
  ) async {
    final ctrl = await _pumpLoadedApp(tester);

    var cells = _allCells(tester);
    final target = cells.firstWhere(
      (c) =>
          ctrl.puzzle![c.row][c.col] == 0 &&
          ctrl.cells[c.row][c.col].value == 0,
    );

    ctrl.cells[target.row][target.col].value = 7;
    ctrl.cells.refresh();
    ctrl.selectedNumber.value = 7;
    await tester.pump();

    cells = _allCells(tester);
    for (final c in cells) {
      if (c.row == target.row && c.col == target.col) continue;
      final isFixed = ctrl.puzzle![c.row][c.col] != 0;
      final isEmptyEditable = !isFixed && ctrl.cells[c.row][c.col].value == 0;

      if (isEmptyEditable) {
        expect(
          c.backgroundColor,
          isNull,
          reason:
              'خانهٔ ${c.row},${c.col} نباید رنگ بگیرد؛ هایلایت همسایه نخواسته است.',
        );
        expect(c.borderColor, Colors.grey.shade300);
      } else if (isFixed && ctrl.cells[c.row][c.col].value != 7) {
        expect(c.backgroundColor, isNull);
        expect(c.borderColor, Colors.grey.shade500);
      }
    }

    await _disposeApp(tester);
  });

  testWidgets('بوردر سبز بلوک‌ها فقط با فعال بودن اعتبارسنجی فوری', (
    WidgetTester tester,
  ) async {
    final ctrl = await _pumpLoadedApp(tester);

    bool isGreenBlock(Widget w) =>
        w is Container &&
        w.decoration is BoxDecoration &&
        (w.decoration as BoxDecoration).border?.top.color == Colors.green &&
        (w.decoration as BoxDecoration).border?.top.width == 1.5;

    ctrl.isActive.value = false;
    await tester.pump();
    expect(find.byWidgetPredicate(isGreenBlock), findsNothing);

    ctrl.isActive.value = true;
    await tester.pump();
    expect(find.byWidgetPredicate(isGreenBlock), findsNWidgets(9));

    ctrl.isActive.value = false;
    await tester.pump();
    expect(find.byWidgetPredicate(isGreenBlock), findsNothing);

    await _disposeApp(tester);
  });
}

// ──────────────────────────────────────────────────────────────
//  کمکی‌ها
// ──────────────────────────────────────────────────────────────

Future<HomeController> _pumpLoadedApp(WidgetTester tester) async {
  Get.testMode = true;
  await tester.pumpWidget(const SudokuApp());

  final controller = Get.find<HomeController>();
  for (var i = 0; i < 200 && controller.isLoading.value; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(controller.isLoading.value, isFalse);
  await tester.pump();
  return controller;
}

List<AnimatedCellContainer> _allCells(WidgetTester tester) => tester
    .widgetList<AnimatedCellContainer>(find.byType(AnimatedCellContainer))
    .toList();

AnimatedCellContainer _cellAt(WidgetTester tester, int row, int col) =>
    tester.widget<AnimatedCellContainer>(
      find.byWidgetPredicate(
        (w) => w is AnimatedCellContainer && w.row == row && w.col == col,
      ),
    );

Future<void> _disposeApp(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpAndSettle();
  Get.reset();
}

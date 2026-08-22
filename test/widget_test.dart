import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:sodocu/home/home_controller.dart';
import 'package:sodocu/home/records_page.dart';
import 'package:sodocu/main.dart';

void main() {
  testWidgets('انتخاب عدد، هایلایت همان دکمه را به‌روزرسانی می‌کند', (
    WidgetTester tester,
  ) async {
    Get.testMode = true;
    await tester.pumpWidget(const SudokuApp());

    final controller = Get.find<HomeController>();
    for (var i = 0; i < 100 && controller.isLoading.value; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(controller.isLoading.value, isFalse);

    controller.isShow.value = true;
    controller.selectedNumber.value = 0;
    await tester.pump();

    final number = List.generate(9, (index) => index + 1).firstWhere(
      (value) => (controller.numberUsage[value] ?? 0) < 9,
    );
    final buttonFinder = find.byKey(ValueKey('number-button-$number'));
    expect(buttonFinder, findsOneWidget);
    await tester.ensureVisible(buttonFinder);
    await tester.pump();

    final before = tester.widget<AnimatedContainer>(buttonFinder);
    final beforeDecoration = before.decoration as BoxDecoration;
    expect(beforeDecoration.color, isNot(equals(Colors.blue.shade700)));

    await tester.tap(buttonFinder);
    await tester.pump();

    expect(controller.selectedNumber.value, number);
    final after = tester.widget<AnimatedContainer>(buttonFinder);
    final afterDecoration = after.decoration as BoxDecoration;
    expect(afterDecoration.color, equals(Colors.blue.shade700));
    expect(afterDecoration.border?.top.width, 2);

    Get.closeAllSnackbars();
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    Get.reset();
  });

  testWidgets('صفحه رکوردها رکوردها را نمایش می‌دهد و امکان حذف دارد', (
    WidgetTester tester,
  ) async {
    Get.testMode = true;
    final controller = HomeController();
    Get.put(controller);
    controller.bestTimes.assignAll({
      'classic.easy': 65,
      'classic.medium': 120,
      'timed.easy': 300,
    });
    controller.bestTimes.refresh();

    await tester.pumpWidget(const GetMaterialApp(home: RecordsPage()));
    await tester.pump();

    // نمایش زمان‌ها با فرمت دقیقه:ثانیه
    expect(find.text('01:05'), findsOneWidget);
    expect(find.text('02:00'), findsOneWidget);
    expect(find.text('05:00'), findsOneWidget);

    // حذف رکورد کلاسیک/آسان با تأیید در دیالوگ
    await tester.tap(find.byKey(const ValueKey('delete-classic-easy')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('حذف'));
    await tester.pumpAndSettle();

    expect(find.text('01:05'), findsNothing);
    expect(controller.bestTimeFor(GameMode.classic, Difficulty.easy), isNull);
    expect(controller.bestTimeFor(GameMode.classic, Difficulty.medium), 120);

    // پاک کردن همهٔ رکوردها
    await tester.tap(find.byKey(const ValueKey('reset-all')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('پاک کردن'));
    await tester.pumpAndSettle();

    expect(controller.bestTimes, isEmpty);
    expect(find.text('هنوز رکوردی ثبت نشده است'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    Get.reset();
  });
}

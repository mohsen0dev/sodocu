import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:sodocu/home/home_controller.dart';
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
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sodocu/home/home.dart';
import 'package:sodocu/home/home_controller.dart';
import 'package:sodocu/home/records_page.dart';
import 'package:sodocu/main.dart';

void main() {
  // SharedPreferences باید در محیط تست (دسکتاپ) شبیه‌سازی شود تا
  // `getInstance()` آویزان نماند و تایمر ۱ ثانیه‌ای `timeout` معلق نماند.
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

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

    // نمایش زمان‌ها با فرمت دقیقه:ثانیه (بهترین زمان کلی در داشبورد هم تکرار می‌شود)
    expect(find.text('01:05'), findsNWidgets(2));
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

  testWidgets('انتخاب‌گر حالت هر ۵ حالت و قوانین را نمایش می‌دهد', (
    WidgetTester tester,
  ) async {
    Get.testMode = true;
    await tester.pumpWidget(const SudokuApp());

    final controller = Get.find<HomeController>();
    for (var i = 0; i < 100 && controller.isLoading.value; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pump();
    expect(controller.isLoading.value, isFalse);

    // دکمهٔ فشردهٔ حالت در صفحهٔ اصلی
    expect(find.text('کلاسیک'), findsOneWidget);

    // باز کردن شیت «حالت و سطح»
    await tester.tap(find.byIcon(Icons.arrow_drop_down));
    await tester.pumpAndSettle();

    // هر ۵ حالت داخل شیت (کلاسیک هم در دکمهٔ پشت شیت هست)
    expect(find.text('کلاسیک'), findsNWidgets(2));
    expect(find.text('زمان‌دار (۵ دقیقه)'), findsOneWidget);
    expect(find.text('بدون راهنما'), findsOneWidget);
    expect(find.text('چالش روزانه'), findsOneWidget);
    expect(find.text('رقابت رکوردی'), findsOneWidget);

    // قوانین اصلی دو حالت خاص
    expect(
      find.text('رقابت با بهترین زمان؛ حداکثر ۳ خطا'),
      findsOneWidget,
    );
    expect(
      find.text('یک پازل ثابت در روز؛ فقط یک تلاش'),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    Get.reset();
  });

  // ──────────────────────────────────────────────────────────────
  //  دو حالت حل بازی (اجرای تست‌ها در محیط دسکتاپ با موس/کلیک)
  // ──────────────────────────────────────────────────────────────

  testWidgets(
    'حالت پیش‌فرض: لمس خانه، پیکر ۹ عدد را کنار خانه باز می‌کند و عدد ثبت می‌شود',
    (WidgetTester tester) async {
      await _pumpLoadedApp(tester);
      final controller = Get.find<HomeController>();
      expect(controller.isShow.value, isFalse);

      final cell = _findEmptyEditableCell(controller);
      final cellFinder = find.byKey(ValueKey('cell-${cell.row}-${cell.col}'));
      await tester.ensureVisible(cellFinder);
      await tester.pump();

      final tapPoint = tester.getCenter(cellFinder);
      await tester.tap(cellFinder);
      await tester.pump();

      // پیکر باز می‌شود و باید کنار خانهٔ لمس‌شده و داخل صفحه باشد.
      final pickerFinder = find.byKey(const ValueKey('number-picker'));
      expect(pickerFinder, findsOneWidget);

      final pickerRect = tester.getRect(pickerFinder);
      final screenRect = tester.getRect(find.byType(SudokuBoard));
      expect(pickerRect.top, lessThanOrEqualTo(tapPoint.dy));
      expect(screenRect.contains(pickerRect.topLeft), isTrue);
      expect(pickerRect.right, lessThanOrEqualTo(screenRect.right));
      expect(pickerRect.bottom, lessThanOrEqualTo(screenRect.bottom));

      // هر ۹ عدد داخل پیکر نمایش داده می‌شوند.
      final pickerNumbers = find.descendant(
        of: pickerFinder,
        matching: find.textContaining(RegExp(r'^[1-9]$')),
      );
      expect(pickerNumbers, findsNWidgets(9));

      // انتخاب یک کاندیدای معتبر، عدد را در خانه ثبت می‌کند و پیکر را می‌بندد.
      final allowed = controller.allowedNumbers(cell.row, cell.col);
      expect(allowed, isNotEmpty);
      final number = allowed.first;

      await tester.tap(
        find.descendant(of: pickerFinder, matching: find.text('$number')),
      );
      await tester.pump();

      expect(controller.cells[cell.row][cell.col].value, number);
      expect(pickerFinder, findsNothing);

      await _disposeApp(tester);
    },
  );

  testWidgets(
    'حالت کیبورد ثابت: از تنظیمات فعال می‌شود و عدد انتخاب‌شده با لمس خانه ثبت می‌گردد',
    (WidgetTester tester) async {
      await _pumpLoadedApp(tester);
      final controller = Get.find<HomeController>();
      expect(controller.isShow.value, isFalse);

      // باز کردن شیت تنظیمات و فعال‌سازی «نمایش اعداد ثابت»
      await tester.tap(find.byTooltip('تنظیمات'));
      await tester.pumpAndSettle();

      final switchTile = find.widgetWithText(
        SwitchListTile,
        'نمایش اعداد ثابت',
      );
      expect(switchTile, findsOneWidget);
      await tester.tap(find.descendant(of: switchTile, matching: find.byType(Switch)));
      await tester.pumpAndSettle();
      expect(controller.isShow.value, isTrue);

      Get.back();
      await tester.pumpAndSettle();

      // نوار اعداد ۱ تا ۹ در پایین صفحه نمایان است.
      final cell = _findEmptyEditableCell(controller);
      final cellFinder = find.byKey(ValueKey('cell-${cell.row}-${cell.col}'));
      await tester.ensureVisible(cellFinder);
      await tester.pump();

      final allowed = controller.allowedNumbers(cell.row, cell.col);
      expect(allowed, isNotEmpty);
      final number = allowed.first;

      final numberButton = find.byKey(ValueKey('number-button-$number'));
      expect(numberButton, findsOneWidget);
      await tester.tap(numberButton);
      await tester.pump();
      expect(controller.selectedNumber.value, number);

      // لمس خانه، همان عدد را بدون باز کردن پیکر ثبت می‌کند.
      await tester.tap(cellFinder);
      await tester.pump();

      expect(controller.cells[cell.row][cell.col].value, number);
      expect(find.byKey(const ValueKey('number-picker')), findsNothing);

      await _disposeApp(tester);
    },
  );
}

// ──────────────────────────────────────────────────────────────
//  کمکی‌های تست
// ──────────────────────────────────────────────────────────────

/// اپ را پمپ می‌کند و تا پایان بارگذاری پازل صبر می‌کند.
Future<void> _pumpLoadedApp(WidgetTester tester) async {
  Get.testMode = true;
  await tester.pumpWidget(const SudokuApp());

  final controller = Get.find<HomeController>();
  for (var i = 0; i < 200 && controller.isLoading.value; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(controller.isLoading.value, isFalse);
  await tester.pump();
}

/// اولین خانهٔ خالیِ قابل ویرایش را برمی‌گرداند.
({int row, int col}) _findEmptyEditableCell(HomeController controller) {
  for (var r = 0; r < 9; r++) {
    for (var c = 0; c < 9; c++) {
      final cell = controller.cells[r][c];
      if (!cell.isFixed && cell.value == 0) return (row: r, col: c);
    }
  }
  throw StateError('هیچ خانهٔ خالی قابل ویرایشی پیدا نشد');
}

/// ویجت ریشه را جمع می‌کند تا تایمر بازی در پایان تست معلق نماند.
Future<void> _disposeApp(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpAndSettle();
  Get.reset();
}

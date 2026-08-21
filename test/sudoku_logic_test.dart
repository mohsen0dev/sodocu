import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:sodocu/home/home_controller.dart';

/// یک جدول سودوکوی حل‌شدهٔ معتبر و ثابت.
///
/// این جدول برای ساخت پازل و تست توابع خالص به‌کار می‌رود تا نتایج تست‌ها
/// قطعی (غیرتصادفی) باشند.
const List<List<int>> solvedBoard = [
  [5, 3, 4, 6, 7, 8, 9, 1, 2],
  [6, 7, 2, 1, 9, 5, 3, 4, 8],
  [1, 9, 8, 3, 4, 2, 5, 6, 7],
  [8, 5, 9, 7, 6, 1, 4, 2, 3],
  [4, 2, 6, 8, 5, 3, 7, 9, 1],
  [7, 1, 3, 9, 2, 4, 8, 5, 6],
  [9, 6, 1, 5, 3, 7, 2, 8, 4],
  [2, 8, 7, 4, 1, 9, 6, 3, 5],
  [3, 4, 5, 2, 8, 6, 1, 7, 9],
];

/// تعداد خانه‌های پرشده (سرنخ‌ها)ی یک جدول.
int countClues(List<List<int>> board) {
  return board.fold(0, (sum, row) => sum + row.where((v) => v != 0).length);
}

void main() {
  group('boxIndex', () {
    test('خانه را به ناحیهٔ ۳×۳ درست نگاشت می‌کند', () {
      expect(HomeController.boxIndex(0, 0), 0);
      expect(HomeController.boxIndex(0, 8), 2);
      expect(HomeController.boxIndex(3, 3), 4);
      expect(HomeController.boxIndex(4, 4), 4);
      expect(HomeController.boxIndex(8, 0), 6);
      expect(HomeController.boxIndex(8, 8), 8);
    });
  });

  group('hasUniqueSolution', () {
    final controller = HomeController();

    test('جدول کامل حل‌شده فقط یک جواب دارد', () {
      expect(controller.hasUniqueSolution(solvedBoard), isTrue);
    });

    test('جدول حل‌شده با یک خانهٔ خالی فقط یک جواب دارد', () {
      final puzzle = solvedBoard.map((row) => [...row]).toList();
      puzzle[0][0] = 0;
      expect(controller.hasUniqueSolution(puzzle), isTrue);
    });

    test('جدول کاملاً خالی بیش از یک جواب دارد', () {
      final empty = List.generate(9, (_) => List.filled(9, 0));
      expect(controller.hasUniqueSolution(empty), isFalse);
    });

    test('جدول بدون جواب (تضاد در خانهٔ اول) یکتا محسوب نمی‌شود', () {
      final invalid = List.generate(9, (_) => List.filled(9, 0));
      // ردیف ۰ (به‌جز (0,0)) با ۱ تا ۸ پر شده؛ پس (0,0) فقط می‌تواند ۹ باشد.
      for (var c = 1; c <= 8; c++) {
        invalid[0][c] = c;
      }
      // اما ستون ۰ از قبل ۹ دارد؛ پس هیچ عددی در (0,0) جا نمی‌شود.
      invalid[1][0] = 9;
      expect(controller.hasUniqueSolution(invalid), isFalse);
    });
  });

  group('generatePuzzle', () {
    final controller = HomeController();

    test('با ۸۱ سرنخ، جدول حل‌شده بدون تغییر برمی‌گردد', () {
      expect(controller.generatePuzzle(solvedBoard, 81), equals(solvedBoard));
    });

    test('برای هر سطح دشواری پازل معتبر و یکتا تولید می‌کند', () {
      for (final entry in HomeController.cluesCount.entries) {
        final difficulty = entry.key;
        final clues = entry.value;
        final puzzle = controller.generatePuzzle(solvedBoard, clues);
        final clueCount = countClues(puzzle);

        expect(
          clueCount,
          lessThanOrEqualTo(clues),
          reason: '$difficulty باید حداکثر $clues سرنخ داشته باشد',
        );
        expect(
          clueCount,
          greaterThanOrEqualTo(clues - 5),
          reason: '$difficulty نباید خیلی کمتر از $clues سرنخ بماند',
        );
        expect(
          controller.hasUniqueSolution(puzzle),
          isTrue,
          reason: 'پازل $difficulty باید جواب یکتا داشته باشد',
        );

        // سرنخ‌ها باید با جواب نهایی مطابقت داشته باشند.
        for (var r = 0; r < 9; r++) {
          for (var c = 0; c < 9; c++) {
            if (puzzle[r][c] != 0) {
              expect(
                puzzle[r][c],
                solvedBoard[r][c],
                reason: 'سرنخ ($r,$c) با جواب نهایی نمی‌خواند',
              );
            }
          }
        }
      }
    });
  });

  group('HomeController - منطق بازی', () {
    late HomeController controller;

    setUp(() {
      Get.testMode = true;
      controller = HomeController();
      Get.put(controller);
    });

    tearDown(() {
      Get.reset();
    });

    test('toggleNote یادداشت را اضافه و حذف می‌کند', () {
      controller.toggleNote(0, 0, 5);
      expect(controller.cells[0][0].notes, contains(5));

      controller.toggleNote(0, 0, 5);
      expect(controller.cells[0][0].notes, isEmpty);
    });

    test('setCellNote از عدد انتخاب‌شده برای مدیریت کاندیدا استفاده می‌کند', () {
      controller.selectedNumber.value = 7;

      controller.setCellNote(0, 0);
      expect(controller.cells[0][0].notes, contains(7));

      controller.setCellNote(0, 0);
      expect(controller.cells[0][0].notes, isEmpty);
    });

    test('حذف همه یادداشت‌های یک خانه تاریخچه را ثبت می‌کند', () {
      controller.toggleNote(0, 0, 5);
      controller.toggleNote(0, 0, 7);

      controller.clearNotes(0, 0);

      expect(controller.cells[0][0].notes, isEmpty);
      expect(controller.canUndo.value, isTrue);
    });

    test('پاک‌سازی خودکار فقط کاندیداهای نامعتبر را حذف می‌کند', () {
      controller.cells[0][0].value = 5;
      controller.cells[0][1].notes.addAll({5, 6});

      expect(controller.invalidNotesCount(), 1);
      final removed = controller.removeInvalidNotes();

      expect(removed, 1);
      expect(controller.cells[0][1].notes, contains(6));
      expect(controller.cells[0][1].notes, isNot(contains(5)));
    });

    test('با ثبت عدد اصلی، همان کاندیدا از خانه‌های مرتبط حذف می‌شود', () {
      controller.toggleNote(0, 1, 5);
      controller.toggleNote(1, 0, 5);
      controller.toggleNote(1, 1, 5);

      controller.placeMainNumber(0, 0, 5);

      expect(controller.cells[0][1].notes, isEmpty);
      expect(controller.cells[1][0].notes, isEmpty);
      expect(controller.cells[1][1].notes, isEmpty);
      expect(controller.numberUsage[5], 1);
    });

    test('placeMainNumber عدد را در خانهٔ خالی قرار می‌دهد و تاریخچه ثبت می‌شود', () {
      controller.placeMainNumber(0, 0, 7);

      expect(controller.cells[0][0].value, 7);
      expect(controller.canUndo.value, isTrue);
    });

    test('setCellValue عدد انتخاب‌شده را قرار می‌دهد و با انتخاب دوباره حذف می‌کند', () {
      controller.isShow.value = true;
      controller.selectedNumber.value = 5;

      controller.setCellValue(0, 0);
      expect(controller.cells[0][0].value, 5);
      expect(controller.numberUsage[5], 1);

      controller.setCellValue(0, 0);
      expect(controller.cells[0][0].value, 0);
      expect(controller.numberUsage[5], 0);
    });

    test('isRowComplete ردیف کامل و ناقص را تشخیص می‌دهد', () {
      expect(controller.isRowComplete(0), isFalse);

      for (var c = 0; c < 9; c++) {
        controller.cells[0][c].value = c + 1;
      }

      expect(controller.isRowComplete(0), isTrue);
      expect(controller.isRowComplete(1), isFalse);
    });

    test('isColComplete ستون کامل را تشخیص می‌دهد', () {
      for (var r = 0; r < 9; r++) {
        controller.cells[r][0].value = r + 1;
      }

      expect(controller.isColComplete(0), isTrue);
      expect(controller.isColComplete(1), isFalse);
    });

    test('isBoxComplete ناحیهٔ ۳×۳ کامل را تشخیص می‌دهد', () {
      var n = 1;
      for (var r = 0; r < 3; r++) {
        for (var c = 0; c < 3; c++) {
          controller.cells[r][c].value = n++;
        }
      }

      expect(controller.isBoxComplete(0), isTrue);
      expect(controller.isBoxComplete(1), isFalse);
    });

    test('recalculateNumberUsage تعداد اعداد روی برد را بازشماری می‌کند', () {
      controller.cells[0][0].value = 3;
      controller.cells[1][1].value = 3;
      controller.cells[2][2].value = 9;

      controller.recalculateNumberUsage();

      expect(controller.numberUsage[3], 2);
      expect(controller.numberUsage[9], 1);
      expect(controller.numberUsage[1], 0);
    });
  });

  group('حالت چالش روزانه', () {
    late HomeController controller;

    setUp(() {
      Get.testMode = true;
      controller = HomeController();
      Get.put(controller);
    });

    tearDown(() {
      // توقف تایمر بازی تا تست با تایمر معلق تمام نشود.
      controller.onClose();
      Get.reset();
    });

    test('پازل روزانه در طول یک روز ثابت می‌ماند', () async {
      controller.gameMode.value = GameMode.daily;

      await controller.newGame();
      final first = controller.puzzle!.map((r) => [...r]).toList();

      await controller.newGame();
      final second = controller.puzzle!.map((r) => [...r]).toList();

      expect(first, equals(second));
      expect(controller.hasUniqueSolution(controller.puzzle!), isTrue);
    });

    test('پازل روزانه با سطح ثابت تولید می‌شود', () async {
      controller.gameMode.value = GameMode.daily;

      await controller.newGame();
      final clueCount = countClues(controller.puzzle!);
      final expected =
          HomeController.cluesCount[HomeController.dailyDifficulty]!;

      expect(clueCount, lessThanOrEqualTo(expected));
      expect(clueCount, greaterThanOrEqualTo(expected - 5));
    });
  });
}

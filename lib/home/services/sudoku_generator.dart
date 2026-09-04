import 'dart:math' show Random;

/// سرویس تولید، حل و اعتبارسنجی پازل سودوکو.
///
/// تمام متدها **static** و عاری از وابستگی به GetX یا state اپلیکیشن
/// هستند تا قابلیت تست واحد و استفادهٔ مجدد به حداکثر برسد.
class SudokuGenerator {
  SudokuGenerator._(); // غیرقابل نمونه‌سازی

  // ─────────────────────── اعتبارسنجی جایگذاری ───────────────────────

  /// آیا می‌توان عدد [number] را در خانهٔ [row],[col] قرار داد؟
  ///
  /// خود خانهٔ هدف (که مقدار قبلی‌اش بازنویسی می‌شود) نادیده گرفته می‌شود.
  static bool canPlace(List<List<int>> board, int row, int col, int number) {
    for (int c = 0; c < 9; c++) {
      if (c != col && board[row][c] == number) return false;
    }
    for (int r = 0; r < 9; r++) {
      if (r != row && board[r][col] == number) return false;
    }
    final startRow = (row ~/ 3) * 3;
    final startCol = (col ~/ 3) * 3;
    for (int r = startRow; r < startRow + 3; r++) {
      for (int c = startCol; c < startCol + 3; c++) {
        if ((r != row || c != col) && board[r][c] == number) return false;
      }
    }
    return true;
  }

  // ─────────────────────── تولید برد حل‌شده ───────────────────────

  /// یک برد ۹×۹ کاملاً حل‌شدهٔ معتبر تولید می‌کند.
  static List<List<int>> generateSolvedBoard({Random? random}) {
    final board = List.generate(9, (_) => List.filled(9, 0));
    _solve(board, random);
    return board;
  }

  /// حل بازگشتی سودوکو با Backtracking.
  /// اگر [random] داده شود، ترتیب کاندیداها تصادفی می‌شود.
  static bool _solve(List<List<int>> board, [Random? random]) {
    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        if (board[row][col] == 0) {
          final numbers = List.generate(9, (i) => i + 1)..shuffle(random);
          for (final num in numbers) {
            if (canPlace(board, row, col, num)) {
              board[row][col] = num;
              if (_solve(board, random)) return true;
              board[row][col] = 0;
            }
          }
          return false;
        }
      }
    }
    return true;
  }

  // ─────────────────────── تولید پازل ───────────────────────

  /// از یک برد حل‌شده، پازلی با [clues] خانهٔ پُر تولید می‌کند.
  ///
  /// تضمین یکتایی راه‌حل با بررسی `_countSolutions` تضمین می‌شود.
  static List<List<int>> generatePuzzle(
    List<List<int>> solved,
    int clues, {
    Random? random,
  }) {
    final puzzle = solved.map((row) => [...row]).toList();
    final indices = List.generate(81, (i) => i)..shuffle(random);
    int filledCells = 81;

    for (final idx in indices) {
      if (filledCells <= clues) break;
      final r = idx ~/ 9;
      final c = idx % 9;
      final backup = puzzle[r][c];
      puzzle[r][c] = 0;
      if (!hasUniqueSolution(puzzle)) {
        puzzle[r][c] = backup;
      } else {
        filledCells--;
      }
    }
    return puzzle;
  }

  // ─────────────────────── بررسی یکتایی راه‌حل ───────────────────────

  /// بررسی می‌کند پازل دقیقاً یک راه‌حل یکتا داشته باشد.
  static bool hasUniqueSolution(List<List<int>> puzzle) {
    final clone = puzzle.map((row) => [...row]).toList();
    return _countSolutions(clone, limit: 2) == 1;
  }

  /// تعداد جواب‌های جدول را می‌شمارد (حداکثر تا [limit] جواب).
  ///
  /// از MRV (Minimum Remaining Values) برای انتخاب خانهٔ بعدی استفاده می‌کند
  /// تا سرعت بررسی یکتایی بسیار بالاتر برود.
  static int _countSolutions(List<List<int>> grid, {int limit = 2}) {
    int solutions = 0;

    bool solve() {
      int row = -1;
      int col = -1;
      List<int>? bestCandidates;

      for (int r = 0; r < 9; r++) {
        for (int c = 0; c < 9; c++) {
          if (grid[r][c] != 0) continue;
          final candidates = [
            for (int number = 1; number <= 9; number++)
              if (canPlace(grid, r, c, number)) number,
          ];
          if (candidates.isEmpty) return false;
          if (bestCandidates == null ||
              candidates.length < bestCandidates.length) {
            row = r;
            col = c;
            bestCandidates = candidates;
            if (candidates.length == 1) break;
          }
        }
        if (bestCandidates?.length == 1) break;
      }

      if (bestCandidates == null) {
        solutions++;
        return solutions >= limit;
      }

      for (final number in bestCandidates) {
        grid[row][col] = number;
        if (solve()) return true;
        grid[row][col] = 0;
      }
      return false;
    }

    solve();
    return solutions;
  }

  // ─────────────────────── کمکی‌ها ───────────────────────

  /// تصویری از مقادیر فعلی سلول‌ها به صورت ماتریس اعداد صحیح (0 = خالی).
  static List<List<int>> currentBoard(
    List<List<CellLike>> cells,
  ) {
    return [
      for (int r = 0; r < 9; r++)
        [for (int c = 0; c < 9; c++) cells[r][c].value],
    ];
  }

  /// آیا پازل کاملاً حل شده است؟
  static bool isSolved(List<List<CellLike>> cells, List<List<int>> solution) {
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (cells[r][c].value == 0 || cells[r][c].value != solution[r][c]) {
          return false;
        }
      }
    }
    return true;
  }

  /// آیا عدد [value] با جواب نهایی در خانهٔ [row],[col] مطابقت دارد؟
  static bool isCorrect(
    List<List<int>> solution,
    int row,
    int col,
    int value,
  ) {
    return solution[row][col] == value;
  }

  /// اعداد مجاز برای خانهٔ [row],[col] در وضعیت فعلی برد.
  static List<int> allowedNumbers(
    List<List<CellLike>> cells,
    List<List<int>> solution,
    int row,
    int col,
  ) {
    if (solution.isEmpty) return [];
    if (cells[row][col].isFixed) return [cells[row][col].value];
    final board = currentBoard(cells);
    final result = <int>[];
    for (int n = 1; n <= 9; n++) {
      if (canPlace(board, row, col, n)) result.add(n);
    }
    return result;
  }
}

/// رابط سبک برای خواندن مقادیر سلول بدون وابستگی به کلاس کامل CellData.
abstract class CellLike {
  int get value;
  bool get isFixed;
}

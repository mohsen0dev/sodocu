import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// سطح دشواری بازی سودوکو
enum Difficulty { easy, medium, hard }

/// مدل داده برای هر خانه
class CellData {
  int value; // 0 = خالی
  Set<int> notes;
  bool isFixed; // آیا جزو پازل اولیه است (قابل تغییر نیست)

  CellData({this.value = 0, this.isFixed = false, Set<int>? notes})
    : notes = notes ?? {};

  CellData copy() {
    return CellData(value: value, isFixed: isFixed, notes: Set.from(notes));
  }
}

class HomeController extends GetxController {
  // ==================== متغیرهای اصلی ====================

  /// سلول‌های بازی (منبع واحد داده)
  late RxList<List<CellData>> cells;

  /// راه‌حل کامل و نهایی برد بازی
  List<List<int>>? _solution;

  /// لیستی از اعداد اولیه پازل
  List<List<int>>? puzzle;

  // ==================== وضعیت‌های UI ====================

  final int maxHelperUses = 3;
  var currentHelperUses = 0.obs;
  RxBool noteMode = false.obs;
  RxBool isActive = false.obs;

  /// نمایش اعداد ثابت (ویجت اعداد پایین صفحه)
  RxBool isShow = false.obs;

  Rx<Difficulty> difficulty = Difficulty.easy.obs;

  /// عدد انتخاب شده توسط کاربر (0 = حالت پاک کردن، 1-9 = اعداد)
  var selectedNumber = 0.obs;

  int? selectedRow;
  int? selectedCol;

  // شمارش تعداد استفاده از هر عدد 1 تا 9
  RxMap<int, int> numberUsage = RxMap<int, int>({
    for (var i = 1; i <= 9; i++) i: 0,
  });

  // ==================== تاریخچه (Undo/Redo) ====================

  final RxList<List<List<CellData>>> _undoStack = <List<List<CellData>>>[].obs;
  final RxList<List<List<CellData>>> _redoStack = <List<List<CellData>>>[].obs;
  RxBool canUndo = false.obs;
  RxBool canRedo = false.obs;

  // ==================== وضعیت بارگذاری ====================
  RxBool isLoading = false.obs;

  // ==================== ثابت‌ها ====================
  static const Map<Difficulty, int> cluesCount = {
    Difficulty.easy: 40,
    Difficulty.medium: 35,
    Difficulty.hard: 28,
  };

  static const int _maxPuzzleRetries = 20;
  int _currentRetryCount = 0;

  // ==================== مقداردهی اولیه ====================

  @override
  void onInit() {
    super.onInit();
    _initCells();
    ever(difficulty, (_) => newGame());
  }

  void _initCells() {
    cells = RxList.generate(9, (_) => List.generate(9, (_) => CellData()).obs);
  }

  // ==================== توابع کمکی ====================

  List<List<CellData>> _copyCells() {
    return List.generate(9, (i) => List.generate(9, (j) => cells[i][j].copy()));
  }

  void _restoreCells(List<List<CellData>> newCells) {
    for (int i = 0; i < 9; i++) {
      for (int j = 0; j < 9; j++) {
        cells[i][j].value = newCells[i][j].value;
        cells[i][j].isFixed = newCells[i][j].isFixed;
        cells[i][j].notes = Set.from(newCells[i][j].notes);
      }
    }
    cells.refresh();
  }

  void _saveToHistory() {
    _undoStack.add(_copyCells());
    _redoStack.clear();
    _updateHistoryButtons();
  }

  void _updateHistoryButtons() {
    canUndo.value = _undoStack.isNotEmpty;
    canRedo.value = _redoStack.isNotEmpty;
  }

  void undo() {
    if (_undoStack.isEmpty) return;
    _redoStack.add(_copyCells());
    _restoreCells(_undoStack.removeLast());
    _updateHistoryButtons();
    _showMessage('مرحله قبل بازگردانی شد', Colors.orange);
  }

  void redo() {
    if (_redoStack.isEmpty) return;
    _undoStack.add(_copyCells());
    _restoreCells(_redoStack.removeLast());
    _updateHistoryButtons();
    _showMessage('مرحله بعد بازیابی شد', Colors.orange);
  }

  // ==================== توابع اصلی بازی ====================

  /// تنظیم عدد انتخاب شده توسط کاربر
  void setNumber(int num) {
    selectedNumber.value = num;
    // اگر عدد 0 انتخاب شد (حذف)، حالت حذف فعال می‌شود
    if (num == 0) {
      _showMessage('حالت حذف فعال شد', Colors.red, duration: 1);
    } else {
      _showMessage('عدد $num انتخاب شد', Colors.blue, duration: 1);
    }
  }

  void toggleNoteMode() {
    noteMode.value = !noteMode.value;
    _showMessage(
      noteMode.value ? 'حالت یادداشت فعال شد' : 'حالت عادی فعال شد',
      Colors.blue,
      duration: 1,
    );
  }

  void selectCell(int r, int c) {
    selectedRow = r;
    selectedCol = c;
    update();
  }

  void placeMainNumber(int r, int c, int number) {
    if (cells[r][c].isFixed) {
      showError('این خانه قابل تغییر نیست!');
      return;
    }
    _saveToHistory();
    cells[r][c].value = number;
    cells[r][c].notes.clear();
    update();
  }

  void toggleNote(int r, int c, int number) {
    if (cells[r][c].isFixed) return;
    _saveToHistory();
    if (cells[r][c].notes.contains(number)) {
      cells[r][c].notes.remove(number);
    } else {
      cells[r][c].notes.add(number);
    }
    update();
  }

  /// تابع اصلی برای تنظیم مقدار خانه (مشابه کد اصلی شما)
  void setCellValue(int row, int col) {
    // اگر حالت نمایش اعداد فعال نیست، هیچ‌کاری نکن
    if (!isShow.value) return;

    final newNumber = selectedNumber.value;
    final prevValue = cells[row][col].value;

    // حالت حذف (عدد 0 انتخاب شده)
    if (newNumber == 0) {
      if (prevValue != 0 && !cells[row][col].isFixed) {
        _saveToHistory();
        // از شمارنده عدد قبلی کم کن
        numberUsage[prevValue] = (numberUsage[prevValue]! - 1).clamp(0, 9);
        cells[row][col].value = 0;
        cells[row][col].notes.clear();
        numberUsage.refresh();
        cells.refresh();
        _showMessage('عدد حذف شد', Colors.red, duration: 1);
      }
      return;
    }

    // اگر خانه عدد داشته باشد: از شمارنده عدد قبلی کم کن
    if (prevValue != 0) {
      numberUsage[prevValue] = (numberUsage[prevValue]! - 1).clamp(0, 9);
    }

    // اگر همان عدد دوباره انتخاب شد ⇒ حذف عدد (خالی‌کردن خانه)
    if (prevValue == newNumber) {
      _saveToHistory();
      cells[row][col].value = 0;
      cells[row][col].notes.clear();
      numberUsage.refresh();
      cells.refresh();
      return;
    }

    if (!_canPlaceCurrentBoard(row, col, newNumber)) {
      showError('عدد $newNumber در این خانه قابل قرار نیست!');
      // شمارنده را برگردان
      if (prevValue != 0) {
        numberUsage[prevValue] = (numberUsage[prevValue]! + 1).clamp(0, 9);
      }
      return;
    }

    // اگر عدد جدید بیش از ۹ بار استفاده شده، اجازه ورود نده
    if (numberUsage[newNumber]! >= 9) {
      showError('عدد $newNumber قبلاً ۹ بار استفاده شده!');
      // شمارنده را برگردان
      if (prevValue != 0) {
        numberUsage[prevValue] = (numberUsage[prevValue]! + 1).clamp(0, 9);
      }
      return;
    }

    // قرار دادن عدد جدید و بروزرسانی شمارنده
    _saveToHistory();
    cells[row][col].value = newNumber;
    cells[row][col].notes.clear();
    numberUsage[newNumber] = numberUsage[newNumber]! + 1;
    numberUsage.refresh();
    cells.refresh();

    // بررسی برنده شدن
    if (isSolved()) {
      _showSuccessDialog();
    }
  }

  /// تابع برای حذف عدد از یک خانه (برای دکمه حذف در پیکر)
  void clearCell(int row, int col) {
    if (cells[row][col].isFixed) {
      showError('این خانه قابل تغییر نیست!');
      return;
    }

    final prevValue = cells[row][col].value;
    if (prevValue != 0) {
      _saveToHistory();
      numberUsage[prevValue] = (numberUsage[prevValue]! - 1).clamp(0, 9);
      cells[row][col].value = 0;
      cells[row][col].notes.clear();
      numberUsage.refresh();
      cells.refresh();
      _showMessage('عدد حذف شد', Colors.red, duration: 1);
    }
  }

  // ==================== توابع بررسی اعتبار ====================

  bool isCorrect(int row, int col, int value) {
    if (_solution == null) return false;
    return _solution![row][col] == value;
  }

  bool _canPlace(List<List<int>> board, int row, int col, int number) {
    for (int c = 0; c < 9; c++) {
      if (board[row][c] == number) return false;
    }
    for (int r = 0; r < 9; r++) {
      if (board[r][col] == number) return false;
    }
    int startRow = (row ~/ 3) * 3;
    int startCol = (col ~/ 3) * 3;
    for (int r = startRow; r < startRow + 3; r++) {
      for (int c = startCol; c < startCol + 3; c++) {
        if (board[r][c] == number) return false;
      }
    }
    return true;
  }

  bool _canPlaceCurrentBoard(int row, int col, int number) {
    String numStr = number.toString();

    // بررسی سطر
    for (int c = 0; c < 9; c++) {
      if (c == col) continue;
      if (cells[row][c].value != 0 &&
          cells[row][c].value.toString() == numStr) {
        return false;
      }
    }

    // بررسی ستون
    for (int r = 0; r < 9; r++) {
      if (r == row) continue;
      if (cells[r][col].value != 0 &&
          cells[r][col].value.toString() == numStr) {
        return false;
      }
    }

    // بررسی بلوک 3x3
    int startRow = (row ~/ 3) * 3;
    int startCol = (col ~/ 3) * 3;
    for (int r = startRow; r < startRow + 3; r++) {
      for (int c = startCol; c < startCol + 3; c++) {
        if (r == row && c == col) continue;
        if (cells[r][c].value != 0 && cells[r][c].value.toString() == numStr) {
          return false;
        }
      }
    }
    return true;
  }

  List<int> allowedNumbers(int row, int col) {
    if (_solution == null) return [];
    if (cells[row][col].isFixed) return [cells[row][col].value];
    List<int> result = [];
    for (int n = 1; n <= 9; n++) {
      if (_canPlaceCurrentBoard(row, col, n)) result.add(n);
    }
    return result;
  }

  // ==================== راهنما ====================

  void useHelper() {
    if (currentHelperUses.value >= maxHelperUses || _solution == null) {
      if (currentHelperUses.value >= maxHelperUses) {
        showError('دیگر امکان استفاده از راهنما وجود ندارد.');
      }
      return;
    }

    List<MapEntry<int, int>> emptyCells = [];
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (cells[r][c].value == 0 && !cells[r][c].isFixed) {
          emptyCells.add(MapEntry(r, c));
        }
      }
    }

    if (emptyCells.isEmpty) {
      showError('هیچ خانه خالی برای پر کردن وجود ندارد!');
      return;
    }

    emptyCells.shuffle();
    final row = emptyCells.first.key;
    final col = emptyCells.first.value;
    final correctNumber = _solution![row][col];

    _saveToHistory();
    cells[row][col].value = correctNumber;
    cells[row][col].notes.clear();
    numberUsage[correctNumber] = (numberUsage[correctNumber] ?? 0) + 1;

    currentHelperUses.value++;
    cells.refresh();
    numberUsage.refresh();

    _showMessage('راهنما: خانه با عدد $correctNumber پر شد', Colors.blue);

    if (isSolved()) {
      _showSuccessDialog();
    }
  }

  // ==================== ساخت پازل ====================

  Future<void> newGame() async {
    if (isLoading.value) return;

    isLoading.value = true;
    _currentRetryCount = 0;

    try {
      await Future.delayed(Duration.zero);

      _solution = _generateSolvedBoard();
      final clues = cluesCount[difficulty.value]!;

      List<List<int>>? generatedPuzzle;
      bool isUnique = false;

      while (!isUnique && _currentRetryCount < _maxPuzzleRetries) {
        generatedPuzzle = generatePuzzle(_solution!, clues);
        if (hasUniqueSolution(generatedPuzzle)) {
          isUnique = true;
        } else {
          _currentRetryCount++;
        }
      }

      if (!isUnique) {
        showError('امکان تولید پازل یکتا وجود ندارد');
        isLoading.value = false;
        return;
      }

      puzzle = generatedPuzzle;
      currentHelperUses.value = 0;
      selectedNumber.value = 0;

      for (var i = 1; i <= 9; i++) {
        numberUsage[i] = 0;
      }

      _undoStack.clear();
      _redoStack.clear();
      _updateHistoryButtons();

      for (int i = 0; i < 9; i++) {
        for (int j = 0; j < 9; j++) {
          final num = puzzle![i][j];
          cells[i][j].value = num;
          cells[i][j].isFixed = num != 0;
          cells[i][j].notes.clear();
          if (num != 0) {
            numberUsage[num] = (numberUsage[num] ?? 0) + 1;
          }
        }
      }

      cells.refresh();
      numberUsage.refresh();
      _showMessage('بازی جدید شروع شد!', Colors.green);
    } catch (e) {
      showError('خطا در شروع بازی: $e');
    } finally {
      isLoading.value = false;
    }
  }

  List<List<int>> _generateSolvedBoard() {
    List<List<int>> board = List.generate(9, (_) => List.filled(9, 0));
    _solveSudoku(board);
    return board;
  }

  bool _solveSudoku(List<List<int>> board) {
    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        if (board[row][col] == 0) {
          List<int> numbers = List.generate(9, (i) => i + 1)..shuffle();
          for (int num in numbers) {
            if (_canPlace(board, row, col, num)) {
              board[row][col] = num;
              if (_solveSudoku(board)) return true;
              board[row][col] = 0;
            }
          }
          return false;
        }
      }
    }
    return true;
  }

  List<List<int>> generatePuzzle(List<List<int>> solved, int clues) {
    final puzzle = solved.map((row) => [...row]).toList();
    List<int> cells = List.generate(81, (i) => i)..shuffle();
    int filledCells = 81;

    for (int idx in cells) {
      if (filledCells <= clues) break;
      int r = idx ~/ 9;
      int c = idx % 9;
      int backup = puzzle[r][c];
      puzzle[r][c] = 0;
      if (!_hasUniqueSolutionFast(puzzle)) {
        puzzle[r][c] = backup;
      } else {
        filledCells--;
      }
    }
    return puzzle;
  }

  bool _hasUniqueSolutionFast(List<List<int>> grid) {
    final clone = grid.map((row) => [...row]).toList();
    return !_solveSudokuWithLimit(clone, limit: 2);
  }

  bool _solveSudokuWithLimit(List<List<int>> grid, {int limit = 2}) {
    int solutions = 0;
    bool solve() {
      int row = -1, col = -1;
      for (int r = 0; r < 9; r++) {
        for (int c = 0; c < 9; c++) {
          if (grid[r][c] == 0) {
            row = r;
            col = c;
            r = 9;
            break;
          }
        }
      }
      if (row == -1) {
        solutions++;
        return solutions >= limit;
      }
      for (int num = 1; num <= 9; num++) {
        if (_canPlace(grid, row, col, num)) {
          grid[row][col] = num;
          if (solve()) return true;
          grid[row][col] = 0;
        }
      }
      return false;
    }

    solve();
    return solutions >= limit;
  }

  bool hasUniqueSolution(List<List<int>> puzzle) {
    int solutionCount = 0;

    bool canPlaceHelper(List<List<int>> board, int row, int col, int number) {
      for (int c = 0; c < 9; c++) {
        if (board[row][c] == number) return false;
      }
      for (int r = 0; r < 9; r++) {
        if (board[r][col] == number) return false;
      }
      int startRow = (row ~/ 3) * 3;
      int startCol = (col ~/ 3) * 3;
      for (int r = startRow; r < startRow + 3; r++) {
        for (int c = startCol; c < startCol + 3; c++) {
          if (board[r][c] == number) return false;
        }
      }
      return true;
    }

    bool solve(List<List<int>> board) {
      for (int row = 0; row < 9; row++) {
        for (int col = 0; col < 9; col++) {
          if (board[row][col] == 0) {
            List<int> numbers = List.generate(9, (i) => i + 1)..shuffle();
            for (int num in numbers) {
              if (canPlaceHelper(board, row, col, num)) {
                board[row][col] = num;
                if (solve(board)) {
                  if (solutionCount > 1) return true;
                }
                board[row][col] = 0;
              }
            }
            return false;
          }
        }
      }
      solutionCount++;
      return solutionCount > 1;
    }

    List<List<int>> testBoard = puzzle
        .map((row) => row.map((cell) => cell).toList())
        .toList();
    solve(testBoard);
    return solutionCount == 1;
  }

  // ==================== توابع کمکی UI ====================

  bool isSolved() {
    if (_solution == null) return false;
    for (int i = 0; i < 9; i++) {
      for (int j = 0; j < 9; j++) {
        if (cells[i][j].value == 0 || cells[i][j].value != _solution![i][j]) {
          return false;
        }
      }
    }
    return true;
  }

  void recalculateNumberUsage() {
    for (var i = 1; i <= 9; i++) {
      numberUsage[i] = 0;
    }
    for (int i = 0; i < 9; i++) {
      for (int j = 0; j < 9; j++) {
        final value = cells[i][j].value;
        if (value != 0 && value >= 1 && value <= 9) {
          numberUsage[value] = (numberUsage[value] ?? 0) + 1;
        }
      }
    }
    numberUsage.refresh();
  }

  bool isInitialCell(int row, int col) {
    return puzzle != null && puzzle![row][col] != 0;
  }

  String getCellValue(int row, int col) {
    final val = cells[row][col].value;
    return val == 0 ? '' : val.toString();
  }

  Color getCellTextColor(int row, int col) {
    if (cells[row][col].isFixed) {
      return Colors.grey.shade400;
    }
    if (cells[row][col].value == 0) {
      return Colors.transparent;
    }
    if (!isActive.value) {
      return Colors.blue;
    }
    return isCorrect(row, col, cells[row][col].value)
        ? Colors.blue
        : Colors.red;
  }

  // ==================== پیام‌ها ====================

  void _showMessage(String message, Color color, {int duration = 2}) {
    Get.snackbar(
      '',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: color,
      colorText: Colors.white,
      duration: Duration(seconds: duration),
      margin: const EdgeInsets.all(10),
      borderRadius: 12,
    );
  }

  void showError(String message) {
    Get.snackbar(
      'خطا',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.shade700,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(10),
      borderRadius: 12,
    );
  }

  void _showSuccessDialog() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.emoji_events, size: 64, color: Colors.amber),
              const SizedBox(height: 16),
              const Text(
                'تبریک! 🎉',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'شما بازی را با موفقیت حل کردید!',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: const Text('بستن'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Get.back();
                      newGame();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                    child: const Text('بازی جدید'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }
}

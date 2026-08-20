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

  /// عددی که در حال نمایش افکت تکمیل ۹تایی است
  RxnInt celebratingNumber = RxnInt();

  /// واحدهای در حال جشن (row-0..8, col-0..8, box-0..8)
  RxSet<String> celebratingUnits = RxSet<String>();

  /// برای راه‌اندازی مجدد انیمیشن واحدها
  var celebrationToken = 0.obs;

  final Set<int> _completedRows = {};
  final Set<int> _completedCols = {};
  final Set<int> _completedBoxes = {};

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
    _syncCompletedUnits();
    celebratingUnits.clear();
    _showMessage('مرحله قبل بازگردانی شد', Colors.orange);
  }

  void redo() {
    if (_redoStack.isEmpty) return;
    _undoStack.add(_copyCells());
    _restoreCells(_redoStack.removeLast());
    _updateHistoryButtons();
    _syncCompletedUnits();
    celebratingUnits.clear();
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
    cells.refresh();
    _afterNumberPlaced(r, c, number);
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
        _syncCompletedUnits();
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
      _syncCompletedUnits();
      return;
    }

    if (!_canPlace(_currentBoard(), row, col, newNumber)) {
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
    _afterNumberPlaced(row, col, newNumber);

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
      _syncCompletedUnits();
      _showMessage('عدد حذف شد', Colors.red, duration: 1);
    }
  }

  // ==================== توابع بررسی اعتبار ====================

  bool isCorrect(int row, int col, int value) {
    if (_solution == null) return false;
    return _solution![row][col] == value;
  }

  /// بررسی می‌کند که آیا می‌توان عدد [number] را در خانه [row],[col] قرار داد.
  /// خود خانه هدف (که مقدار قبلی آن بازنویسی می‌شود) نادیده گرفته می‌شود.
  bool _canPlace(List<List<int>> board, int row, int col, int number) {
    for (int c = 0; c < 9; c++) {
      if (c != col && board[row][c] == number) return false;
    }
    for (int r = 0; r < 9; r++) {
      if (r != row && board[r][col] == number) return false;
    }
    int startRow = (row ~/ 3) * 3;
    int startCol = (col ~/ 3) * 3;
    for (int r = startRow; r < startRow + 3; r++) {
      for (int c = startCol; c < startCol + 3; c++) {
        if ((r != row || c != col) && board[r][c] == number) return false;
      }
    }
    return true;
  }

  /// تصویری از مقادیر فعلی برد به صورت ماتریس اعداد صحیح (0 = خالی).
  List<List<int>> _currentBoard() {
    return [
      for (int r = 0; r < 9; r++)
        [for (int c = 0; c < 9; c++) cells[r][c].value],
    ];
  }

  List<int> allowedNumbers(int row, int col) {
    if (_solution == null) return [];
    if (cells[row][col].isFixed) return [cells[row][col].value];
    final board = _currentBoard();
    final result = <int>[];
    for (int n = 1; n <= 9; n++) {
      if (_canPlace(board, row, col, n)) result.add(n);
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
    _afterNumberPlaced(row, col, correctNumber);

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
      celebratingNumber.value = null;
      celebratingUnits.clear();
      _completedRows.clear();
      _completedCols.clear();
      _completedBoxes.clear();

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
      _syncCompletedUnits();
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
      if (!hasUniqueSolution(puzzle)) {
        puzzle[r][c] = backup;
      } else {
        filledCells--;
      }
    }
    return puzzle;
  }

  /// تعداد جواب‌های جدول را می‌شمارد (حداکثر تا [limit] جواب).
  int _countSolutions(List<List<int>> grid, {int limit = 2}) {
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
    return solutions;
  }

  /// بررسی می‌کند که پازل فقط یک راه‌حل یکتا داشته باشد.
  bool hasUniqueSolution(List<List<int>> puzzle) {
    final clone = puzzle.map((row) => [...row]).toList();
    return _countSolutions(clone, limit: 2) == 1;
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
    final value = cells[row][col].value;
    if (value == 0) {
      return Colors.transparent;
    }
    if (_isNumberFullyPlaced(value)) {
      return Colors.grey.shade800;
    }
    if (cells[row][col].isFixed) {
      return Colors.grey.shade400;
    }
    if (!isActive.value) {
      return Colors.blue;
    }
    return isCorrect(row, col, value) ? Colors.blue : Colors.red;
  }

  bool _isNumberFullyPlaced(int number) => _countNumberOnBoard(number) >= 9;

  int _countNumberOnBoard(int number) {
    int count = 0;
    for (final row in cells) {
      for (final cell in row) {
        if (cell.value == number) count++;
      }
    }
    return count;
  }

  void _onNumberPlaced(int number) {
    if (number < 1 || number > 9) return;
    if (_countNumberOnBoard(number) != 9) return;
    celebratingNumber.value = number;
    Future.delayed(const Duration(milliseconds: 850), () {
      if (celebratingNumber.value == number) {
        celebratingNumber.value = null;
      }
    });
  }

  static int boxIndex(int row, int col) => (row ~/ 3) * 3 + (col ~/ 3);

  bool isCellCelebrating(int row, int col) {
    return celebratingUnits.contains('row-$row') ||
        celebratingUnits.contains('col-$col') ||
        celebratingUnits.contains('box-${boxIndex(row, col)}');
  }

  Color? getCompletedUnitBackground(int row, int col) {
    final done = _completedRows.contains(row) ||
        _completedCols.contains(col) ||
        _completedBoxes.contains(boxIndex(row, col));
    if (!done) return null;
    return Colors.teal.withValues(alpha: 0.18);
  }

  Color getCompletedUnitPeakBackground(int row, int col) {
    final done = _completedRows.contains(row) ||
        _completedCols.contains(col) ||
        _completedBoxes.contains(boxIndex(row, col));
    if (!done) return Colors.amber.withValues(alpha: 0.3);
    return Colors.teal.withValues(alpha: 0.38);
  }

  bool _isUnitValuesComplete(List<int> values) {
    if (values.length != 9 || values.any((v) => v == 0)) return false;
    return values.toSet().length == 9;
  }

  bool isRowComplete(int row) {
    return _isUnitValuesComplete([
      for (int c = 0; c < 9; c++) cells[row][c].value,
    ]);
  }

  bool isColComplete(int col) {
    return _isUnitValuesComplete([
      for (int r = 0; r < 9; r++) cells[r][col].value,
    ]);
  }

  bool isBoxComplete(int box) {
    final startRow = (box ~/ 3) * 3;
    final startCol = (box % 3) * 3;
    final values = <int>[];
    for (int r = startRow; r < startRow + 3; r++) {
      for (int c = startCol; c < startCol + 3; c++) {
        values.add(cells[r][c].value);
      }
    }
    return _isUnitValuesComplete(values);
  }

  void _syncCompletedUnits() {
    _completedRows.clear();
    _completedCols.clear();
    _completedBoxes.clear();
    for (int i = 0; i < 9; i++) {
      if (isRowComplete(i)) _completedRows.add(i);
      if (isColComplete(i)) _completedCols.add(i);
      if (isBoxComplete(i)) _completedBoxes.add(i);
    }
    cells.refresh();
  }

  void _afterNumberPlaced(int row, int col, int number) {
    _onNumberPlaced(number);
    _checkAndCelebrateUnits(row, col);
  }

  void _checkAndCelebrateUnits(int row, int col) {
    final newUnits = <String>[];

    if (isRowComplete(row) && _completedRows.add(row)) {
      newUnits.add('row-$row');
    } else if (!isRowComplete(row)) {
      _completedRows.remove(row);
    }

    if (isColComplete(col) && _completedCols.add(col)) {
      newUnits.add('col-$col');
    } else if (!isColComplete(col)) {
      _completedCols.remove(col);
    }

    final box = boxIndex(row, col);
    if (isBoxComplete(box) && _completedBoxes.add(box)) {
      newUnits.add('box-$box');
    } else if (!isBoxComplete(box)) {
      _completedBoxes.remove(box);
    }

    if (newUnits.isEmpty) return;

    celebratingUnits.addAll(newUnits);
    celebrationToken.value++;
    Future.delayed(const Duration(milliseconds: 950), () {
      celebratingUnits.removeAll(newUnits);
      cells.refresh();
    });
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

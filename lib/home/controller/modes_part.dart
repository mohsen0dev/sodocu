part of '../home_controller.dart';

/// پیکربندی حالت بازی: گترهای حالت، سطح مؤثر، چالش روزانه،
/// آنبوردینگ و تغییر حالت بازی.
extension HomeControllerModes on HomeController {
  // ─────────────────────── حالت‌ها و پیکربندی ───────────────────────

  /// راهنما در حالت «بدون راهنما» و «رقابت رکوردی» غیرفعال است
  /// تا رقابت رکوردی بدون هیچ کمکی قابل اعتماد بماند.
  bool get hintsEnabled =>
      gameMode.value != GameMode.noHints && gameMode.value != GameMode.record;
  bool get isDailyMode => gameMode.value == GameMode.daily;
  bool get isRecordMode => gameMode.value == GameMode.record;

  /// آیا خانهٔ [row],[col] همان خانهٔ آخرین خطای رکوردی است؟
  bool isMistakeCell(int row, int col) =>
      _mistakeRow == row && _mistakeCol == col;

  /// آیا پیکر عدد فقط کاندیداهای معتبر را فعال نشان می‌دهد؟
  bool get filterPickerCandidates =>
      gameMode.value != GameMode.record && gameMode.value != GameMode.noHints;

  /// آیا عدد [number] در پیکر خانهٔ [row],[col] قابل انتخاب است؟
  bool isPickerNumberEnabled(int row, int col, int number) {
    final cell = cells[row][col];
    if (cell.value != 0) return false;
    if (!filterPickerCandidates) return true;
    if (noteMode.value && cell.notes.contains(number)) return true;
    return allowedNumbers(row, col).contains(number);
  }

  /// سطح مؤثر: چالش روزانه همیشه از سطح ثابت استفاده می‌کند.
  Difficulty get _effectiveDifficulty =>
      isDailyMode ? HomeController.dailyDifficulty : difficulty.value;

  /// دانهٔ تصادفی بر اساس تاریخ جلالی
  int get _dailySeed {
    final j = jalaliFromGregorian(DateTime.now());
    return j.year * 10000 + j.month * 100 + j.day;
  }

  /// کلید رکورد بر اساس حالت و سطح مؤثر
  String get recordKey =>
      '${gameMode.value.name}.${_effectiveDifficulty.name}';

  String get modeTitle => HomeController.gameModeLabel(gameMode.value);

  String get dailyDateLabel => formatJalaliFull(DateTime.now());

  bool get dailyAttemptUsed =>
      _persistence?.loadDailyAttempt() == _todayKey;
  String get _todayKey => jalaliDateKey(DateTime.now());

  bool get onboardingSeen => _persistence?.isOnboardingSeen() ?? false;

  Future<void> markOnboardingSeen() async {
    await _persistence?.setOnboardingSeen();
  }

  Future<void> changeMode(GameMode mode) async {
    if (mode == gameMode.value) return;
    if (mode == GameMode.daily && dailyAttemptUsed) {
      showError('تلاش امروز قبلاً انجام شده است.');
      return;
    }
    gameMode.value = mode;
    await newGame();
  }
}

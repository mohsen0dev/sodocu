part of '../home_controller.dart';

/// بهترین زمان‌ها، آمار کلی بازی‌ها و استریک چالش روزانه.
extension HomeControllerRecords on HomeController {
  // ─────────────────────── بهترین زمان‌ها ───────────────────────

  bool _isNewRecord(int seconds) {
    final previous = bestTimes[recordKey];
    return previous == null || seconds < previous;
  }

  Future<void> _saveBestTime() async {
    final current = elapsedSeconds.value;
    if (!_isNewRecord(current)) return;
    bestTimes[recordKey] = current;
    bestTimes.refresh();
    await _persistBestTimes();
  }

  int? bestTimeFor(GameMode mode, Difficulty diff) {
    return bestTimes['${mode.name}.${diff.name}'];
  }

  Future<void> clearBestTime(GameMode mode, Difficulty diff) async {
    final key = '${mode.name}.${diff.name}';
    if (!bestTimes.containsKey(key)) return;
    bestTimes.remove(key);
    bestTimes.refresh();
    await _persistBestTimes();
  }

  Future<void> clearAllBestTimes() async {
    if (bestTimes.isEmpty) return;
    bestTimes.clear();
    bestTimes.refresh();
    await _persistBestTimes();
  }

  // ==================== آمار بازی‌ها ====================

  void _recordGameCompletion() {
    gamesCompleted.value++;
    totalCompletedSeconds.value += elapsedSeconds.value;
    if (isDailyMode) _recordDailyCompletion();
    unawaited(_persistStats());
  }

  void _recordDailyCompletion() {
    final today = _todayKey;
    final yesterday = jalaliDateKey(
      DateTime.now().subtract(const Duration(days: 1)),
    );
    _currentStreak = HomeController.nextDailyStreak(
      todayKey: today,
      yesterdayKey: yesterday,
      lastCompletedKey: _lastDailyCompletedKey,
      currentStreak: _currentStreak,
    );
    _lastDailyCompletedKey = today;
    if (_currentStreak > bestStreak.value) bestStreak.value = _currentStreak;
  }

  int? get averageCompletedSeconds => gamesCompleted.value == 0
      ? null
      : totalCompletedSeconds.value ~/ gamesCompleted.value;

  int? get overallBestTime {
    int? best;
    for (final value in bestTimes.values) {
      if (best == null || value < best) best = value;
    }
    return best;
  }

  String formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final rem = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${rem.toString().padLeft(2, '0')}';
  }
}

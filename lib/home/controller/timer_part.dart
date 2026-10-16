part of '../home_controller.dart';

/// تایمر بازی: شروع، تیک هر ثانیه و توقف/ذخیرهٔ هنگام خروج.
extension HomeControllerTimer on HomeController {
  // ─────────────────────── تایمر ───────────────────────

  void _startTimer() {
    _timer.start(
      interval: const Duration(seconds: 1),
      onTick: _onTimerTick,
    );
  }

  void _onTimerTick() {
    if (!_hasActiveGame || isLoading.value || isGameOver.value) return;
    elapsedSeconds.value++;
    if (gameMode.value == GameMode.timed) {
      remainingSeconds.value =
          (HomeController.timedGameSeconds - elapsedSeconds.value).clamp(
            0,
            HomeController.timedGameSeconds,
          );
      if (remainingSeconds.value == 0) _finishTimedGame();
    }
    if (elapsedSeconds.value % 5 == 0) _requestSave();
  }

  // ─────────────────────── توقف بازی ───────────────────────

  void stopGameTimer() {
    _timer.stop();
    _requestSave();
  }
}

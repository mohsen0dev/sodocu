part of '../home_controller.dart';

/// پایان بازی: پایان زمان، خطاهای رقابت رکوردی و دیالوگ‌های باخت.
extension HomeControllerGameOver on HomeController {
  // ─────────────────────── پایان بازی ───────────────────────

  void _finishTimedGame() {
    if (isGameOver.value) return;
    isGameOver.value = true;
    _hasActiveGame = false;
    _timer.stop();
    _deleteSavedGame();
    unawaited(HapticFeedback.heavyImpact());
    _showGameOverDialog();
  }

  void _showGameOverDialog() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.timer_off, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'زمان تمام شد!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'متأسفانه نتوانستید پازل را در ۵ دقیقه کامل کنید.',
                textAlign: TextAlign.center,
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
                      backgroundColor: Colors.red,
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

  void _handleRecordMistake(int row, int col, int number) {
    if (!isRecordMode) return;
    if (_solution == null || number == _solution![row][col]) return;
    mistakes.value++;
    _mistakeRow = row;
    _mistakeCol = col;
    mistakeFlashToken.value++;
    unawaited(HapticFeedback.mediumImpact());
    if (mistakes.value >= HomeController.maxMistakes) {
      _finishRecordGameByMistakes();
    }
  }

  void _finishRecordGameByMistakes() {
    if (isGameOver.value) return;
    isGameOver.value = true;
    _hasActiveGame = false;
    _timer.stop();
    _deleteSavedGame();
    unawaited(HapticFeedback.heavyImpact());
    _showMistakeGameOverDialog();
  }

  void _showMistakeGameOverDialog() {
    if (Get.testMode) return;
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.heart_broken, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'باخت!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'با ${HomeController.maxMistakes} اشتباه بازی را باختید.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'در رقابت رکوردی فقط ${HomeController.maxMistakes} خطا مجاز است؛ '
                'برای ثبت بهترین زمان باید پیش از خطای سوم پازل را کامل کنید.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
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
                      backgroundColor: Colors.red,
                    ),
                    child: const Text('تلاش دوباره'),
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

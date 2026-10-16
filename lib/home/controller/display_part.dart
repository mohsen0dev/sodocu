part of '../home_controller.dart';

/// نمایش خانه‌ها (مقدار/رنگ/پیشرفت) + پیام‌ها و دیالوگ پیروزی.
extension HomeControllerDisplay on HomeController {
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
      return Get.isDarkMode ? Colors.grey.shade600 : Colors.grey.shade800;
    }
    if (cells[row][col].isFixed) {
      return Get.isDarkMode ? Colors.grey.shade300 : Colors.grey.shade100;
    }
    if (!isActive.value && !isRecordMode) {
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

  // ==================== Progress Tracking ====================

  void _updateProgress() {
    int completed = 0;
    int empty = 0;
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (cells[r][c].value != 0) {
          completed++;
        } else {
          empty++;
        }
      }
    }
    completedCells.value = completed;
    emptyCells.value = empty;
  }

  // ==================== پیام‌ها ====================

  void _showMessage(String message, Color color, {int duration = 2}) {
    if (Get.testMode) return;
    Get.showSnackbar(
      GetSnackBar(
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: color,
        messageText: Text(message, style: TextStyle(color: Colors.white)),
        duration: Duration(seconds: duration),
        margin: const EdgeInsets.all(10),
        borderRadius: 12,
      ),
    );
  }

  void showError(String message) {
    if (Get.testMode) return;
    Get.showSnackbar(
      GetSnackBar(
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade700,
        messageText: Text(message, style: TextStyle(color: Colors.white)),
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(10),
        borderRadius: 12,
      ),
    );
  }

  void _showSuccessDialog({required bool isNewRecord}) {
    final recordMode = isRecordMode;
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
              Text(
                recordMode
                    ? (isNewRecord ? 'رکورد جدید! 🏆' : 'پازل کامل شد!')
                    : 'تبریک! 🎉',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (recordMode) ...[
                Text(
                  'زمان: ${formatDuration(elapsedSeconds.value)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  mistakes.value == 0
                      ? 'بدون خطا'
                      : '${mistakes.value} خطا',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
              ],
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

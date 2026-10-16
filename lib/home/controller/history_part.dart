part of '../home_controller.dart';

/// تاریخچهٔ بازی: اسنپ‌شات گرفتن، بازگردانی (undo) و بازیابی (redo).
extension HomeControllerHistory on HomeController {
  // ==================== توابع کمکی Undo/Redo ====================

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
    _saveSnapshotToHistory(_copyCells());
  }

  void _saveSnapshotToHistory(List<List<CellData>> snapshot) {
    _undoStack.add(snapshot);
    _redoStack.clear();
    _updateHistoryButtons();
  }

  void _updateHistoryButtons() {
    canUndo.value = _undoStack.isNotEmpty;
    canRedo.value = _redoStack.isNotEmpty;
  }

  void undo() {
    if (isGameOver.value) return;
    if (_undoStack.isEmpty) return;
    _redoStack.add(_copyCells());
    _restoreCells(_undoStack.removeLast());
    _updateHistoryButtons();
    recalculateNumberUsage();
    _syncCompletedUnits();
    celebratingUnits.clear();
    _requestSave();
    _showMessage('مرحله قبل بازگردانی شد', Colors.orange);
  }

  void redo() {
    if (isGameOver.value) return;
    if (_redoStack.isEmpty) return;
    _undoStack.add(_copyCells());
    _restoreCells(_redoStack.removeLast());
    _updateHistoryButtons();
    recalculateNumberUsage();
    _syncCompletedUnits();
    celebratingUnits.clear();
    _requestSave();
    _showMessage('مرحله بعد بازیابی شد', Colors.orange);
  }
}

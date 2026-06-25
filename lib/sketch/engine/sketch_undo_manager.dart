import '../domain/sketch_models.dart';

class SketchUndoManager {
  SketchUndoManager({this.maxDepth = 50});

  final int maxDepth;
  final List<SketchDocument> _undoStack = [];
  final List<SketchDocument> _redoStack = [];

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  void push(SketchDocument previous) {
    _undoStack.add(previous);
    if (_undoStack.length > maxDepth) {
      _undoStack.removeAt(0);
    }
    _redoStack.clear();
  }

  SketchDocument? undo(SketchDocument current) {
    if (_undoStack.isEmpty) return null;
    _redoStack.add(current);
    return _undoStack.removeLast();
  }

  SketchDocument? redo(SketchDocument current) {
    if (_redoStack.isEmpty) return null;
    _undoStack.add(current);
    return _redoStack.removeLast();
  }

  void reset() {
    _undoStack.clear();
    _redoStack.clear();
  }
}

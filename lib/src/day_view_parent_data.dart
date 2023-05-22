import 'package:calendar_day_view/calendar_day_view.dart';
import 'package:flutter/rendering.dart';

class DayViewWidgetParentData extends ContainerBoxParentData<RenderDayItemWidget> {
  DayViewWidgetParentData({
    required this.hourHeight,
    required this.date,
    required this.dragStep,
    bool draggable = false,
    this.isNewItem = false,
    this.left = 0,
  }) : _draggable = draggable;

  final double hourHeight;
  final DateTime date;
  final Duration dragStep;
  bool needsLayout = true;
  bool isNewItem;
  double left;

  bool _draggable;
  bool get draggable => _draggable;
  set draggable(bool value) {
    if (_draggable == value) return;

    _draggable = value;
    needsLayout = true;
  }

  int _numColumns = 1;
  int get numColumns => _numColumns;
  set numColumns(int value) {
    if (_numColumns == value) return;
    _numColumns = value;
    needsLayout = true;
  }

  int _startCol = -1;
  int get startCol => _startCol;
  set startCol(int value) {
    if (_startCol == value) return;
    _startCol = value;
    needsLayout = true;
  }

  int _colSpan = -1;
  int get colSpan => _colSpan;
  set colSpan(int value) {
    if (_colSpan == value) return;
    _colSpan = value;
    needsLayout = true;
  }

  int get endCol => startCol + colSpan;

  int? oldStartCol;
  int? oldColSpan;
  int? oldNumColumns;

  bool pendingColChange = false;
  bool pendingDragChange = false;
  bool firstLayout = true;

  void checkNeedsLayout() {
    if (!needsLayout) return;

    if (firstLayout) {
      firstLayout = false;
      return;
    }

    if (!pendingDragChange &&
        pendingColChange &&
        oldNumColumns == numColumns &&
        oldStartCol == startCol &&
        oldColSpan == colSpan) {
      needsLayout = false;
    }

    pendingColChange = false;
    pendingDragChange = false;
  }

  void reset() {
    oldStartCol = startCol;
    oldColSpan = colSpan;
    oldNumColumns = numColumns;

    numColumns = 1;
    startCol = -1;
    colSpan = -1;
  }
}

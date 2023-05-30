import 'dart:math';

import 'package:flutter_calendar_view/src/calendar_gesture_detector.dart';
import 'package:flutter_calendar_view/src/day_view_parent_data.dart';
import 'package:flutter_calendar_view/src/day_view_widget.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_calendar_view/src/extension.dart';

typedef DragHandlePainter = void Function(Canvas canvas, Size size);
typedef DragChildBuilder = Widget Function(DateTime start, DateTime end);

enum ToggleDraggableAction {
  onTap,
  onLongPress,
}

enum _ActiveHandle { start, end, middle }

class DayItemWidget extends SingleChildRenderObjectWidget {
  const DayItemWidget({
    super.key,
    super.child,
    required this.start,
    required this.end,
    this.onItemDragEnd,
    this.toggleDraggableAction = ToggleDraggableAction.onLongPress,
    this.drawTopDragHandle,
    this.drawBottomDragHandle,
    this.isForNewItem = false,
    this.minimumAppointmentDuration = const Duration(minutes: 15),
  });

  final bool isForNewItem;

  // The start time of the item in the day view.
  final DateTime start;

  // The end time of the item in the day view.
  final DateTime end;

  // Called after a item is dragged and modified.
  final ValueChanged<DateTimeRange>? onItemDragEnd;

  // The action that will trigger the item to be draggable. Either a tap or a long press.
  final ToggleDraggableAction? toggleDraggableAction;

  // The painter that will be used to draw the top drag handle. This exposes
  final DragHandlePainter? drawTopDragHandle;
  final DragHandlePainter? drawBottomDragHandle;

  final Duration minimumAppointmentDuration;

  @override
  RenderDayItemWidget createRenderObject(BuildContext context) {
    return RenderDayItemWidget(
      start: start,
      end: end,
      isForNewItem: isForNewItem,
      onItemDragEnd: onItemDragEnd,
      toggleDraggableAction: toggleDraggableAction,
      drawTopDragHandle: drawTopDragHandle,
      drawBottomDragHandle: drawBottomDragHandle,
      minimumAppointmentDuration: minimumAppointmentDuration,
    );
  }

  @override
  void updateRenderObject(BuildContext context, covariant RenderDayItemWidget renderObject) {
    renderObject
      ..start = start
      ..end = end
      ..isForNewItem = isForNewItem
      ..onItemDragEnd = onItemDragEnd
      ..toggleDraggableAction = toggleDraggableAction
      ..drawTopDragHandle = drawTopDragHandle
      ..drawBottomDragHandle = drawBottomDragHandle;
  }
}

class RenderDayItemWidget extends RenderBox with RenderObjectWithChildMixin<RenderObject>, WidgetsBindingObserver {
  RenderDayItemWidget({
    required DateTime start,
    required DateTime end,
    required Duration minimumAppointmentDuration,
    bool isForNewItem = false,
    ValueChanged<DateTimeRange>? onItemDragEnd,
    ToggleDraggableAction? toggleDraggableAction,
    DragHandlePainter? drawTopDragHandle,
    DragHandlePainter? drawBottomDragHandle,
  })  : _start = start,
        _end = end,
        _isForNewItem = isForNewItem,
        _onItemDragEnd = onItemDragEnd,
        _toggleDraggableAction = toggleDraggableAction,
        _drawTopDragHandle = drawTopDragHandle,
        _drawBottomDragHandle = drawBottomDragHandle,
        _minimumAppointmentDuration = minimumAppointmentDuration {
    WidgetsBinding.instance.addObserver(this);
  }

  final Duration _minimumAppointmentDuration;

  DateTime _start;
  DateTime _end;
  bool _isForNewItem;

  ValueChanged<DateTimeRange>? _onItemDragEnd;

  DateTime? _draggedStart;
  DateTime? get draggedStart => _draggedStart;
  set draggedStart(DateTime? value) {
    if (_draggedStart == value) return;
    _draggedStart = value;

    parentData?.pendingDragChange = true;
    parentData?.needsLayout = true;
  }

  DateTime? _draggedEnd;
  DateTime? get draggedEnd => _draggedEnd;
  set draggedEnd(DateTime? value) {
    if (_draggedEnd == value) return;
    _draggedEnd = value;

    parentData?.pendingDragChange = true;
    parentData?.needsLayout = true;
  }

  double _cumulativeDelta = 0;

  ToggleDraggableAction? _toggleDraggableAction;

  DragHandlePainter? _drawTopDragHandle;
  DragHandlePainter? _drawBottomDragHandle;

  _ActiveHandle? _activeHandle;

  CalendarGestureDetector? _gestureDetector;

  @override
  DayViewWidgetParentData? get parentData => super.parentData as DayViewWidgetParentData?;

  DateTimeRange get range {
    return DateTimeRange(start: start, end: end);
  }

  DateTime get start {
    return (draggedStart ?? _start).isBefore(parentData!.date) ? parentData!.date : (draggedStart ?? _start);
  }

  set start(DateTime value) {
    if (_start == value) return;
    _start = value;

    parentData?.needsLayout = true;
    if (!_isForNewItem) {
      markParentNeedsRecalculate();
    }
  }

  DateTime get end {
    return (draggedEnd ?? _end);
  }

  set end(DateTime value) {
    if (_end == value) return;
    _end = value;
    parentData?.needsLayout = true;

    if (!_isForNewItem) {
      markParentNeedsRecalculate();
    }
  }

  ToggleDraggableAction? get toggleDraggableAction => _toggleDraggableAction;
  set toggleDraggableAction(ToggleDraggableAction? value) {
    if (_toggleDraggableAction == value) return;
    _toggleDraggableAction = value;
  }

  DragHandlePainter? get drawTopDragHandle => _drawTopDragHandle;
  set drawTopDragHandle(DragHandlePainter? value) {
    if (_drawTopDragHandle == value) return;
    _drawTopDragHandle = value;
  }

  DragHandlePainter? get drawBottomDragHandle => _drawBottomDragHandle;
  set drawBottomDragHandle(DragHandlePainter? value) {
    if (_drawBottomDragHandle == value) return;
    _drawBottomDragHandle = value;
  }

  ValueChanged<DateTimeRange>? get onItemDragEnd => _onItemDragEnd;
  set onItemDragEnd(ValueChanged<DateTimeRange>? value) {
    if (_onItemDragEnd == value) return;
    _onItemDragEnd = value;
  }

  bool get isForNewItem => _isForNewItem;
  set isForNewItem(bool value) {
    if (_isForNewItem == value) return;
    _isForNewItem = value;
    markNeedsPaint();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Disable dragging when the app is paused
    if (state == AppLifecycleState.paused && parentData!.draggable) {
      _toggleDraggable();
    }
  }

  @override
  void setupParentData(covariant RenderObject child) {
    super.setupParentData(child);

    parentData?.draggable = false;
    parentData?.isNewItem = _isForNewItem;
    parentData?.firstLayout = true;
  }

  void _toggleDraggable() {
    parentData!.draggable = !parentData!.draggable;
    markNeedsPaint();
    markParentCountDraggables();
  }

  void _onVerticalDragStart(double yOffset) {
    if (!parentData!.draggable) {
      return;
    }

    final draggingStart = yOffset < dragHandleHeight;
    final draggingEnd = yOffset > size.height - dragHandleHeight;

    if (draggingStart) {
      _activeHandle = _ActiveHandle.start;
    } else if (draggingEnd) {
      _activeHandle = _ActiveHandle.end;
    } else {
      _activeHandle = _ActiveHandle.middle;
    }
  }

  void _onVerticalDragUpdate(double delta) {
    if (parentData!.draggable && _activeHandle != null) {
      _cumulativeDelta += delta;

      final seconds = (_cumulativeDelta / parentData!.hourHeight * 3600).round();

      if (seconds.abs() <= parentData!.dragStep.inSeconds) return;

      DateTime newStart = start;
      DateTime newEnd = end;

      _cumulativeDelta = 0;
      if (_activeHandle == _ActiveHandle.start) {
        newStart = start.add(Duration(seconds: seconds));
      } else if (_activeHandle == _ActiveHandle.end) {
        newEnd = end.add(Duration(seconds: seconds));
      } else if (_activeHandle == _ActiveHandle.middle) {
        newStart = start.add(Duration(seconds: seconds));
        newEnd = end.add(Duration(seconds: seconds));
      }

      final oldDuration = start.difference(end).abs();
      final newDuration = newStart.difference(newEnd).abs();

      // If the new start day is before the parent day, set it to the parent day to stay on the same day
      if (newStart.day != parentData!.date.day) {
        newStart = parentData!.date.startOfDay;

        if (_activeHandle == _ActiveHandle.middle) {
          newEnd = newStart.add(oldDuration);
        }
      }

      // If the new end day is after the parent day, set it to the parent day to stay on the same day
      if (newEnd.day != parentData!.date.day) {
        newEnd = parentData!.date.endOfDay;

        if (_activeHandle == _ActiveHandle.middle) {
          newStart = newEnd.subtract(oldDuration);
        }
      }

      // Make sure the appointment is at least the minimum duration
      if (_activeHandle != _ActiveHandle.middle && newDuration < _minimumAppointmentDuration) {
        return;
      }

      draggedStart = newStart;
      draggedEnd = newEnd;

      parentData!.needsLayout = true;
      markParentNeedsRecalculate();
    }
  }

  @override
  void attach(covariant PipelineOwner owner) {
    super.attach(owner);

    _gestureDetector ??= CalendarGestureDetector(
      onTap: _toggleDraggableAction == ToggleDraggableAction.onTap ? _toggleDraggable : null,
      onLongPress: _toggleDraggableAction == ToggleDraggableAction.onLongPress ? _toggleDraggable : null,
      onVerticalDragStart: _onVerticalDragStart,
      onVerticalDragUpdate: _onVerticalDragUpdate,
    );
  }

  @override
  void handleEvent(PointerEvent event, covariant HitTestEntry<HitTestTarget> entry) {
    assert(debugHandleEvent(event, entry));

    _gestureDetector?.handleEvent(event);
  }

  Size _performLayout(BoxConstraints constraints, {required bool dry}) {
    final hourHeight = parentData!.hourHeight;

    final start = this.start;
    final end = this.end;

    final startOffset = (start.hour + (start.minute / 60)) * hourHeight;
    final endOffset = (end.hour + (end.minute / 60)) * hourHeight;

    // Min height should be a fourth of the hour height (15 minutes)
    final height = max(endOffset - startOffset, (hourHeight / 4));
    final maxWidth = (constraints.maxWidth - parentData!.left);
    final columnWidth = maxWidth / parentData!.numColumns;
    final width = parentData!.isNewItem ? maxWidth : columnWidth * parentData!.colSpan;

    if (!dry) {
      final childConstraints = BoxConstraints(
        maxWidth: width,
        minWidth: width,
        maxHeight: height,
        minHeight: height,
      );
      child?.layout(childConstraints);
    }

    return Size(width, height);
  }

  void stopDragging() {
    parentData!.draggable = false;
    onItemDragEnd?.call(range);

    _activeHandle = null;
    _cumulativeDelta = 0;
    draggedStart = null;
    draggedEnd = null;

    parentData!.needsLayout = true;
    markNeedsPaint();
  }

  @override
  void performLayout() {
    if (parentData?.needsLayout == true) {
      size = _performLayout(constraints, dry: false);
      parentData?.needsLayout = false;
    }
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    return _performLayout(constraints, dry: true);
  }

  double get dragHandleHeight => 20;

  @override
  void paint(PaintingContext context, Offset offset) {
    final childParentData = child?.parentData as BoxParentData;
    final topLeft = childParentData.offset + offset;

    if (child != null) {
      context.paintChild(child!, topLeft);
    }

    if (parentData?.draggable == true) {
      context.canvas.save();
      context.canvas.translate(topLeft.dx, topLeft.dy);

      drawTopDragHandle?.call(context.canvas, size);
      drawBottomDragHandle?.call(context.canvas, size);

      context.canvas.restore();
    }
  }

  void markParentNeedsRecalculate() {
    // Can happen with the dragging of a new item
    if (this.parent == null) return;

    final RenderObject parent = this.parent! as RenderObject;
    if (parent is RenderDayViewWidget) {
      parent.markNeedsRecalculate();
    }
  }

  void markParentCountDraggables() {
    // Can happen with the dragging of a new item
    if (this.parent == null) return;

    final RenderObject parent = this.parent! as RenderObject;
    if (parent is RenderDayViewWidget) {
      parent.markCountDraggables();
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    if (this.child == null) return false;
    if (this.child is! RenderBox) return false;

    if (parentData?.draggable == true) return true;

    final child = this.child as RenderBox;
    final childParentData = child.parentData as BoxParentData;

    return result.addWithPaintOffset(
      offset: childParentData.offset,
      position: position,
      hitTest: (BoxHitTestResult result, Offset transformed) {
        assert(transformed == position - childParentData.offset);
        return child.hitTest(result, position: transformed);
      },
    );
  }
}

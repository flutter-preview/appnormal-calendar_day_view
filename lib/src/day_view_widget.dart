import 'dart:math';

import 'package:flutter_calendar_view/flutter_calendar_view.dart';
import 'package:flutter_calendar_view/src/calendar_gesture_detector.dart';
import 'package:flutter_calendar_view/src/day_view_parent_data.dart';
import 'package:flutter_calendar_view/src/extension.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

typedef CanIndexDragCallback<T> = bool Function(T item);

class DayViewWidget<T> extends MultiChildRenderObjectWidget {
  DayViewWidget({
    Key? key,
    required List<Widget> children,
    required ValueGetter<Widget> onNewItemBuilder,
    required this.height,
    required this.date,
    this.leftInset = 55,
    this.dragStep = const Duration(seconds: 1),
    this.minimumDuration = const Duration(minutes: 15),
    this.canDragItem,
    this.onNewEvent,
    this.onDraggingStateChange,
    this.textStyle = const TextStyle(
      color: Colors.black,
      fontWeight: FontWeight.w600,
    ),
  }) : super(
          key: key,
          children: [
            ...children,
            DayItemWidget(
              start: date,
              end: date,
              child: onNewItemBuilder(),
            ),
          ],
        );

  final double height;
  final double leftInset;
  final Duration dragStep;
  final Duration minimumDuration;
  final DateTime date;
  final TextStyle textStyle;

  final CanIndexDragCallback<T>? canDragItem;
  final ValueSetter<DateTimeRange>? onNewEvent;
  final ValueSetter<bool>? onDraggingStateChange;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderDayViewWidget<T>(
      height: height,
      date: date,
      dragStep: dragStep,
      minimumDuration: minimumDuration,
      canDragItem: canDragItem,
      onNewEvent: onNewEvent,
      onDraggingStateChange: onDraggingStateChange,
      leftInset: leftInset,
      textStyle: textStyle,
    );
  }

  @override
  void updateRenderObject(BuildContext context, covariant RenderDayViewWidget<T> renderObject) {
    renderObject
      ..height = height
      ..date = date
      ..dragStep = dragStep
      ..minimumDuration = minimumDuration
      ..leftInset = leftInset
      ..onDraggingStateChange = onDraggingStateChange
      ..canDragItem = canDragItem
      ..onNewEvent = onNewEvent
      ..textStyle = textStyle;
  }
}

class RenderDayViewWidget<T> extends RenderBox
    with
        ContainerRenderObjectMixin<RenderDayItemWidget, DayViewWidgetParentData>,
        RenderBoxContainerDefaultsMixin<RenderDayItemWidget, DayViewWidgetParentData> {
  RenderDayViewWidget({
    required double height,
    required DateTime date,
    required Duration dragStep,
    required Duration minimumDuration,
    required ValueSetter<DateTimeRange>? onNewEvent,
    required ValueSetter<bool>? onDraggingStateChange,
    required CanIndexDragCallback<T>? canDragItem,
    required double leftInset,
    required TextStyle textStyle,
  })  : _height = height,
        _date = date,
        _dragStep = dragStep,
        _minimumDuration = minimumDuration,
        _canDragItem = canDragItem,
        _onNewEvent = onNewEvent,
        _onDraggingStateChange = onDraggingStateChange,
        _leftInset = leftInset,
        _textStyle = textStyle;

  late double _height;
  set height(double value) {
    if (_height == value) return;
    _height = value;
    markNeedsLayout();
  }

  late DateTime _date;
  set date(DateTime value) {
    if (_date == value) return;
    _date = value;
    markNeedsPaint();
  }

  late ValueSetter<DateTimeRange>? _onNewEvent;
  set onNewEvent(ValueSetter<DateTimeRange>? value) {
    if (_onNewEvent == value) return;
    _onNewEvent = value;
  }

  late ValueSetter<bool>? _onDraggingStateChange;
  set onDraggingStateChange(ValueSetter<bool>? value) {
    if (_onDraggingStateChange == value) return;
    _onDraggingStateChange = value;
  }

  late TextStyle _textStyle;
  set textStyle(TextStyle value) {
    if (_textStyle == value) return;
    _textStyle = value;
    markNeedsPaint();
  }

  late double _leftInset;
  set leftInset(double value) {
    if (_leftInset == value) return;
    _leftInset = value;
    markNeedsPaint();
  }

  late Duration _dragStep;
  set dragStep(Duration value) {
    if (_dragStep == value) return;
    _dragStep = value;
  }

  late Duration _minimumDuration;
  set minimumDuration(Duration value) {
    if (_minimumDuration == value) return;
    _minimumDuration = value;
  }

  CanIndexDragCallback<T>? _canDragItem;
  set canDragItem(CanIndexDragCallback<T>? value) {
    if (_canDragItem == value) return;
    _canDragItem = value;
  }

  CalendarGestureDetector? _gestureDetector;

  DateTime? _dragStart;
  DateTime? _dragEnd;
  int numColumns = 1;

  @override
  void attach(covariant PipelineOwner owner) {
    super.attach(owner);

    print('Test');
    _gestureDetector ??= CalendarGestureDetector(
      onTap: _handleOnTap,
      onLongPress: _startDragging,
      onVerticalDragUpdate: _updateDragging,
      onVerticalDragEnd: _endDragging,
      longPressDragEnabled: true,
      onChildHit: (offset) => hitTestChildren(BoxHitTestResult(), position: offset),
    );
  }

  @override
  void handleEvent(PointerEvent event, covariant HitTestEntry<HitTestTarget> entry) {
    assert(debugHandleEvent(event, entry));

    _gestureDetector?.handleEvent(event);
  }

  bool stopDragging() {
    bool didStopDragging = false;
    // Stop dragging any existing children
    loopChildren((child) {
      if (child.parentData?.draggable == true) {
        child.stopDragging();
        didStopDragging = true;
      }
    });

    _gestureDetector?.stopDragging();

    // Stop dragging any new items
    if (_dragEnd != null || _dragStart != null) didStopDragging = true;
    _dragEnd = null;
    _dragStart = null;

    markNeedsPaint();

    return didStopDragging;
  }

  void _handleOnTap() {
    final tapLocation = _gestureDetector?.lastPointer;
    final stoppedDragging = stopDragging();
    if (!stoppedDragging && tapLocation != null) {
      final range = offsetToDateTime(tapLocation.dy);
      final start = range.copyWith(minute: 0);
      final end = start.add(const Duration(hours: 1));
      _onNewEvent?.call(DateTimeRange(start: start, end: end));
    }

    markCountDraggables();
  }

  void _startDragging() {
    final offset = _gestureDetector?.lastPointer;
    if (offset == null) return;
    final yOffset = offset.dy;

    _gestureDetector?.startDragging();

    _dragStart = offsetToDateTime(yOffset);
    _dragEnd = _dragStart?.copyWith().add(_minimumDuration);
    markDragNeedsLayout();
  }

  void _updateDragging(double delta) {
    final offset = _gestureDetector?.lastPointer;
    if (offset == null || _dragStart == null) return;

    final yOffset = offset.dy;

    DateTime newEnd = offsetToDateTime(yOffset);
    if (newEnd.day != _dragStart?.day) {
      if (newEnd.day > _dragStart!.day) {
        newEnd = _dragStart!.endOfDay;
      } else {
        newEnd = _dragStart!.startOfDay;
      }
    }

    _dragEnd = newEnd;

    markDragNeedsLayout();
  }

  void _endDragging(double delta) {
    final range = dragRange;
    if (range == null) return;

    _onNewEvent?.call(range);

    _dragEnd = null;
    _dragStart = null;

    markNeedsPaint();
  }

  DateTimeRange? get dragRange {
    if (_dragStart == null || _dragEnd == null) {
      return null;
    }

    var start = _dragStart!;
    var end = _dragEnd!;

    if (end.isBefore(start)) {
      final temp = start;
      start = end;
      end = temp;
    }

    // Adhere to min duration
    if (end.difference(start) < _minimumDuration) {
      end = start.add(_minimumDuration);
    }

    return DateTimeRange(start: start, end: end);
  }

  DateTime offsetToDateTime(double yOffset) {
    final hourHeight = _height / 24;
    final hour = yOffset ~/ hourHeight;
    final hourExact = yOffset / hourHeight;

    // Minutes go in intervals
    var minutes = ((yOffset % hourHeight) / hourHeight * 60).round();
    minutes = (minutes ~/ _dragStep.inMinutes) * _dragStep.inMinutes;

    if (hourExact < 0) {
      return _date.startOfDay.subtract(Duration(hours: hour.abs(), minutes: minutes.abs()));
    } else {
      return _date.startOfDay.add(Duration(hours: hour, minutes: minutes));
    }
  }

  @override
  void setupParentData(covariant RenderObject child) {
    bool resetColumns = false;

    if (child.parentData is! DayViewWidgetParentData) {
      // New child, we need to recalculate columns
      resetColumns = true;

      // Give the new child a fresh parent data

      child.parentData = DayViewWidgetParentData<T>(
        hourHeight: _height / 24,
        date: _date.startOfDay,
        canDragItem: _canDragItem,
        left: _leftInset,
        dragStep: _dragStep,
        minimumDuration: _minimumDuration,
      );
    }

    if (resetColumns) markNeedsRecalculate();
  }

  Size _performLayout(BoxConstraints constraints) {
    return Size(constraints.maxWidth, _height);
  }

  void layoutChild(RenderDayItemWidget child) {
    final childParentData = child.parentData!;

    final colWidth = (size.width - _leftInset) / numColumns;

    final yOffset = (child.start.hour + (child.start.minute / 60)) * (_height / 24);
    final xOffset = _leftInset + (colWidth * childParentData.startCol);

    childParentData.offset = Offset(xOffset, yOffset);

    child.layout(
      constraints.copyWith(
        minWidth: 0,
        maxHeight: _height,
      ),
    );
  }

  @override
  void performLayout() {
    size = _performLayout(constraints);

    _calculateColumns();

    loopChildren((child) {
      if (child.parentData!.isNewItem) return;

      layoutChild(child);
    });
  }

  void markDragNeedsLayout() {
    loopChildren((child) {
      if (!child.parentData!.isNewItem) return;

      child.parentData!.startCol = 0;
      child.parentData!.numColumns = 1;
      child.parentData!.colSpan = 1;

      final range = dragRange;
      if (range == null) return;

      child.start = range.start;
      child.end = range.end;

      child.markNeedsLayout();
      layoutChild(child);
    });

    markNeedsPaint();
  }

  void markNeedsRecalculate() {
    loopChildren((child) {
      child.parentData!.reset();
      child.markNeedsLayout();
    });
    markNeedsLayout();
  }

  void markCountDraggables() {
    int draggableCount = 0;
    loopChildren((child) {
      if (child.parentData!.draggable) draggableCount++;
    });

    _onDraggingStateChange?.call(draggableCount > 0);
  }

  void _calculateColumns() {
    int numColumns = 0;

    // First loop finds all startColumns
    loopChildren((child) {
      final childParentData = child.parentData!;

      if (childParentData.isNewItem) return;

      childParentData.pendingColChange = true;

      // Check if we already calculated this child
      if (childParentData.startCol == -1) {
        final parent = _overlapOnIndex(child);
        if (parent != null) {
          final parentData = parent.parentData!;
          childParentData.startCol = parentData.startCol + 1;
        } else {
          childParentData.startCol = 0;
        }
      }

      numColumns = max(numColumns, childParentData.startCol);
    });

    // numColumns is 0 indexed, so we need to add 1
    numColumns++;

    // Second pass will find all colSpans
    loopChildren((child) {
      final childParentData = child.parentData!;

      // Check if we already calculated this child
      if (childParentData.colSpan != -1) return;
      if (childParentData.isNewItem) return;

      final firstOverlapToTheRight = _findFirstToTheRight(
        child,
        startCol: childParentData.startCol,
        numColumns: numColumns,
      );

      final int newColSpan;
      if (firstOverlapToTheRight != null) {
        // Overlap, our colspan is the difference between the two startCols
        final firstOverlapToTheRightParentData = firstOverlapToTheRight.parentData!;
        newColSpan = firstOverlapToTheRightParentData.startCol - childParentData.startCol;
      } else {
        // No overlap, our colspan is the number of columns minus our startCol
        newColSpan = numColumns - childParentData.startCol;
      }

      childParentData.numColumns = numColumns;
      childParentData.colSpan = newColSpan;

      childParentData.checkNeedsLayout();
    });

    this.numColumns = numColumns;
  }

  RenderDayItemWidget? _overlapOnIndex(RenderDayItemWidget child, {int startCol = 0}) {
    return loopChildren((neighbor) {
      final neighborParentData = neighbor.parentData as DayViewWidgetParentData<T>;

      final overlaps = child.range.overlaps(neighbor.range);

      if (neighborParentData.startCol == startCol && overlaps) {
        // Nice we found a parent, but we need to check if it has a better parent
        // that we can use instead. This is to avoid overlapping items.
        RenderDayItemWidget bestParent = neighbor;

        // Save the best parent we found so far
        RenderDayItemWidget? betterParent = bestParent;
        int searchCol = startCol + 1;

        do {
          // Check if the better parent has a better parent
          betterParent = _overlapOnIndex(child, startCol: searchCol++);

          /// If we found overlap we assign that one as the better
          /// parent, and repeat to check the next index.
          if (betterParent != null) bestParent = betterParent;

          /// Until we find a index with no overlap
        } while (betterParent != null);

        return bestParent;
      }
      return null;
    });
  }

  RenderDayItemWidget? _findFirstToTheRight(
    RenderDayItemWidget child, {
    required int startCol,
    required int numColumns,
  }) {
    int lowestEndCol = numColumns;
    RenderDayItemWidget? bestResult;

    loopChildren((neighbor) {
      final neighborParentData = neighbor.parentData as DayViewWidgetParentData<T>;

      final overlaps = child.range.overlaps(neighbor.range);
      final betterStartCol = neighborParentData.startCol < lowestEndCol;

      if (betterStartCol && neighborParentData.startCol > startCol && overlaps) {
        lowestEndCol = neighborParentData.startCol;
        bestResult = neighbor;
      }
    });

    return bestResult;
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    return _performLayout(constraints);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final linePainter = Paint()
      ..strokeWidth = 1.0
      ..color = const Color(0xFFE3ECF8);

    final canvas = context.canvas;
    final hourHeight = _height / 24;

    double y = 0;
    for (int i = 0; i < 25; i++) {
      _drawText(canvas, offset + Offset(5, y), '${i.toString().padLeft(2, '0')}:00');
      canvas.drawLine(offset + Offset(_leftInset, y), offset + Offset(size.width, y), linePainter);
      y += hourHeight;
    }

    // Paint the children
    loopChildren((child) {
      final childParentData = child.parentData!;

      // If we are dragging a child, we don't want to paint it
      // if either drag start or end is null
      if (childParentData.isNewItem && dragRange == null) {
        return;
      }

      context.paintChild(child, child.parentData!.offset + offset);
    });
  }

  void _drawText(Canvas canvas, Offset offset, String s) {
    final span = TextSpan(text: s, style: _textStyle);
    final painter = TextPainter(text: span, textDirection: TextDirection.ltr);
    painter.layout(maxWidth: _leftInset);
    painter.paint(canvas, offset - Offset(0, painter.height / 2));
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final hit = loopChildren((child) {
      final childParentData = child.parentData!;

      if (childParentData.isNewItem) return null;

      final bool isHit = result.addWithPaintOffset(
        offset: childParentData.offset,
        position: position,
        hitTest: (BoxHitTestResult result, Offset transformed) {
          assert(transformed == position - childParentData.offset);
          return child.hitTest(result, position: transformed);
        },
      );

      return isHit == true ? true : null;
    });

    return hit ?? false;
  }

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    loopChildren((child) {
      final childParentData = child.parentData!;

      if (childParentData.isNewItem) return;

      visitor(child);
    });
  }
}

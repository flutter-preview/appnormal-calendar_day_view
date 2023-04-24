import 'dart:math';

import 'package:calendar_day_view/calendar_day_view.dart';
import 'package:calendar_day_view/src/extension.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class DayViewWidget<T> extends MultiChildRenderObjectWidget {
  DayViewWidget({
    super.key,
    super.children,
    required this.height,
    required this.date,
    this.leftInset = 55,
    this.onNewEvent,
    this.onDraggingStateChange,
    this.textStyle = const TextStyle(
      color: Colors.black,
      fontWeight: FontWeight.w600,
    ),
  });

  final double height;
  final double leftInset;
  final DateTime date;
  final TextStyle textStyle;
  final ValueSetter<DateTimeRange>? onNewEvent;
  final ValueSetter<bool>? onDraggingStateChange;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderDayViewWidget(
      height: height,
      date: date,
      onNewEvent: onNewEvent,
      onDraggingStateChange: onDraggingStateChange,
      leftInset: leftInset,
      textStyle: textStyle,
    );
  }

  @override
  void updateRenderObject(BuildContext context, covariant RenderDayViewWidget renderObject) {
    renderObject
      ..height = height
      ..date = date
      ..leftInset = leftInset
      ..onDraggingStateChange = onDraggingStateChange
      ..onNewEvent = onNewEvent
      ..textStyle = textStyle;
  }
}

class DayViewWidgetParentData extends ContainerBoxParentData<RenderDayItemWidget> {
  DayViewWidgetParentData({
    required this.hourHeight,
    required this.date,
    this.draggable = false,
    this.left = 0,
  });

  final double hourHeight;
  final DateTime date;
  bool draggable;
  double left;

  int numColumns = 1;
  int startCol = -1;
  int colSpan = -1;

  int get endCol => startCol + colSpan;

  void reset() {
    numColumns = 1;
    startCol = -1;
    colSpan = -1;
  }

  @override
  String toString() {
    return 'DayViewWidgetParentData{hourHeight: $hourHeight, numColumns: $numColumns, startCol: $startCol, colSpan: $colSpan, endCol: $endCol}';
  }
}

class RenderDayViewWidget extends RenderBox
    with
        ContainerRenderObjectMixin<RenderDayItemWidget, DayViewWidgetParentData>,
        RenderBoxContainerDefaultsMixin<RenderDayItemWidget, DayViewWidgetParentData> {
  RenderDayViewWidget({
    required double height,
    required DateTime date,
    required ValueSetter<DateTimeRange>? onNewEvent,
    required ValueSetter<bool>? onDraggingStateChange,
    required double leftInset,
    required TextStyle textStyle,
  })  : _height = height,
        _date = date,
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

  late final TapGestureRecognizer _tapGestureRecognizer;

  @override
  void attach(covariant PipelineOwner owner) {
    super.attach(owner);
    _tapGestureRecognizer = TapGestureRecognizer(debugOwner: this)
      ..onTapUp = (details) {
        _handleNewItemStart(details.localPosition);
      };
  }

  @override
  void handleEvent(PointerEvent event, covariant HitTestEntry<HitTestTarget> entry) {
    assert(debugHandleEvent(event, entry));

    if (event is PointerDownEvent) {
      _tapGestureRecognizer.addPointer(event);
    }
  }

  void _handleNewItemStart(Offset localPosition) {
    final hitChild = defaultHitTestChildren(BoxHitTestResult(), position: localPosition);
    if (!hitChild) {
      debugPrint('On start drag on view');
      _onNewEvent?.call(_selectedRange(localPosition));
    }
  }

  DateTimeRange _selectedRange(Offset localPosition) {
    final start = offsetToDateTime(localPosition);
    final end = start.add(const Duration(minutes: 30));

    return DateTimeRange(start: start, end: end);
  }

  DateTime offsetToDateTime(Offset offset) {
    final hourHeight = _height / 24;
    final hour = offset.dy ~/ hourHeight;
    final minute = ((offset.dy % hourHeight) / hourHeight * 60).round();

    return _date.midnight.add(Duration(hours: hour, minutes: minute));
  }

  @override
  void setupParentData(covariant RenderObject child) {
    bool resetColumns = false;

    if (child.parentData is! DayViewWidgetParentData) {
      // New child, we need to recalculate columns
      resetColumns = true;

      // Give the new child a fresh parent data
      child.parentData = DayViewWidgetParentData(
        hourHeight: _height / 24,
        date: _date.midnight,
        left: _leftInset,
      );
    }

    if (resetColumns) markNeedsRecalculate();
  }

  Size _performLayout(BoxConstraints constraints) {
    return Size(constraints.maxWidth, _height);
  }

  @override
  void performLayout() {
    size = _performLayout(constraints);

    final numColumns = _calculateColumns();

    loopChildren((child) {
      final childParentData = child.parentData!;

      childParentData.numColumns = numColumns;

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
    });
  }

  void markNeedsRecalculate() {
    debugPrint('Marking needs recalculate');
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

  int _calculateColumns() {
    int numColumns = 0;

    // First loop finds all startColumns
    loopChildren((child) {
      final childParentData = child.parentData!;

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
      if (childParentData.colSpan != -1) return null;

      final firstOverlapToTheRight = _findFirstToTheRight(
        child,
        startCol: childParentData.startCol,
        numColumns: numColumns,
      );
      if (firstOverlapToTheRight != null) {
        // Overlap, our colspan is the difference between the two startCols
        final firstOverlapToTheRightParentData = firstOverlapToTheRight.parentData!;
        childParentData.colSpan = firstOverlapToTheRightParentData.startCol - childParentData.startCol;
      } else {
        // No overlap, our colspan is the number of columns minus our startCol
        childParentData.colSpan = numColumns - childParentData.startCol;
      }

      debugPrint(childParentData.toString());
    });

    return numColumns;
  }

  RenderDayItemWidget? _overlapOnIndex(RenderDayItemWidget child, {int startCol = 0}) {
    return loopChildren((neighbor) {
      final neighborParentData = neighbor.parentData as DayViewWidgetParentData;

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
      final neighborParentData = neighbor.parentData as DayViewWidgetParentData;

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
    defaultPaint(context, offset);
  }

  void _drawText(Canvas canvas, Offset offset, String s) {
    final span = TextSpan(text: s, style: _textStyle);
    final painter = TextPainter(text: span, textDirection: TextDirection.ltr);
    painter.layout(maxWidth: _leftInset);
    painter.paint(canvas, offset - Offset(0, painter.height / 2));
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }

  @override
  bool hitTestSelf(Offset position) {
    return true;
  }
}

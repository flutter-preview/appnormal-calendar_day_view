import 'package:calendar_day_view/src/day_view_widget.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

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
    this.toggleDraggableAction,
  });

  final DateTime start;
  final DateTime end;
  final ToggleDraggableAction? toggleDraggableAction;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderDayItemWidget(
      start: start,
      end: end,
      toggleDraggableAction: toggleDraggableAction,
    );
  }

  @override
  void updateRenderObject(BuildContext context, covariant RenderDayItemWidget renderObject) {
    renderObject
      ..start = start
      ..end = end
      ..toggleDraggableAction = toggleDraggableAction;
  }
}

class RenderDayItemWidget extends RenderBox with RenderObjectWithChildMixin<RenderObject> {
  RenderDayItemWidget({
    required DateTime start,
    required DateTime end,
    ToggleDraggableAction? toggleDraggableAction,
  })  : _start = start,
        _end = end,
        _toggleDraggableAction = toggleDraggableAction;

  DateTime _start;
  DateTime _end;

  DateTime? _draggedStart;
  DateTime? _draggedEnd;

  ToggleDraggableAction? _toggleDraggableAction;
  _ActiveHandle? _activeHandle;

  late final TapGestureRecognizer _tapGestureRecognizer;
  late final LongPressGestureRecognizer _longPressGestureRecognizer;
  late final VerticalDragGestureRecognizer _dragGestureRecognizer;

  @override
  void setupParentData(covariant RenderObject child) {
    super.setupParentData(child);
    parentData?.draggable = false;
  }

  @override
  void attach(covariant PipelineOwner owner) {
    super.attach(owner);

    _tapGestureRecognizer = TapGestureRecognizer(debugOwner: this)
      ..onTapDown = (details) {
        if (toggleDraggableAction == ToggleDraggableAction.onTap) {
          parentData!.draggable = !parentData!.draggable;
          markNeedsPaint();
        }
      };

    _longPressGestureRecognizer = LongPressGestureRecognizer(debugOwner: this)
      ..onLongPressEnd = (details) {
        if (toggleDraggableAction == ToggleDraggableAction.onLongPress) {
          parentData!.draggable = !parentData!.draggable;
          markNeedsPaint();
        }
      };

    _dragGestureRecognizer = VerticalDragGestureRecognizer(debugOwner: this)
      ..onDown = (details) {
        if (!parentData!.draggable) {
          return;
        }

        final yOffset = details.localPosition.dy;
        final draggingStart = yOffset < dragHandleHeight;
        final draggingEnd = yOffset > size.height - dragHandleHeight;

        if (draggingStart) {
          debugPrint('Dragging start');
          _activeHandle = _ActiveHandle.start;
        } else if (draggingEnd) {
          debugPrint('Dragging end');
          _activeHandle = _ActiveHandle.end;
        } else {
          debugPrint('Dragging middle');
          _activeHandle = _ActiveHandle.middle;
        }
      }
      ..onUpdate = (details) {
        if (parentData!.draggable && _activeHandle != null) {
          final delta = details.primaryDelta ?? 0;
          final seconds = (delta / parentData!.hourHeight * 3600).round();
          debugPrint('Dragging delta: $delta == $seconds seconds');

          if (_activeHandle == _ActiveHandle.start) {
            _draggedStart = start.add(Duration(seconds: seconds));
            markParentNeedsRecalculate();
          } else if (_activeHandle == _ActiveHandle.end) {
            _draggedEnd = end.add(Duration(seconds: seconds));
            markParentNeedsRecalculate();
          } else if (_activeHandle == _ActiveHandle.middle) {
            _draggedStart = start.add(Duration(seconds: seconds));
            _draggedEnd = end.add(Duration(seconds: seconds));
            markParentNeedsRecalculate();
          }
        }
      };
  }

  @override
  void handleEvent(PointerEvent event, covariant HitTestEntry<HitTestTarget> entry) {
    assert(debugHandleEvent(event, entry));

    if (event is PointerDownEvent) {
      _tapGestureRecognizer.addPointer(event);
      _longPressGestureRecognizer.addPointer(event);
      _dragGestureRecognizer.addPointer(event);
    }
  }

  @override
  DayViewWidgetParentData? get parentData => super.parentData as DayViewWidgetParentData?;

  DateTimeRange get range => DateTimeRange(start: start, end: end);

  DateTime get start =>
      (_draggedStart ?? _start).isBefore(parentData!.date) ? parentData!.date : (_draggedStart ?? _start);
  set start(DateTime value) {
    if (_start == value) return;
    _start = value;
    markParentNeedsRecalculate();
  }

  DateTime get end => (_draggedEnd ?? _end).isAfter(parentData!.date.add(const Duration(days: 1)))
      ? parentData!.date.add(const Duration(days: 1))
      : (_draggedEnd ?? _end);
  set end(DateTime value) {
    if (_end == value) return;
    _end = value;
    markParentNeedsRecalculate();
  }

  ToggleDraggableAction? get toggleDraggableAction => _toggleDraggableAction;
  set toggleDraggableAction(ToggleDraggableAction? value) {
    if (_toggleDraggableAction == value) return;
    _toggleDraggableAction = value;
  }

  Size _performLayout(BoxConstraints constraints, {required bool dry}) {
    final hourHeight = parentData!.hourHeight;

    final start = this.start;
    final end = this.end;

    final startOffset = (start.hour + (start.minute / 60)) * hourHeight;
    final endOffset = (end.hour + (end.minute / 60)) * hourHeight;

    final height = endOffset - startOffset;
    final columnWidth = (constraints.maxWidth - parentData!.left) / parentData!.numColumns;
    final width = columnWidth * parentData!.colSpan;

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

  @override
  void performLayout() {
    size = _performLayout(constraints, dry: false);
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    return _performLayout(constraints, dry: true);
  }

  double get dragHandleHeight => 20;

  @override
  void paint(PaintingContext context, Offset offset) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(.3)
      ..style = PaintingStyle.fill;

    final childParentData = child?.parentData as BoxParentData;
    final topLeft = childParentData.offset + offset;

    if (child != null) {
      context.paintChild(child!, topLeft);
    }
    if (parentData?.draggable == true) {
      context.canvas.save();
      context.canvas.translate(topLeft.dx, topLeft.dy);

      final topRect = Rect.fromLTRB(0, 0, size.width, dragHandleHeight);
      final bottomRect = Rect.fromLTRB(0, size.height - dragHandleHeight, size.width, size.height);

      context.canvas.drawRect(topRect, paint);
      context.canvas.drawRect(bottomRect, paint);

      context.canvas.restore();
    }
  }

  void markParentNeedsRecalculate() {
    assert(this.parent != null);
    final RenderObject parent = this.parent! as RenderObject;
    if (parent is RenderDayViewWidget) {
      parent.markNeedsRecalculate();
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

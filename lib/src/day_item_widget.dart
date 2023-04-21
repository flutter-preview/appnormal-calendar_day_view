import 'package:calendar_day_view/src/day_view_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class DayItemWidget extends SingleChildRenderObjectWidget {
  const DayItemWidget({
    super.key,
    super.child,
    required this.start,
    required this.end,
  });

  final DateTime start;
  final DateTime end;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderDayItemWidget(
      start: start,
      end: end,
    );
  }

  @override
  void updateRenderObject(BuildContext context, covariant RenderDayItemWidget renderObject) {
    renderObject
      ..start = start
      ..end = end;
  }
}

class RenderDayItemWidget extends RenderBox with RenderObjectWithChildMixin<RenderObject> {
  RenderDayItemWidget({
    required DateTime start,
    required DateTime end,
  })  : _start = start,
        _end = end;

  late DateTime _start;
  late DateTime _end;

  @override
  DayViewWidgetParentData? get parentData => super.parentData as DayViewWidgetParentData?;

  DateTimeRange get range => DateTimeRange(start: start, end: end);

  DateTime get start => _start.isBefore(parentData!.date) ? parentData!.date : _start;
  set start(DateTime value) {
    if (_start == value) return;
    _start = value;
    markParentNeedsRecalculate();
  }

  DateTime get end => _end.isAfter(parentData!.date.add(const Duration(days: 1)))
      ? parentData!.date.add(const Duration(days: 1))
      : _end;
  set end(DateTime value) {
    if (_end == value) return;
    _end = value;
    markParentNeedsRecalculate();
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

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child != null) {
      final childParentData = child!.parentData as BoxParentData;
      context.paintChild(child!, childParentData.offset + offset);
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

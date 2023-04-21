import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

extension DateTimeRangeEx on DateTimeRange {
  /// Logic according to: https://stackoverflow.com/a/325964/680093
  bool overlaps(DateTimeRange other) {
    final startA = start.microsecondsSinceEpoch;
    final endA = end.microsecondsSinceEpoch;
    final startB = other.start.microsecondsSinceEpoch;
    final endB = other.end.microsecondsSinceEpoch;

    return (startA < endB) && (endA > startB);
  }
}

extension DateTimeEx on DateTime {
  DateTime get midnight => subtract(Duration(
        hours: hour,
        minutes: minute,
        seconds: second,
        milliseconds: millisecond,
        microseconds: microsecond,
      ));
}

extension ContainerParentDataMixinEx<ChildType extends RenderObject,
        ParentDataType extends ContainerParentDataMixin<ChildType>>
    on ContainerRenderObjectMixin<ChildType, ParentDataType> {
  T? loopChildren<T>(T? Function(ChildType child) callback) {
    var child = firstChild;
    while (child != null) {
      final result = callback(child);
      if (result != null) return result;
      child = childAfter(child);
    }

    return null;
  }
}

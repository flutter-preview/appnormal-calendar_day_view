import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class CalendarGestureDetector {
  late final TapGestureRecognizer _tapGestureRecognizer;
  late final LongPressGestureRecognizer _longPressGestureRecognizer;
  late final VerticalDragGestureRecognizer _dragGestureRecognizer;

  Offset? lastPointer;

  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final ValueChanged<double>? onVerticalDragStart;
  final ValueChanged<double>? onVerticalDragUpdate;
  final ValueChanged<double>? onVerticalDragEnd;
  final bool Function(Offset position)? onChildHit;

  bool _dragging = false;

  CalendarGestureDetector({
    this.onTap,
    this.onLongPress,
    this.onVerticalDragStart,
    this.onVerticalDragUpdate,
    this.onVerticalDragEnd,
    this.onChildHit,
    bool longPressDragEnabled = false,
  }) {
    _tapGestureRecognizer = TapGestureRecognizer(debugOwner: this)
      ..onTapUp = (details) {
        if (onChildHit?.call(details.localPosition) ?? false) {
          return;
        }

        lastPointer = details.localPosition;
        onTap?.call();
      };

    _longPressGestureRecognizer = LongPressGestureRecognizer(debugOwner: this)
      ..onLongPressMoveUpdate = (details) {
        if (!longPressDragEnabled) {
          return;
        }

        final delta = details.localPosition - lastPointer!;
        lastPointer = details.localPosition;
        onVerticalDragUpdate?.call(delta.dy);
      }
      ..onLongPressEnd = (details) {
        if (!longPressDragEnabled) {
          return;
        }

        onVerticalDragEnd?.call(lastPointer!.dy);
      }
      ..onLongPressStart = (details) {
        if (onChildHit?.call(details.localPosition) ?? false) {
          return;
        }

        lastPointer = details.localPosition;
        onLongPress?.call();
      };

    _dragGestureRecognizer = VerticalDragGestureRecognizer(debugOwner: this)
      ..onDown = (details) {
        if (onChildHit?.call(details.localPosition) != true) {
          return;
        }

        lastPointer = details.localPosition;
        onVerticalDragStart?.call(details.localPosition.dy);
      }
      ..onEnd = (details) {
        if (lastPointer == null) {
          return;
        }

        onVerticalDragEnd?.call(lastPointer!.dy);
      }
      ..onUpdate = (details) {
        if (onChildHit?.call(details.localPosition) != true) {
          return;
        }

        lastPointer = details.localPosition;
        onVerticalDragUpdate?.call(details.delta.dy);
      };
  }

  void handleEvent(PointerEvent event) {
    if (event is PointerDownEvent) {
      _tapGestureRecognizer.addPointer(event);
      _longPressGestureRecognizer.addPointer(event);

      if (_dragging) {
        _dragGestureRecognizer.addPointer(event);
      }
    }
  }

  void startDragging() {
    _dragging = true;
  }

  void stopDragging() {
    _dragging = false;
  }
}

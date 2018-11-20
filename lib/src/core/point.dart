import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'dart:math' as math;

import 'package:flutter_map/src/map/map.dart';
import 'package:latlong/latlong.dart';

class Point<T extends num> extends math.Point<T> {
  const Point(num x, num y) : super(x, y);

  Point<T> operator /(num /*T|int*/ factor) {
    return new Point<T>(x / factor, y / factor);
  }

  Point<T> ceil() {
    return new Point(x.ceil(), y.ceil());
  }

  Point<T> floor() {
    return new Point<T>(x.floor(), y.floor());
  }

  Point<T> unscaleBy(Point<T> point) {
    return new Point<T>(x / point.x, y / point.y);
  }

  Point<T> operator +(math.Point<T> other) {
    return new Point<T>(x + other.x, y + other.y);
  }

  Point<T> operator -(math.Point<T> other) {
    return new Point<T>(x - other.x, y - other.y);
  }

  Point<T> operator *(num /*T|int*/ factor) {
    return new Point<T>((x * factor), (y * factor));
  }

  Point scaleBy(Point point) {
    return new Point(this.x * point.x, this.y * point.y);
  }

  Point round() {
    var x = this.x is double ? this.x.round() : this.x;
    var y = this.y is double ? this.y.round() : this.y;
    return new Point(x, y);
  }

  Point multiplyBy(num n) {
      return new Point(this.x * n, this.y * n);
  }

  String toString() => "Point ($x, $y)";
}

typedef void PointTapCallback(int index, LatLng point);
typedef void PointLongPressCallback(int index, LatLng point);
typedef void PointDragStartCallback(int index, LatLng point);
typedef void PointDragUpdateCallback(int index, LatLng point);
typedef void PointDragCancelCallback(int index, LatLng point);
typedef void PointDragEndCallback(int index, LatLng point);
typedef Offset TranslateFunction(Offset offset, bool toLocal);

class EditablePointWidget extends StatefulWidget {

  final Size size;
  final MapState map;
  final WidgetBuilder builder;
  final int index;
  final List<LatLng> points;
  final TranslateFunction translate;
  final Stream<int> onChanged;
  final PointDragUpdateCallback onDragStart;
  final PointDragUpdateCallback onDragUpdate;
  final PointDragUpdateCallback onDragCancel;
  final PointDragUpdateCallback onDragEnd;
  final PointTapCallback onTap;
  final PointLongPressCallback onLongPress;

  EditablePointWidget({
    @required this.map,
    @required this.size,
    @required this.builder,
    @required this.index,
    @required this.points,
    this.translate,
    this.onChanged,
    this.onDragStart,
    this.onDragUpdate,
    this.onDragCancel,
    this.onDragEnd,
    this.onTap,
    this.onLongPress,
  });

  @override
  EditablePointWidgetState createState() => EditablePointWidgetState();

}

class EditablePointWidgetState extends State<EditablePointWidget> {

  LatLng _point;
  Offset _offset;
  StreamSubscription<int> subscription;

  // Borrowed gesture recognized lifetime
  // management from [Draggable] source code, see
  // https://github.com/flutter/flutter/.../widgets/drag_target.dart#L316
  int _activeCount = 0;
  PanGestureRecognizer _immediateRecognizer;

  @override
  void initState() {
    super.initState();

    _initSubscription();

    _immediateRecognizer = PanGestureRecognizer()
      ..onStart = (DragStartDetails details) {
        HapticFeedback.selectionClick();
        setState(() {
          _activeCount++;
          _point = widget.points[widget.index];
          _offset = _translate(widget.map.latlngToOffset(_point), true);
          if(widget.onDragStart != null) {
            widget.onDragStart(widget.index, _point);
          }
        });
      }
      ..onUpdate = (DragUpdateDetails details) {
        setState(() {
          _offset = _offset + details.delta;
          _point = widget.map.offsetToLatLng(_translate(_offset, false));
          widget.points[widget.index] = _point;
          if(widget.onDragUpdate != null) {
            widget.onDragUpdate(widget.index, _point);
          }
        });
      }
      ..onCancel = () {
        setState(() {
          _activeCount--;
          _point = widget.points[widget.index];
          _offset = _translate(widget.map.latlngToOffset(_point), true);
          if(widget.onDragCancel != null) {
            widget.onDragCancel(widget.index, _point);
          }
        });
      }
      ..onEnd = (DragEndDetails details) {
        setState(() {
          _activeCount--;
          widget.points[widget.index] = _point;
          if(widget.onDragEnd != null) {
            widget.onDragEnd(widget.index, _point);
          }
        });
      };

  }


  Offset _translate(Offset offset, bool toLocal) {
    return widget.translate == null ? offset : widget.translate(offset, toLocal);
  }

  void _initSubscription() {
    _point = widget.points[widget.index];
    if(widget.onChanged != null) {
      subscription = widget.onChanged.listen((index) =>
        setState((){
          if(widget.index == index) {
            _point = widget.points[index];
          }
      }));
    }
  }


  @override
  void didUpdateWidget(EditablePointWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _disposeSubscription();
    _initSubscription();
  }

  @override
  void dispose() {
    _disposeSubscription();
    _disposeRecognizerIfInactive();
    super.dispose();
  }

  void _disposeSubscription() {
    if(subscription != null) {
      subscription.cancel();
      subscription = null;
    }
  }

  void _disposeRecognizerIfInactive() {
    if (_activeCount > 0)
      return;
    _immediateRecognizer.dispose();
    _immediateRecognizer = null;
  }

  @override
  Widget build(BuildContext context) {

    final bool canDrag = _activeCount < 1;

    Offset offset = widget.translate(
        widget.map.latlngToOffset(_point), true
    );

    return Positioned(
        width: widget.size.width,
        height: widget.size.height,
        left: offset.dx,
        top: offset.dy,
        child: Listener(
          onPointerDown: (PointerDownEvent event) {
            if(canDrag) {
              _immediateRecognizer.addPointer(event);
            }
          },
          child: GestureDetector(
            child: widget.builder(context),
            onTap: widget.onTap != null
                ? () => widget.onTap(widget.index, widget.points[widget.index])
                : null,
            onLongPress: widget.onLongPress != null
                ? () => widget.onLongPress(widget.index, widget.points[widget.index])
                : null,
          ),
        ),
      );
  }

}

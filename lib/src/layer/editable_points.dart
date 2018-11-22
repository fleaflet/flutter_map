import 'dart:async';
import 'dart:collection';
import 'dart:ui';
import 'dart:core';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/map/map.dart';
import 'package:latlong/latlong.dart' show LatLng;

class EditablePointsWidget extends StatefulWidget {
  final WidgetBuilder builder;
  final List<LatLng> points;
  final MapState map;
  final double radius = 15.0;
  final double strokeWidth = 1.0;

  const EditablePointsWidget(
      {Key key, this.builder, this.points, this.map})
      : super(key: key);

  @override
  _EditablePointsWidgetState createState() => _EditablePointsWidgetState();
}

class _EditablePointsWidgetState extends State<EditablePointsWidget> {
  final List<LatLng> _midPoints = [];
  final StreamController<int> onPointChanged;
  final StreamController<int> onMidPointChanged;

  final Map<int,LatLng> _dragging = HashMap();

  _EditablePointsWidgetState()
      : onPointChanged = StreamController.broadcast(),
        onMidPointChanged = StreamController.broadcast();

  @override
  void dispose() {
    onPointChanged.close();
    onMidPointChanged.close();
    super.dispose();
  }

  void _onPointUpdate(int index, LatLng point) {
//    print("_onPointUpdate($index, $point)");
    int length = _setMidPoints().length;
    for (int i = 0; i < length; i++) {
      onMidPointChanged.add(i);
    }
  }

  void _onPointTap(int index, LatLng point) {
//    print("_onPointTap($index, $point)");
    if(widget.points.length>2) {
      setState(() {
        widget.points.removeAt(index);
        for (int i = 0; i < widget.points.length; i++) {
          onPointChanged.add(i);
        }
        int length = _setMidPoints().length;
        for (int i = 0; i < length; i++) {
          onMidPointChanged.add(i);
        }
      });
    }
  }

  void _onMidPointStart(int index, LatLng point) {
    _dragging[index] = point;
    widget.points.insert(index + 1, point);
  }

  void _onMidPointCancel(int index, LatLng point) {
    if(_dragging.containsKey(index)) {
      setState(() {
        _dragging.remove(index);
      });
    }
  }

  void _onMidPointUpdate(int index, LatLng point) {
    for (int i = 0; i < _midPoints.length; i++) {
      onMidPointChanged.add(i);
    }
    for (int i = 0; i < widget.points.length; i++) {
      onPointChanged.add(i);
    }
    setState(() {
      _dragging[index] = point;
      widget.points[index + 1] = point;
    });
  }

  void _onMidPointEnd(int index, LatLng point) {
    for (int i = 0; i < widget.points.length; i++) {
      onPointChanged.add(i);
    }
    for (int i = 0; i < _midPoints.length; i++) {
      onMidPointChanged.add(i);
    }
    _onMidPointCancel(index, point);
  }

  List<LatLng> _setMidPoints() {
    Offset previous;

    _midPoints.clear();

    widget.points.forEach((next) {
      Offset offset = widget.map.latlngToOffset(next);
      if (previous != null) {
        _midPoints.add(
            widget.map.offsetToLatLng(_calcMidPoint(previous, offset))
        );
      }
      previous = offset;
    });

    return _midPoints;
  }

  Offset _calcMidPoint(Offset p1, Offset p2) {
    return Offset((p1.dx + p2.dx) / 2.0, (p1.dy + p2.dy) / 2.0);
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> widgets = [widget.builder(context)];

    widgets.addAll(_buildMidPointHandles());
    widgets.addAll(_buildPointHandles());

    return Stack(
      children: widgets,
    );
  }

  List<Widget> _buildPointHandles() {
    int i = 0;
    return widget.points
        .map((_) => EditableHandleWidget(
      map: widget.map,
      radius: widget.radius,
      strokeWidth: widget.strokeWidth,
      isMidPoint: false,
      index: i++,
      points: widget.points,
      onChanged: onPointChanged.stream,
      onTap: _onPointTap,
      onDragUpdate: _onPointUpdate,
    ))
        .toList();
  }

  List<Widget> _buildMidPointHandles() {
    int i = 0;
    return _setMidPoints()
        .map((_) => EditableHandleWidget(
        map: widget.map,
        radius: widget.radius,
        strokeWidth: widget.strokeWidth,
        isMidPoint: true,
        index: i++,
        points: _midPoints,
        onChanged: onMidPointChanged.stream,
        onDragStart: _onMidPointStart,
        onDragUpdate: _onMidPointUpdate,
        onDragEnd: _onMidPointEnd,
        onTap: _onMidPointEnd))
        .toList();
  }
}

class EditableHandleWidget extends EditablePointWidget {
  final MapState map;
  final double radius;
  final bool isMidPoint;
  final double strokeWidth;
  final int index;
  final List<LatLng> points;
  final Stream<int> onChanged;
  final PointTapCallback onDragStart;
  final PointDragUpdateCallback onDragUpdate;
  final PointDragEndCallback onDragEnd;
  final PointTapCallback onTap;
  final PointLongPressCallback onLongPress;

  EditableHandleWidget({
    this.map,
    this.radius,
    this.isMidPoint,
    this.strokeWidth,
    this.index,
    this.points,
    this.onChanged,
    this.onDragStart,
    this.onDragUpdate,
    this.onDragEnd,
    this.onTap,
    this.onLongPress,
  }) : super(
    map: map,
    size: Size.fromRadius(radius),
    builder: (BuildContext context) {
      return Stack(
        children: [
          CustomPaint(
            painter: HandlePainter(
                offset: Offset(radius, radius),
                radius: radius,
                isMidPoint: isMidPoint,
                strokeWidth: strokeWidth),
            size: Size.fromRadius(radius),
          ),
//                  Center(child: Text("$index")),
        ],
      );
    },
    translate: (Offset position, bool toLocal) {
      return position.translate(
        toLocal ? -radius : radius * 2,
        toLocal ? -radius : radius * 2,
      );
    },
    index: index,
    points: points,
    onChanged: onChanged,
    onDragStart: onDragStart,
    onDragUpdate: onDragUpdate,
    onDragEnd: onDragEnd,
    onTap: onTap,
    onLongPress: onLongPress,
  );
}

class HandlePainter extends CustomPainter {
  final Offset offset;
  final double radius;
  final double strokeWidth;
  final bool isMidPoint;

  HandlePainter({this.offset, this.radius, this.strokeWidth, this.isMidPoint});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final double opacity = isMidPoint ? 0.4 : 0.8;
    canvas.clipRect(rect);
    final fill = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white.withOpacity(opacity);

    final line = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.blue.withOpacity(opacity)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    (isMidPoint ? _paintRect : _paintCircle)(canvas, radius, fill);
    (isMidPoint ? _paintRect : _paintCircle)(
        canvas, radius - strokeWidth / 2.0, line);

    line.strokeWidth = strokeWidth / 2.0;

    _paintCross(canvas, line);
  }

  void _paintCross(Canvas canvas, Paint paint) {
    final Path path = Path();
    Offset center = offset;
    path.moveTo(center.dx, center.dy - 3.0);
    path.lineTo(center.dx, center.dy + 3.0);
    path.moveTo(center.dx - 3.0, center.dy);
    path.lineTo(center.dx + 3.0, center.dy);
    path.close();
    canvas.drawPath(path, paint);
  }

  void _paintRect(Canvas canvas, double radius, Paint paint) {
    canvas.drawRect(Rect.fromCircle(center: offset, radius: radius), paint);
  }

  void _paintCircle(Canvas canvas, double radius, Paint paint) {
    canvas.drawCircle(offset, radius, paint);
  }

  @override
  bool shouldRepaint(HandlePainter other) => true;
}
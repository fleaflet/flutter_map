import 'dart:async';
import 'dart:collection';
import 'dart:math';
import 'dart:ui';
import 'dart:core';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/map/map.dart';
import 'package:latlong/latlong.dart' show LatLng;

typedef PolylineCallback(Polyline polyline, LatLng point);
typedef PolylineMovedCallback(Polyline polyline, LatLng point);
typedef PolylineChangedCallback(Polyline polyline, LatLng point);

class PolylineLayerOptions extends LayerOptions {
  final List<Polyline> polylines;
  final PolylineCallback onTap;
  final PolylineCallback onLongPress;
  final bool editable;
  final PolylineMovedCallback onMoved;
  final PolylineChangedCallback onChanged;
  PolylineLayerOptions(
      {this.polylines = const [],
      this.onTap,
      this.onLongPress,
      this.editable = false,
      this.onMoved,
      this.onChanged,
      rebuild})
      : super(rebuild: rebuild);
}

class Polyline {
  final List<LatLng> points;
  final List<Offset> offsets = [];
  final double strokeWidth;
  final Color color;
  final double borderStrokeWidth;
  final Color borderColor;
  final bool isDotted;

  Rect _bounds = Rect.zero;

  bool get isEmpty => this.points == null || this.points.isEmpty;
  bool get isNotEmpty => this.points != null && this.points.isNotEmpty;
  Rect get bounds => this._bounds;

  Polyline({
    this.points,
    this.strokeWidth = 1.0,
    this.color = const Color(0xFF00FF00),
    this.borderStrokeWidth = 0.0,
    this.borderColor = const Color(0xFFFFFF00),
    this.isDotted = false,
  });
}

class PolylineLayer extends StatelessWidget {
  final PolylineLayerOptions polylineOpts;
  final MapState map;
  final Stream<Null> stream;

  PolylineLayer(this.polylineOpts, this.map, this.stream);

  Widget build(BuildContext context) {
    return new LayoutBuilder(
      builder: (BuildContext context, BoxConstraints bc) {
        final size = new Size(bc.maxWidth, bc.maxHeight);
        return _build(context, size);
      },
    );
  }

  Widget _build(BuildContext context, Size size) {
    return new StreamBuilder<int>(
      stream: stream, // a Stream<int> or null
      builder: (BuildContext context, _) {
        return Container(
          child: Stack(
            children: _buildPolylines(size),
          ),
        );
      },
    );
  }

  List<Widget> _buildPolylines(Size size) {
    var list = polylineOpts.polylines
        .where((polyline) => polyline.isNotEmpty)
        .map(
          (polyline) => polylineOpts.editable
              ? EditablePolylineWidget(
                  builder: (BuildContext context) =>
                      _buildPolylineWidget(polyline, size),
                  points: polyline.points,
                  map: map,
                  options: polylineOpts,
                )
              : _buildPolylineWidget(polyline, size),
        )
        .toList();
    return list;
  }

  Widget _buildPolylineWidget(Polyline polyline, Size size) {
    polyline.offsets.clear();
    polyline._bounds = Rect.zero;
    var i = 0;
    for (var point in polyline.points) {
      var offset = map.latlngToOffset(point);
      polyline.offsets.add(offset);
      if (i > 0 && i < polyline.points.length) {
        polyline.offsets.add(offset);
        polyline._bounds = polyline._bounds
            .expandToInclude(Rect.fromPoints(polyline.offsets[i - 1], offset));
      }
      i++;
    }
    return CustomPaint(
      painter: PolylinePainter(polyline),
      size: size,
    );
  }
}

class EditablePolylineWidget extends StatefulWidget {
  final WidgetBuilder builder;
  final List<LatLng> points;
  final MapState map;
  final PolylineLayerOptions options;
  final double radius = 15.0;
  final double strokeWidth = 1.0;

  const EditablePolylineWidget(
      {Key key, this.builder, this.points, this.map, this.options})
      : super(key: key);

  @override
  _EditablePolylineWidgetState createState() => _EditablePolylineWidgetState();
}

class _EditablePolylineWidgetState extends State<EditablePolylineWidget> {
  final List<LatLng> _midPoints = [];
  final StreamController<int> onPointChanged;
  final StreamController<int> onMidPointChanged;

  final Map<int,LatLng> _dragging = HashMap();

  _EditablePolylineWidgetState()
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

class PolylinePainter extends CustomPainter {
  final Polyline polylineOpt;
  PolylinePainter(this.polylineOpt);

  @override
  void paint(Canvas canvas, Size size) {
    if (polylineOpt.offsets.isEmpty) {
      return;
    }
    final rect = Offset.zero & size;
    canvas.clipRect(rect);
    final paint = new Paint()
      ..color = polylineOpt.color
      ..strokeWidth = polylineOpt.strokeWidth;
    final borderPaint = polylineOpt.borderStrokeWidth > 0.0
        ? (new Paint()
          ..color = polylineOpt.borderColor
          ..strokeWidth =
              polylineOpt.strokeWidth + polylineOpt.borderStrokeWidth)
        : null;
    double radius = polylineOpt.strokeWidth / 2;
    double borderRadius = radius + (polylineOpt.borderStrokeWidth / 2);
    if (polylineOpt.isDotted) {
      double spacing = polylineOpt.strokeWidth * 1.5;
      if (borderPaint != null) {
        _paintDottedLine(
            canvas, polylineOpt.offsets, borderRadius, spacing, borderPaint);
      }
      _paintDottedLine(canvas, polylineOpt.offsets, radius, spacing, paint);
    } else {
      if (borderPaint != null) {
        _paintLine(canvas, polylineOpt.offsets, borderRadius, borderPaint);
      }
      _paintLine(canvas, polylineOpt.offsets, radius, paint);
    }
  }

  void _paintDottedLine(Canvas canvas, List<Offset> offsets, double radius,
      double stepLength, Paint paint) {
    double startDistance = 0.0;
    for (int i = 0; i < offsets.length - 1; i++) {
      Offset o0 = offsets[i];
      Offset o1 = offsets[i + 1];
      double totalDistance = _dist(o0, o1);
      double distance = startDistance;
      while (distance < totalDistance) {
        double f1 = distance / totalDistance;
        double f0 = 1.0 - f1;
        var offset = Offset(o0.dx * f0 + o1.dx * f1, o0.dy * f0 + o1.dy * f1);
        canvas.drawCircle(offset, radius, paint);
        distance += stepLength;
      }
      startDistance = distance < totalDistance
          ? stepLength - (totalDistance - distance)
          : distance - totalDistance;
    }
    canvas.drawCircle(polylineOpt.offsets.last, radius, paint);
  }

  void _paintLine(
      Canvas canvas, List<Offset> offsets, double radius, Paint paint) {
    canvas.drawPoints(PointMode.lines, offsets, paint);
    for (var offset in offsets) {
      canvas.drawCircle(offset, radius, paint);
    }
  }

  @override
  bool shouldRepaint(PolylinePainter other) => false;
}

double _dist(Offset v, Offset w) {
  return sqrt(_dist2(v, w));
}

double _dist2(Offset v, Offset w) {
  return _sqr(v.dx - w.dx) + _sqr(v.dy - w.dy);
}

double _sqr(double x) {
  return x * x;
}

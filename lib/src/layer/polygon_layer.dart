import 'dart:math';
import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/map/map.dart';
import 'package:latlong/latlong.dart' hide Path;  // conflict with Path from UI

class PolygonLayerOptions extends LayerOptions {
  final List<Polygon> polygons;

  PolygonLayerOptions({this.polygons = const [], rebuild})
      : super(rebuild: rebuild);
}

class Polygon {
  final List<LatLng> points;
  final List<Offset> offsets = [];
  final Color color;
  final double borderStrokeWidth;
  final Color borderColor;
  final bool isDotted;

  Polygon({
    this.points,
    this.color = const Color(0xFF00FF00),
    this.borderStrokeWidth = 0.0,
    this.borderColor = const Color(0xFFFFFF00),
    this.isDotted = false,
  });
}

class PolygonLayer extends StatelessWidget {
  final PolygonLayerOptions polygonOpts;
  final MapState map;
  final Stream<Null> stream;

  PolygonLayer(this.polygonOpts, this.map, this.stream);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints bc) {
        final size = Size(bc.maxWidth, bc.maxHeight);
        return _build(context, size);
      },
    );
  }

  Widget _build(BuildContext context, Size size) {
    return StreamBuilder<int>(
      stream: stream, // a Stream<int> or null
      builder: (BuildContext context, _) {
        for (var polygonOpt in polygonOpts.polygons) {
          polygonOpt.offsets.clear();
          var i = 0;
          for (var point in polygonOpt.points) {
            var pos = map.project(point);
            pos = pos.multiplyBy(map.getZoomScale(map.zoom, map.zoom)) - map.getPixelOrigin();
            polygonOpt.offsets.add(Offset(pos.x.toDouble(), pos.y.toDouble()));
            if (i > 0 && i < polygonOpt.points.length) {
              polygonOpt.offsets.add(Offset(pos.x.toDouble(), pos.y.toDouble()));
            }
            i++;
          }
        }

        var polygons = <Widget>[];
        for (var polygonOpt in polygonOpts.polygons) {
          polygons.add(
            CustomPaint(
              painter: PolygonPainter(polygonOpt),
              size: size,
            ),
          );
        }

        return Container(
          child: Stack(
            children: polygons,
          ),
        );
      },
    );
  }
}

class PolygonPainter extends CustomPainter {
  final Polygon polygonOpt;

  PolygonPainter(this.polygonOpt);

  @override
  void paint(Canvas canvas, Size size) {
    if (polygonOpt.offsets.isEmpty) {
      return;
    }
    final rect = Offset.zero & size;
    canvas.clipRect(rect);
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = polygonOpt.color;
    final borderPaint = polygonOpt.borderStrokeWidth > 0.0
        ? (Paint()
      ..color = polygonOpt.borderColor
      ..strokeWidth = polygonOpt.borderStrokeWidth)
        : null;

    _paintPolygon(canvas, polygonOpt.offsets, paint);

    var borderRadius = (polygonOpt.borderStrokeWidth / 2);
    if (polygonOpt.borderStrokeWidth > 0.0) {
      if (polygonOpt.isDotted) {
        var spacing = polygonOpt.borderStrokeWidth * 1.5;
        _paintDottedLine(canvas, polygonOpt.offsets, borderRadius, spacing, borderPaint);
      } else {
        _paintLine(canvas, polygonOpt.offsets, borderRadius, borderPaint);
      }
    }
  }

  void _paintDottedLine(Canvas canvas, List<Offset> offsets, double radius,
      double stepLength, Paint paint) {
    var startDistance = 0.0;
    for (var i = 0; i < offsets.length - 1; i++) {
      var o0 = offsets[i];
      var o1 = offsets[i + 1];
      var totalDistance = _dist(o0, o1);
      var distance = startDistance;
      while (distance < totalDistance) {
        var f1 = distance / totalDistance;
        var f0 = 1.0 - f1;
        var offset = Offset(o0.dx * f0 + o1.dx * f1, o0.dy * f0 + o1.dy * f1);
        canvas.drawCircle(offset, radius, paint);
        distance += stepLength;
      }
      startDistance = distance < totalDistance
          ? stepLength - (totalDistance - distance)
          : distance - totalDistance;
    }
    canvas.drawCircle(polygonOpt.offsets.last, radius, paint);
  }

  void _paintLine(Canvas canvas, List<Offset> offsets, double radius, Paint paint) {
    canvas.drawPoints(PointMode.lines, [...offsets, offsets[0]], paint);
    for (var offset in offsets) {
      canvas.drawCircle(offset, radius, paint);
    }
  }

  void _paintPolygon(Canvas canvas, List<Offset> offsets, Paint paint) {
    var path = Path();
    path.addPolygon(offsets, true);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(PolygonPainter other) => false;

  double _dist(Offset v, Offset w) {
    return sqrt(_dist2(v, w));
  }

  double _dist2(Offset v, Offset w) {
    return _sqr(v.dx - w.dx) + _sqr(v.dy - w.dy);
  }

  double _sqr(double x) {
    return x * x;
  }
}

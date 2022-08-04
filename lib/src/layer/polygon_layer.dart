import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/layer/label.dart';
import 'package:flutter_map/src/map/flutter_map_state.dart';
import 'package:latlong2/latlong.dart' hide Path; // conflict with Path from UI

enum PolygonLabelPlacement {
  centroid,
  polylabel,
}

class Polygon {
  final List<LatLng> points;
  final List<Offset> offsets = [];
  final List<List<LatLng>>? holePointsList;
  final List<List<Offset>>? holeOffsetsList;
  final Color color;
  final double borderStrokeWidth;
  final Color borderColor;
  final bool disableHolesBorder;
  final bool isDotted;
  final bool isFilled;
  final StrokeCap strokeCap;
  final StrokeJoin strokeJoin;
  late final LatLngBounds boundingBox;
  final String? label;
  final TextStyle labelStyle;
  final PolygonLabelPlacement labelPlacement;

  Polygon({
    required this.points,
    this.holePointsList,
    this.color = const Color(0xFF00FF00),
    this.borderStrokeWidth = 0.0,
    this.borderColor = const Color(0xFFFFFF00),
    this.disableHolesBorder = false,
    this.isDotted = false,
    this.isFilled = false,
    this.strokeCap = StrokeCap.round,
    this.strokeJoin = StrokeJoin.round,
    this.label,
    this.labelStyle = const TextStyle(),
    this.labelPlacement = PolygonLabelPlacement.centroid,
  }) : holeOffsetsList = null == holePointsList || holePointsList.isEmpty
            ? null
            : List.generate(holePointsList.length, (_) => []);
}

class PolygonLayer extends StatelessWidget {
  final List<Polygon> polygons;

  /// screen space culling of polygons based on bounding box
  final bool polygonCulling;

  PolygonLayer({
    super.key,
    this.polygons = const [],
    this.polygonCulling = false,
  }) {
    if (polygonCulling) {
      for (final polygon in polygons) {
        polygon.boundingBox = LatLngBounds.fromPoints(polygon.points);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints bc) {
        final map = FlutterMapState.maybeOf(context)!;
        final size = Size(bc.maxWidth, bc.maxHeight);
        final polygonsWidget = <Widget>[];

        for (final polygon in polygons) {
          polygon.offsets.clear();

          if (null != polygon.holeOffsetsList) {
            for (final offsets in polygon.holeOffsetsList!) {
              offsets.clear();
            }
          }

          if (polygonCulling &&
              !polygon.boundingBox.isOverlapping(map.bounds)) {
            // skip this polygon as it's offscreen
            continue;
          }

          _fillOffsets(polygon.offsets, polygon.points, map);

          if (null != polygon.holePointsList) {
            final len = polygon.holePointsList!.length;
            for (var i = 0; i < len; ++i) {
              _fillOffsets(
                  polygon.holeOffsetsList![i], polygon.holePointsList![i], map);
            }
          }

          polygonsWidget.add(
            CustomPaint(
              painter: PolygonPainter(polygon),
              size: size,
            ),
          );
        }

        return Stack(
          children: polygonsWidget,
        );
      },
    );
  }

  void _fillOffsets(
      final List<Offset> offsets, final List<LatLng> points, FlutterMapState map) {
    final len = points.length;
    for (var i = 0; i < len; ++i) {
      final point = points[i];
      final offset = map.getOffsetFromOrigin(point);
      offsets.add(offset);
    }
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
    _paintPolygon(canvas, rect);
  }

  void _paintBorder(Canvas canvas) {
    if (polygonOpt.borderStrokeWidth > 0.0) {
      final borderPaint = Paint()
        ..color = polygonOpt.borderColor
        ..strokeWidth = polygonOpt.borderStrokeWidth;

      if (polygonOpt.isDotted) {
        final borderRadius = (polygonOpt.borderStrokeWidth / 2);

        final spacing = polygonOpt.borderStrokeWidth * 1.5;
        _paintDottedLine(
            canvas, polygonOpt.offsets, borderRadius, spacing, borderPaint);

        if (!polygonOpt.disableHolesBorder &&
            null != polygonOpt.holeOffsetsList) {
          for (final offsets in polygonOpt.holeOffsetsList!) {
            _paintDottedLine(
                canvas, offsets, borderRadius, spacing, borderPaint);
          }
        }
      } else {
        borderPaint
          ..style = PaintingStyle.stroke
          ..strokeCap = polygonOpt.strokeCap
          ..strokeJoin = polygonOpt.strokeJoin;

        _paintLine(canvas, polygonOpt.offsets, borderPaint);

        if (!polygonOpt.disableHolesBorder &&
            null != polygonOpt.holeOffsetsList) {
          for (final offsets in polygonOpt.holeOffsetsList!) {
            _paintLine(canvas, offsets, borderPaint);
          }
        }
      }
    }
  }

  void _paintDottedLine(Canvas canvas, List<Offset> offsets, double radius,
      double stepLength, Paint paint) {
    var startDistance = 0.0;
    for (var i = 0; i < offsets.length; i++) {
      final o0 = offsets[i % offsets.length];
      final o1 = offsets[(i + 1) % offsets.length];
      final totalDistance = _dist(o0, o1);
      var distance = startDistance;
      while (distance < totalDistance) {
        final f1 = distance / totalDistance;
        final f0 = 1.0 - f1;
        final offset = Offset(o0.dx * f0 + o1.dx * f1, o0.dy * f0 + o1.dy * f1);
        canvas.drawCircle(offset, radius, paint);
        distance += stepLength;
      }
      startDistance = distance < totalDistance
          ? stepLength - (totalDistance - distance)
          : distance - totalDistance;
    }
    canvas.drawCircle(offsets.last, radius, paint);
  }

  void _paintLine(Canvas canvas, List<Offset> offsets, Paint paint) {
    if (offsets.isEmpty) {
      return;
    }
    final path = Path()..addPolygon(offsets, true);
    canvas.drawPath(path, paint);
  }

  void _paintPolygon(Canvas canvas, Rect rect) {
    final paint = Paint();

    if (null != polygonOpt.holeOffsetsList) {
      canvas.saveLayer(rect, paint);
      paint.style = PaintingStyle.fill;

      for (final offsets in polygonOpt.holeOffsetsList!) {
        final path = Path();
        path.addPolygon(offsets, true);
        canvas.drawPath(path, paint);
      }

      paint
        ..color = polygonOpt.color
        ..blendMode = BlendMode.srcOut;

      final path = Path();
      path.addPolygon(polygonOpt.offsets, true);
      canvas.drawPath(path, paint);

      _paintBorder(canvas);

      canvas.restore();
    } else {
      canvas.clipRect(rect);
      paint
        ..style =
            polygonOpt.isFilled ? PaintingStyle.fill : PaintingStyle.stroke
        ..color = polygonOpt.color;

      final path = Path();
      path.addPolygon(polygonOpt.offsets, true);
      canvas.drawPath(path, paint);

      _paintBorder(canvas);

      if (polygonOpt.label != null) {
        Label.paintText(
          canvas,
          polygonOpt.offsets,
          polygonOpt.label,
          polygonOpt.labelStyle,
          labelPlacement: polygonOpt.labelPlacement,
        );
      }
    }
  }

  @override
  bool shouldRepaint(PolygonPainter oldDelegate) => false;

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

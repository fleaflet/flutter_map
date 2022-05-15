import 'dart:math';
import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/layer/label.dart';
import 'package:flutter_map/src/map/map.dart';
import 'package:latlong2/latlong.dart' hide Path; // conflict with Path from UI

class PolygonLayerOptions extends LayerOptions {
  final List<Polygon> polygons;
  final bool polygonCulling;

  /// screen space culling of polygons based on bounding box
  PolygonLayerOptions({
    Key? key,
    this.polygons = const [],
    this.polygonCulling = false,
    Stream<void>? rebuild,
  }) : super(key: key, rebuild: rebuild) {
    if (polygonCulling) {
      for (final polygon in polygons) {
        polygon.boundingBox = LatLngBounds.fromPoints(polygon.points);
      }
    }
  }
}

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
    this.label,
    this.labelStyle = const TextStyle(),
    this.labelPlacement = PolygonLabelPlacement.centroid,
  }) : holeOffsetsList = null == holePointsList || holePointsList.isEmpty
            ? null
            : List.generate(holePointsList.length, (_) => []);
}

class PolygonLayerWidget extends StatelessWidget {
  final PolygonLayerOptions options;
  const PolygonLayerWidget({Key? key, required this.options}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final mapState = MapState.maybeOf(context)!;
    return PolygonLayer(options, mapState, mapState.onMoved);
  }
}

class PolygonLayer extends StatelessWidget {
  final PolygonLayerOptions polygonOpts;
  final MapState map;
  final Stream<void>? stream;

  PolygonLayer(this.polygonOpts, this.map, this.stream)
      : super(key: polygonOpts.key);

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
    return StreamBuilder(
      stream: stream, // a Stream<void> or null
      builder: (BuildContext context, _) {
        final polygons = <Widget>[];

        for (final polygon in polygonOpts.polygons) {
          polygon.offsets.clear();

          if (null != polygon.holeOffsetsList) {
            for (final offsets in polygon.holeOffsetsList!) {
              offsets.clear();
            }
          }

          if (polygonOpts.polygonCulling &&
              !polygon.boundingBox.isOverlapping(map.bounds)) {
            // skip this polygon as it's offscreen
            continue;
          }

          _fillOffsets(polygon.offsets, polygon.points);

          if (null != polygon.holePointsList) {
            final len = polygon.holePointsList!.length;
            for (var i = 0; i < len; ++i) {
              _fillOffsets(
                  polygon.holeOffsetsList![i], polygon.holePointsList![i]);
            }
          }

          polygons.add(
            CustomPaint(
              painter: PolygonPainter(polygon),
              size: size,
            ),
          );
        }

        return Stack(
          children: polygons,
        );
      },
    );
  }

  void _fillOffsets(final List<Offset> offsets, final List<LatLng> points) {
    final len = points.length;
    for (var i = 0; i < len; ++i) {
      final point = points[i];

      var pos = map.project(point);
      pos = pos.multiplyBy(map.getZoomScale(map.zoom, map.zoom)) -
          map.getPixelOrigin();
      offsets.add(Offset(pos.x.toDouble(), pos.y.toDouble()));
      if (i > 0) {
        offsets.add(Offset(pos.x.toDouble(), pos.y.toDouble()));
      }
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
      final borderRadius = (polygonOpt.borderStrokeWidth / 2);

      final borderPaint = Paint()
        ..color = polygonOpt.borderColor
        ..strokeWidth = polygonOpt.borderStrokeWidth;

      if (polygonOpt.isDotted) {
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
        _paintLine(canvas, polygonOpt.offsets, borderRadius, borderPaint);

        if (!polygonOpt.disableHolesBorder &&
            null != polygonOpt.holeOffsetsList) {
          for (final offsets in polygonOpt.holeOffsetsList!) {
            _paintLine(canvas, offsets, borderRadius, borderPaint);
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

  void _paintLine(
      Canvas canvas, List<Offset> offsets, double radius, Paint paint) {
    canvas.drawPoints(PointMode.lines, [...offsets, offsets[0]], paint);
    for (final offset in offsets) {
      canvas.drawCircle(offset, radius, paint);
    }
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

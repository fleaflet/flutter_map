import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/map/flutter_map_state.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class Polyline {
  final Key? key;
  final List<LatLng> points;
  final double strokeWidth;
  final Color color;
  final double borderStrokeWidth;
  final Color? borderColor;
  final List<Color>? gradientColors;
  final List<double>? colorsStop;
  final bool isDotted;
  final StrokeCap strokeCap;
  final StrokeJoin strokeJoin;
  final bool useStrokeWidthInMeter;

  LatLngBounds? _boundingBox;
  LatLngBounds get boundingBox {
    if (_boundingBox == null) {
      _boundingBox = LatLngBounds.fromPoints(points);
    }
    return _boundingBox!;
  }

  Polyline({
    required this.points,
    this.key,
    this.strokeWidth = 1.0,
    this.color = const Color(0xFF00FF00),
    this.borderStrokeWidth = 0.0,
    this.borderColor = const Color(0xFFFFFF00),
    this.gradientColors,
    this.colorsStop,
    this.isDotted = false,
    this.strokeCap = StrokeCap.round,
    this.strokeJoin = StrokeJoin.round,
    this.useStrokeWidthInMeter = false,
  });
}

class PolylineLayer extends StatelessWidget {
  /// List of polylines to draw.
  final List<Polyline> polylines;

  final bool polylineCulling;

  /// {@macro newPolylinePainter.saveLayers}
  ///
  /// By default, this value is set to `false` to improve performance on
  /// layers containing a lot of polylines.
  ///
  /// You might want to set this to `true` if you get unwanted darker lines
  /// where they overlap but, keep in mind that this might reduce the
  /// performance of the layer.
  final bool saveLayers;

  const PolylineLayer({
    super.key,
    this.polylines = const [],
    this.polylineCulling = false,
    this.saveLayers = false,
  });

  @override
  Widget build(BuildContext context) {
    final map = FlutterMapState.maybeOf(context)!;
    final zoom = map.zoom;
    final rotation = map.rotation;

    final origin = map.pixelOrigin;
    final offset = Offset(origin.x.toDouble(), origin.y.toDouble());

    final polylineWidgets = <Widget>[];
    for (final polyline in polylines) {
      if (polylineCulling && !polyline.boundingBox.isOverlapping(map.bounds)) {
        // Skip this polyline as it's offscreen
        continue;
      }

      final paint = CustomPaint(
        key: polyline.key,
        painter: PolylinePainter(polyline, saveLayers, map, zoom, rotation),
        size: Size(0, 0),
        // If we were smarter we could set willChange to true during
        // zooming/rotating the map and to false during moves.
        willChange: true,
        isComplex: true,
      );

      polylineWidgets.add(
        Positioned(
          left: -offset.dx,
          top: -offset.dy,
          // Avoid the RepaintBoundary for Web. In practice it turns out to be
          // faster to always redraw the polyline.
          child: kIsWeb
              ? paint
              : RepaintBoundary(key: ValueKey(polyline.hashCode), child: paint),
        ),
      );
    }

    return Stack(children: polylineWidgets);
  }
}

class PolylinePainter extends CustomPainter {
  final Polyline polyline;

  /// {@template newPolylinePainter.saveLayers}
  /// If `true`, the canvas will be updated on every frame by calling the
  /// methods [Canvas.saveLayer] and [Canvas.restore].
  /// {@endtemplate}
  final bool saveLayers;

  final FlutterMapState map;
  final double zoom;
  final double rotation;

  const PolylinePainter(
      this.polyline, this.saveLayers, this.map, this.zoom, this.rotation);

  List<Offset> getOffsets(List<LatLng> points) {
    return points.map((pos) {
      final delta = map.project(pos);
      return Offset(delta.x.toDouble(), delta.y.toDouble());
    }).toList();
  }

  static Size getSize(List<Offset> offsets) {
    double maxx = 0, minx = 0, maxy = 0, miny = 0;
    for (final offset in offsets) {
      maxx = max(maxx, offset.dx);
      minx = min(minx, offset.dx);
      maxy = max(maxy, offset.dy);
      miny = min(miny, offset.dy);
    }
    return Size(maxx - minx, maxy - miny);
  }

  @override
  void paint(Canvas canvas, Size _) {
    final offsets = getOffsets(polyline.points);
    if (offsets.isEmpty) {
      return;
    }

    Rect rect = Offset.zero & Size(0, 0);
    if (saveLayers) {
      rect = Offset.zero & getSize(offsets);
      canvas.clipRect(rect);
    }

    late final double strokeWidth;
    if (polyline.useStrokeWidthInMeter) {
      final firstPoint = polyline.points.first;
      final firstOffset = offsets.first;
      final r = const Distance().offset(
        firstPoint,
        polyline.strokeWidth,
        180,
      );
      final delta = firstOffset - map.getOffsetFromOrigin(r);

      strokeWidth = delta.distance;
    } else {
      strokeWidth = polyline.strokeWidth;
    }
    final paint = Paint()
      ..strokeWidth = strokeWidth
      ..strokeCap = polyline.strokeCap
      ..strokeJoin = polyline.strokeJoin
      ..blendMode = BlendMode.srcOver;

    if (polyline.gradientColors == null) {
      paint.color = polyline.color;
    } else {
      polyline.gradientColors!.isNotEmpty
          ? paint.shader = _paintGradient(offsets)
          : paint.color = polyline.color;
    }

    Paint? filterPaint;
    if (polyline.borderColor != null) {
      filterPaint = Paint()
        ..color = polyline.borderColor!.withAlpha(255)
        ..strokeWidth = strokeWidth
        ..strokeCap = polyline.strokeCap
        ..strokeJoin = polyline.strokeJoin
        ..blendMode = BlendMode.dstOut;
    }

    final borderPaint = polyline.borderStrokeWidth > 0.0
        ? (Paint()
          ..color = polyline.borderColor ?? const Color(0x00000000)
          ..strokeWidth = strokeWidth + polyline.borderStrokeWidth
          ..strokeCap = polyline.strokeCap
          ..strokeJoin = polyline.strokeJoin
          ..blendMode = BlendMode.srcOver)
        : null;
    final radius = paint.strokeWidth / 2;
    final borderRadius = (borderPaint?.strokeWidth ?? 0) / 2;
    if (polyline.isDotted) {
      final spacing = strokeWidth * 1.5;
      if (saveLayers) canvas.saveLayer(rect, Paint());
      if (borderPaint != null && filterPaint != null) {
        _paintDottedLine(canvas, offsets, borderRadius, spacing, borderPaint);
        _paintDottedLine(canvas, offsets, radius, spacing, filterPaint);
      }
      _paintDottedLine(canvas, offsets, radius, spacing, paint);
      if (saveLayers) canvas.restore();
    } else {
      paint.style = PaintingStyle.stroke;
      if (saveLayers) canvas.saveLayer(rect, Paint());
      if (borderPaint != null && filterPaint != null) {
        borderPaint.style = PaintingStyle.stroke;
        _paintLine(canvas, offsets, borderPaint);
        filterPaint.style = PaintingStyle.stroke;
        _paintLine(canvas, offsets, filterPaint);
      }
      _paintLine(canvas, offsets, paint);
      if (saveLayers) canvas.restore();
    }
  }

  void _paintDottedLine(Canvas canvas, List<Offset> offsets, double radius,
      double stepLength, Paint paint) {
    final path = ui.Path();
    var startDistance = 0.0;
    for (var i = 0; i < offsets.length - 1; i++) {
      final o0 = offsets[i];
      final o1 = offsets[i + 1];
      final totalDistance = _dist(o0, o1);
      var distance = startDistance;
      while (distance < totalDistance) {
        final f1 = distance / totalDistance;
        final f0 = 1.0 - f1;
        final offset = Offset(o0.dx * f0 + o1.dx * f1, o0.dy * f0 + o1.dy * f1);
        path.addOval(Rect.fromCircle(center: offset, radius: radius));
        distance += stepLength;
      }
      startDistance = distance < totalDistance
          ? stepLength - (totalDistance - distance)
          : distance - totalDistance;
    }
    path.addOval(Rect.fromCircle(center: offsets.last, radius: radius));
    canvas.drawPath(path, paint);
  }

  void _paintLine(Canvas canvas, List<Offset> offsets, Paint paint) {
    if (offsets.isEmpty) {
      return;
    }
    final path = ui.Path()..addPolygon(offsets, false);
    canvas.drawPath(path, paint);
  }

  ui.Gradient _paintGradient(List<Offset> offsets) => ui.Gradient.linear(
      offsets.first, offsets.last, polyline.gradientColors!, _getColorsStop());

  List<double>? _getColorsStop() => (polyline.colorsStop != null &&
          polyline.colorsStop!.length == polyline.gradientColors!.length)
      ? polyline.colorsStop
      : _calculateColorsStop();

  List<double> _calculateColorsStop() {
    final colorsStopInterval = 1.0 / polyline.gradientColors!.length;
    return polyline.gradientColors!
        .map((gradientColor) =>
            polyline.gradientColors!.indexOf(gradientColor) *
            colorsStopInterval)
        .toList();
  }

  @override
  bool shouldRepaint(PolylinePainter oldDelegate) {
    return zoom != oldDelegate.zoom || rotation != oldDelegate.rotation;
  }
}

double _dist(Offset v, Offset w) {
  return sqrt(_sqr(v.dx - w.dx) + _sqr(v.dy - w.dy));
}

double _sqr(double x) {
  return x * x;
}

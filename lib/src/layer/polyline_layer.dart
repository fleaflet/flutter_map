import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/map/flutter_map_state.dart';
import 'package:latlong2/latlong.dart';

class Polyline {
  final Key? key;
  final List<LatLng> points;
  final List<Offset> offsets = [];
  double strokeWidth;
  final Color color;
  final double borderStrokeWidth;
  final Color? borderColor;
  final List<Color>? gradientColors;
  final List<double>? colorsStop;
  final bool isDotted;
  final StrokeCap strokeCap;
  final StrokeJoin strokeJoin;
  final bool useStrokeWidthInMeter;
  late LatLngBounds boundingBox;

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

  PolylineLayer({
    super.key,
    this.polylines = const [],
    this.polylineCulling = false,
    this.saveLayers = false,
  }) {
    if (polylineCulling) {
      for (final polyline in polylines) {
        polyline.boundingBox = LatLngBounds.fromPoints(polyline.points);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final map = FlutterMapState.maybeOf(context)!;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints bc) {
        final size = Size(bc.maxWidth, bc.maxHeight);
        final polylineWidgets = <Widget>[];

        for (final polylineOpt in polylines) {
          polylineOpt.offsets.clear();

          if (polylineCulling &&
              !polylineOpt.boundingBox.isOverlapping(map.bounds)) {
            // skip this polyline as it's offscreen
            continue;
          }

          _fillOffsets(polylineOpt.offsets, polylineOpt.points, map);

          polylineWidgets.add(
            CustomPaint(
              key: polylineOpt.key,
              painter: PolylinePainter(polylineOpt, saveLayers, map),
              size: size,
            ),
          );
        }

        return Stack(
          children: polylineWidgets,
        );
      },
    );
  }

  void _fillOffsets(
    final List<Offset> offsets,
    final List<LatLng> points,
    FlutterMapState map,
  ) {
    final len = points.length;
    for (var i = 0; i < len; ++i) {
      final point = points[i];
      final offset = map.getOffsetFromOrigin(point);
      offsets.add(offset);
    }
  }
}

class PolylinePainter extends CustomPainter {
  final Polyline polylineOpt;

  /// {@template newPolylinePainter.saveLayers}
  /// If `true`, the canvas will be updated on every frame by calling the
  /// methods [Canvas.saveLayer] and [Canvas.restore].
  /// {@endtemplate}
  final bool saveLayers;

  final FlutterMapState map;

  PolylinePainter(this.polylineOpt, this.saveLayers, this.map);

  @override
  void paint(Canvas canvas, Size size) {
    if (polylineOpt.offsets.isEmpty) {
      return;
    }

    final rect = Offset.zero & size;
    canvas.clipRect(rect);

    late final double strokeWidth;
    if (polylineOpt.useStrokeWidthInMeter) {
      final firstPoint = polylineOpt.points.first;
      final firstOffset = polylineOpt.offsets.first;
      final r = const Distance().offset(
        firstPoint,
        polylineOpt.strokeWidth,
        180,
      );
      final delta = firstOffset - map.getOffsetFromOrigin(r);

      strokeWidth = delta.distance;
    } else {
      strokeWidth = polylineOpt.strokeWidth;
    }
    final paint = Paint()
      ..strokeWidth = strokeWidth
      ..strokeCap = polylineOpt.strokeCap
      ..strokeJoin = polylineOpt.strokeJoin
      ..blendMode = BlendMode.srcOver;

    if (polylineOpt.gradientColors == null) {
      paint.color = polylineOpt.color;
    } else {
      polylineOpt.gradientColors!.isNotEmpty
          ? paint.shader = _paintGradient()
          : paint.color = polylineOpt.color;
    }

    Paint? filterPaint;
    if (polylineOpt.borderColor != null) {
      filterPaint = Paint()
        ..color = polylineOpt.borderColor!.withAlpha(255)
        ..strokeWidth = strokeWidth
        ..strokeCap = polylineOpt.strokeCap
        ..strokeJoin = polylineOpt.strokeJoin
        ..blendMode = BlendMode.dstOut;
    }

    final borderPaint = polylineOpt.borderStrokeWidth > 0.0
        ? (Paint()
          ..color = polylineOpt.borderColor ?? const Color(0x00000000)
          ..strokeWidth = strokeWidth + polylineOpt.borderStrokeWidth
          ..strokeCap = polylineOpt.strokeCap
          ..strokeJoin = polylineOpt.strokeJoin
          ..blendMode = BlendMode.srcOver)
        : null;
    final radius = paint.strokeWidth / 2;
    final borderRadius = (borderPaint?.strokeWidth ?? 0) / 2;
    if (polylineOpt.isDotted) {
      final spacing = strokeWidth * 1.5;
      if (saveLayers) canvas.saveLayer(rect, Paint());
      if (borderPaint != null && filterPaint != null) {
        _paintDottedLine(
            canvas, polylineOpt.offsets, borderRadius, spacing, borderPaint);
        _paintDottedLine(
            canvas, polylineOpt.offsets, radius, spacing, filterPaint);
      }
      _paintDottedLine(canvas, polylineOpt.offsets, radius, spacing, paint);
      if (saveLayers) canvas.restore();
    } else {
      paint.style = PaintingStyle.stroke;
      if (saveLayers) canvas.saveLayer(rect, Paint());
      if (borderPaint != null && filterPaint != null) {
        borderPaint.style = PaintingStyle.stroke;
        _paintLine(canvas, polylineOpt.offsets, borderPaint);
        filterPaint.style = PaintingStyle.stroke;
        _paintLine(canvas, polylineOpt.offsets, filterPaint);
      }
      _paintLine(canvas, polylineOpt.offsets, paint);
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
    path.addOval(
        Rect.fromCircle(center: polylineOpt.offsets.last, radius: radius));
    canvas.drawPath(path, paint);
  }

  void _paintLine(Canvas canvas, List<Offset> offsets, Paint paint) {
    if (offsets.isEmpty) {
      return;
    }
    final path = ui.Path()..addPolygon(offsets, false);
    canvas.drawPath(path, paint);
  }

  ui.Gradient _paintGradient() => ui.Gradient.linear(polylineOpt.offsets.first,
      polylineOpt.offsets.last, polylineOpt.gradientColors!, _getColorsStop());

  List<double>? _getColorsStop() => (polylineOpt.colorsStop != null &&
          polylineOpt.colorsStop!.length == polylineOpt.gradientColors!.length)
      ? polylineOpt.colorsStop
      : _calculateColorsStop();

  List<double> _calculateColorsStop() {
    final colorsStopInterval = 1.0 / polylineOpt.gradientColors!.length;
    return polylineOpt.gradientColors!
        .map((gradientColor) =>
            polylineOpt.gradientColors!.indexOf(gradientColor) *
            colorsStopInterval)
        .toList();
  }

  @override
  bool shouldRepaint(PolylinePainter oldDelegate) => false;
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

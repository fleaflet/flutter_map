import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/map/flutter_map_state.dart';
import 'package:latlong2/latlong.dart';

class Polyline {
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
    _boundingBox ??= LatLngBounds.fromPoints(points);
    return _boundingBox!;
  }

  Polyline({
    required this.points,
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

  /// Used to batch draw calls to the canvas.
  int get renderHashCode => Object.hash(
      strokeWidth,
      color,
      borderStrokeWidth,
      borderColor,
      gradientColors,
      colorsStop,
      isDotted,
      strokeCap,
      strokeJoin,
      useStrokeWidthInMeter);
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
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints bc) {
        final size = Size(bc.maxWidth, bc.maxHeight);
        final map = FlutterMapState.maybeOf(context)!;

        final Iterable<Polyline> lines = polylineCulling
            ? polylines.where((p) {
                return p.boundingBox.isOverlapping(map.bounds);
              })
            : polylines;

        return CustomPaint(
          key: UniqueKey(),
          painter: PolylinePainter(lines, saveLayers, map),
          size: size,
        );
      },
    );
  }
}

class PolylinePainter extends CustomPainter {
  final Iterable<Polyline> polylines;

  /// {@template newPolylinePainter.saveLayers}
  /// If `true`, the canvas will be updated on every frame by calling the
  /// methods [Canvas.saveLayer] and [Canvas.restore].
  /// {@endtemplate}
  final bool saveLayers;

  final FlutterMapState map;

  const PolylinePainter(this.polylines, this.saveLayers, this.map);

  List<Offset> getOffsets(List<LatLng> points) {
    return points.map((pos) => map.getOffsetFromOrigin(pos)).toList();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.clipRect(rect);

    var path = ui.Path();
    var borderPath = ui.Path();
    var filterPath = ui.Path();
    var paint = Paint();
    Paint? borderPaint;
    Paint? filterPaint;
    int? lastHash;

    void drawPaths() {
      canvas.drawPath(path, paint);
      path = ui.Path();
      paint = Paint();

      if (borderPaint != null) {
        canvas.drawPath(borderPath, borderPaint!);
        borderPath = ui.Path();
        borderPaint = null;
      }

      if (filterPaint != null) {
        canvas.drawPath(filterPath, filterPaint!);
        filterPath = ui.Path();
        filterPaint = null;
      }
    }

    for (final polyline in polylines) {
      final offsets = getOffsets(polyline.points);
      if (offsets.isEmpty) {
        continue;
      }

      final hash = polyline.renderHashCode;
      if (lastHash != null && lastHash != hash) {
        drawPaths();
      }
      lastHash = hash;

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

      final isDotted = polyline.isDotted;
      paint = Paint()
        ..strokeWidth = strokeWidth
        ..strokeCap = polyline.strokeCap
        ..strokeJoin = polyline.strokeJoin
        ..style = isDotted ? PaintingStyle.fill : PaintingStyle.stroke
        ..blendMode = BlendMode.srcOver;

      if (polyline.gradientColors == null) {
        paint.color = polyline.color;
      } else {
        polyline.gradientColors!.isNotEmpty
            ? paint.shader = _paintGradient(polyline, offsets)
            : paint.color = polyline.color;
      }

      if (polyline.borderColor != null) {
        filterPaint = Paint()
          ..color = polyline.borderColor!.withAlpha(255)
          ..strokeWidth = strokeWidth
          ..strokeCap = polyline.strokeCap
          ..strokeJoin = polyline.strokeJoin
          ..style = isDotted ? PaintingStyle.fill : PaintingStyle.stroke
          ..blendMode = BlendMode.dstOut;
      }

      if (polyline.borderStrokeWidth > 0.0) {
        borderPaint = Paint()
          ..color = polyline.borderColor ?? const Color(0x00000000)
          ..strokeWidth = strokeWidth + polyline.borderStrokeWidth
          ..strokeCap = polyline.strokeCap
          ..strokeJoin = polyline.strokeJoin
          ..style = isDotted ? PaintingStyle.fill : PaintingStyle.stroke
          ..blendMode = BlendMode.srcOver;
      }

      final radius = paint.strokeWidth / 2;
      final borderRadius = (borderPaint?.strokeWidth ?? 0) / 2;

      if (saveLayers) canvas.saveLayer(rect, Paint());
      if (isDotted) {
        final spacing = strokeWidth * 1.5;
        if (borderPaint != null && filterPaint != null) {
          _paintDottedLine(borderPath, offsets, borderRadius, spacing);
          _paintDottedLine(filterPath, offsets, radius, spacing);
        }
        _paintDottedLine(path, offsets, radius, spacing);
      } else {
        if (borderPaint != null && filterPaint != null) {
          _paintLine(borderPath, offsets);
          _paintLine(filterPath, offsets);
        }
        _paintLine(path, offsets);
      }
      if (saveLayers) canvas.restore();
    }

    drawPaths();
  }

  void _paintDottedLine(
      ui.Path path, List<Offset> offsets, double radius, double stepLength) {
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
  }

  void _paintLine(ui.Path path, List<Offset> offsets) {
    if (offsets.isEmpty) {
      return;
    }
    path.addPolygon(offsets, false);
  }

  ui.Gradient _paintGradient(Polyline polyline, List<Offset> offsets) =>
      ui.Gradient.linear(offsets.first, offsets.last, polyline.gradientColors!,
          _getColorsStop(polyline));

  List<double>? _getColorsStop(Polyline polyline) =>
      (polyline.colorsStop != null &&
              polyline.colorsStop!.length == polyline.gradientColors!.length)
          ? polyline.colorsStop
          : _calculateColorsStop(polyline);

  List<double> _calculateColorsStop(Polyline polyline) {
    final colorsStopInterval = 1.0 / polyline.gradientColors!.length;
    return polyline.gradientColors!
        .map((gradientColor) =>
            polyline.gradientColors!.indexOf(gradientColor) *
            colorsStopInterval)
        .toList();
  }

  @override
  bool shouldRepaint(PolylinePainter oldDelegate) => true;
}

double _dist(Offset v, Offset w) {
  return sqrt(_sqr(v.dx - w.dx) + _sqr(v.dy - w.dy));
}

double _sqr(double x) {
  return x * x;
}

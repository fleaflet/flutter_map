import 'dart:core';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/misc/simplify.dart';

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

@immutable
class PolylineLayer extends StatelessWidget {
  final List<Polyline> polylines;

  /// extent outside of the viewport before culling polylines, set to null to
  /// disable polyline culling
  final double? polylineCullingMargin;

  /// how much to simplify the polygons, in decimal degrees scaled to floored zoom
  final double? simplificationTolerance;

  /// high quality simplification uses the https://en.wikipedia.org/wiki/Ramer%E2%80%93Douglas%E2%80%93Peucker_algorithm
  /// otherwise, points within the radial distance of the threshold value are merged. (Also called radial distance simplification)
  /// radial distance is faster, but does not preserve the shape of the original line as well as Douglas Peucker
  final bool simplificationHighQuality;

  const PolylineLayer({
    super.key,
    required this.polylines,
    this.polylineCullingMargin = 0,
    this.simplificationTolerance = 1,
    this.simplificationHighQuality = false,
  });

  @override
  Widget build(BuildContext context) {
    final mapCamera = MapCamera.of(context);

    final renderedLines = <Polyline>[];

    if (polylineCullingMargin == null) {
      renderedLines.addAll(polylines);
    } else {
      final bounds = mapCamera.visibleBounds;
      final margin =
          polylineCullingMargin! / pow(2, mapCamera.zoom.floorToDouble());
      // The min(-90), max(180), etc.. are used to get around the limits of LatLng
      // the value cannot be greater or smaller than that
      final boundsAdjusted = LatLngBounds(
          LatLng(max(-90, bounds.southWest.latitude - margin),
              max(-180, bounds.southWest.longitude - margin)),
          LatLng(min(90, bounds.northEast.latitude + margin),
              min(180, bounds.northEast.longitude + margin)));

      for (final polyline in polylines) {
        // Gradiant poylines do not render identically and cannot be easily segmented
        if (polyline.gradientColors != null) {
          renderedLines.add(polyline);
          continue;
        }
        // pointer that indicates the start of the visible polyline segment
        int start = -1;
        bool fullyVisible = true;
        for (int i = 0; i < polyline.points.length - 1; i++) {
          //current pair
          final p1 = polyline.points[i];
          final p2 = polyline.points[i + 1];

          // segment is visible
          if (Bounds(
                  Point(boundsAdjusted.southWest.longitude,
                      boundsAdjusted.southWest.latitude),
                  Point(boundsAdjusted.northEast.longitude,
                      boundsAdjusted.northEast.latitude))
              .aabbContainsLine(
                  p1.longitude, p1.latitude, p2.longitude, p2.latitude)) {
            // segment is visible
            if (start == -1) {
              start = i;
            }
            if (!fullyVisible && i == polyline.points.length - 2) {
              final segment = polyline.points.sublist(start, i + 2);
              renderedLines.add(Polyline(
                points: segment,
                borderColor: polyline.borderColor,
                borderStrokeWidth: polyline.borderStrokeWidth,
                color: polyline.color,
                colorsStop: polyline.colorsStop,
                gradientColors: polyline.gradientColors,
                isDotted: polyline.isDotted,
                strokeCap: polyline.strokeCap,
                strokeJoin: polyline.strokeJoin,
                strokeWidth: polyline.strokeWidth,
                useStrokeWidthInMeter: polyline.useStrokeWidthInMeter,
              ));
            }
          } else {
            fullyVisible = false;
            // if we cannot see the segment, then reset start
            if (start != -1) {
              // partial start
              final segment = polyline.points.sublist(start, i + 1);
              // TODO copyWith method for polyline
              renderedLines.add(Polyline(
                points: segment,
                borderColor: polyline.borderColor,
                borderStrokeWidth: polyline.borderStrokeWidth,
                color: polyline.color,
                colorsStop: polyline.colorsStop,
                gradientColors: polyline.gradientColors,
                isDotted: polyline.isDotted,
                strokeCap: polyline.strokeCap,
                strokeJoin: polyline.strokeJoin,
                strokeWidth: polyline.strokeWidth,
                useStrokeWidthInMeter: polyline.useStrokeWidthInMeter,
              ));
              start = -1;
            }
            if (start != -1) {
              start = i;
            }
          }
        }
        if (fullyVisible) {
          //The whole polyline is visible
          renderedLines.add(polyline);
        }
      }
    }

    return MobileLayerTransformer(
      child: CustomPaint(
        painter: PolylinePainter(renderedLines, mapCamera,
            simplificationTolerance, simplificationHighQuality),
        size: Size(mapCamera.size.x, mapCamera.size.y),
        isComplex: true,
      ),
    );
  }
}

class PolylinePainter extends CustomPainter {
  final List<Polyline> polylines;

  final MapCamera camera;
  final LatLngBounds bounds;

  final double? simplificationTolerance;
  final bool simplificationHighQuality;

  PolylinePainter(this.polylines, this.camera, this.simplificationTolerance,
      this.simplificationHighQuality)
      : bounds = camera.visibleBounds;

  int get hash => _hash ??= Object.hashAll(polylines);

  int? _hash;

  List<Offset> getOffsets(Offset origin, List<LatLng> points) {
    final List<LatLng> simplifiedPoints;
    if (simplificationTolerance != null) {
      simplifiedPoints = simplify(points,
          simplificationTolerance! / pow(2, camera.zoom.floorToDouble()),
          highestQuality: simplificationHighQuality);
    } else {
      simplifiedPoints = points;
    }
    return List.generate(simplifiedPoints.length, (index) {
      return getOffset(origin, simplifiedPoints[index]);
    }, growable: false);
  }

  Offset getOffset(Offset origin, LatLng point) {
    // Critically create as little garbage as possible. This is called on every frame.
    final projected = camera.project(point);
    return Offset(projected.x - origin.dx, projected.y - origin.dy);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    var path = ui.Path();
    var borderPath = ui.Path();
    var filterPath = ui.Path();
    var paint = Paint();
    var needsLayerSaving = false;

    Paint? borderPaint;
    Paint? filterPaint;
    int? lastHash;

    void drawPaths() {
      final hasBorder = borderPaint != null && filterPaint != null;
      if (hasBorder) {
        if (needsLayerSaving) {
          canvas.saveLayer(rect, Paint());
        }

        canvas.drawPath(borderPath, borderPaint!);
        borderPath = ui.Path();
        borderPaint = null;

        if (needsLayerSaving) {
          canvas.drawPath(filterPath, filterPaint!);
          filterPath = ui.Path();
          filterPaint = null;

          canvas.restore();
        }
      }

      canvas.drawPath(path, paint);
      path = ui.Path();
      paint = Paint();
    }

    final origin =
        camera.project(camera.center).toOffset() - camera.size.toOffset() / 2;

    for (final polyline in polylines) {
      final offsets = getOffsets(origin, polyline.points);
      if (offsets.isEmpty) {
        continue;
      }

      final hash = polyline.renderHashCode;
      if (needsLayerSaving || (lastHash != null && lastHash != hash)) {
        drawPaths();
      }
      lastHash = hash;
      needsLayerSaving = polyline.color.opacity < 1.0 ||
          (polyline.gradientColors?.any((c) => c.opacity < 1.0) ?? false);

      late final double strokeWidth;
      if (polyline.useStrokeWidthInMeter) {
        final firstPoint = polyline.points.first;
        final firstOffset = offsets.first;
        final r = const Distance().offset(
          firstPoint,
          polyline.strokeWidth,
          180,
        );
        final delta = firstOffset - getOffset(origin, r);

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

      if (polyline.borderColor != null && polyline.borderStrokeWidth > 0.0) {
        // Outlined lines are drawn by drawing a thicker path underneath, then
        // stenciling the middle (in case the line fill is transparent), and
        // finally drawing the line fill.
        borderPaint = Paint()
          ..color = polyline.borderColor ?? const Color(0x00000000)
          ..strokeWidth = strokeWidth + polyline.borderStrokeWidth
          ..strokeCap = polyline.strokeCap
          ..strokeJoin = polyline.strokeJoin
          ..style = isDotted ? PaintingStyle.fill : PaintingStyle.stroke
          ..blendMode = BlendMode.srcOver;

        filterPaint = Paint()
          ..color = polyline.borderColor!.withAlpha(255)
          ..strokeWidth = strokeWidth
          ..strokeCap = polyline.strokeCap
          ..strokeJoin = polyline.strokeJoin
          ..style = isDotted ? PaintingStyle.fill : PaintingStyle.stroke
          ..blendMode = BlendMode.dstOut;
      }

      final radius = paint.strokeWidth / 2;
      final borderRadius = (borderPaint?.strokeWidth ?? 0) / 2;

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
    }

    drawPaths();
  }

  void _paintDottedLine(
      ui.Path path, List<Offset> offsets, double radius, double stepLength) {
    var startDistance = 0.0;
    for (var i = 0; i < offsets.length - 1; i++) {
      final o0 = offsets[i];
      final o1 = offsets[i + 1];
      final totalDistance = (o0 - o1).distance;
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
  bool shouldRepaint(PolylinePainter oldDelegate) {
    return oldDelegate.bounds != bounds ||
        oldDelegate.polylines.length != polylines.length ||
        oldDelegate.hash != hash;
  }
}

import 'dart:core';
import 'dart:ui' as ui;

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/src/geo/latlng_bounds.dart';
import 'package:flutter_map/src/layer/general/mobile_layer_transformer.dart';
import 'package:flutter_map/src/map/camera/camera.dart';
import 'package:latlong2/latlong.dart';

class Polyline<T extends Object> {
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

  /// The tag of the polyline
  ///
  /// Tag is used to identify a [Polyline] or group of [Polyline]
  /// Tag does not have to be unique
  /// ```dart
  /// PolylineLayer<T>{
  ///   onTap: (polyline) {
  ///     if(polyline.tag == 'polylineTag')
  ///     myTap();
  ///   }
  /// }
  /// ```
  final T? tag;

  LatLngBounds? _boundingBox;

  LatLngBounds get boundingBox =>
      _boundingBox ??= LatLngBounds.fromPoints(points);

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
    this.tag,
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
      useStrokeWidthInMeter,
      tag);
}

@immutable
class PolylineLayer<T extends Object> extends StatelessWidget {
  final List<Polyline<T>> polylines;
  final bool polylineCulling;
  final void Function(Polyline<T> polyline)? onTap;

  const PolylineLayer({
    super.key,
    required this.polylines,
    this.polylineCulling = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final map = MapCamera.of(context);
    final visiblePolylines = polylineCulling
        ? polylines
            .where((p) => p.boundingBox.isOverlapping(map.visibleBounds))
            .toList()
        : polylines;

    final maybeTap = onTap;

    return MobileLayerTransformer(
      child: Stack(
          children: visiblePolylines
              .map(
                (polyline) => GestureDetector(
                  onTap: maybeTap != null ? () => maybeTap(polyline) : null,
                  child: CustomPaint(
                    painter: PolylinePainter<T>(
                      polyline,
                      map,
                    ),
                    size: Size(map.size.x, map.size.y),
                    isComplex: true,
                  ),
                ),
              )
              .toList()),
    );
  }
}

class PolylinePainter<T extends Object> extends CustomPainter {
  final Polyline<T> polyline;

  final MapCamera map;
  final LatLngBounds bounds;
  final _touchablePath = ui.Path();

  PolylinePainter(this.polyline, this.map) : bounds = map.visibleBounds;

  int get hash => _hash ??= Object.hashAll(polyline.points);

  int? _hash;

  Offset getOffset(LatLng point) => map.getOffsetFromOrigin(point);

  List<Offset> getOffsets(List<LatLng> points) {
    return List.generate(
      points.length,
      (index) {
        return getOffset(points[index]);
      },
      growable: false,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    var path = ui.Path();
    var borderPath = ui.Path();
    var filterPath = ui.Path();
    var paint = Paint();
    var needsLayerSaving = false;
    final offsets = getOffsets(polyline.points);

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

    final hash = polyline.renderHashCode;
    if (needsLayerSaving || lastHash != hash) {
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
      final delta = firstOffset - getOffset(r);

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
      _paintDottedLine(_touchablePath, offsets,
          (strokeWidth + polyline.borderStrokeWidth) / 2, spacing);
    } else {
      if (borderPaint != null && filterPaint != null) {
        _paintLine(borderPath, offsets);
        _paintLine(filterPath, offsets);
      }
      _paintLine(path, offsets);
      _paintTouchablePath(_touchablePath, offsets, strokeWidth);
    }
    drawPaths();
  }

  void _paintTouchablePath(
      ui.Path dottedPath, List<Offset> offsets, double radius) {
    // We used a widthFactor with a threshold to prevent radius too small for accessible tap
    final widthFactor = radius < 5.0 ? 5.0 : radius;
    for (final offset in offsets) {
      dottedPath.addOval(Rect.fromCircle(center: offset, radius: widthFactor));
    }
    offsets.forEachIndexed((index, offset) {
      if ((index + 1) < offsets.length) {
        final currentUnitPerpendicularVector = Offset(
          offsets[index + 1].dy - offset.dy,
          -offsets[index + 1].dx + offset.dx,
        );

        final test = (currentUnitPerpendicularVector /
                currentUnitPerpendicularVector.distance) *
            widthFactor;
        dottedPath.addPolygon([
          (offset + test),
          (offsets[index + 1] + test),
          (offsets[index + 1] - test),
          (offset - test),
        ], true);
      }
    });
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

  ui.Gradient _paintGradient(Polyline<T> polyline, List<Offset> offsets) =>
      ui.Gradient.linear(offsets.first, offsets.last, polyline.gradientColors!,
          _getColorsStop(polyline));

  List<double>? _getColorsStop(Polyline<T> polyline) =>
      (polyline.colorsStop != null &&
              polyline.colorsStop!.length == polyline.gradientColors!.length)
          ? polyline.colorsStop
          : _calculateColorsStop(polyline);

  List<double> _calculateColorsStop(Polyline<T> polyline) {
    final colorsStopInterval = 1.0 / polyline.gradientColors!.length;
    return polyline.gradientColors!
        .map((gradientColor) =>
            polyline.gradientColors!.indexOf(gradientColor) *
            colorsStopInterval)
        .toList();
  }

  @override
  bool hitTest(Offset position) => _touchablePath.contains(position);

  @override
  bool shouldRepaint(PolylinePainter<T> oldDelegate) {
    return oldDelegate.bounds != bounds || oldDelegate.hash != hash;
  }
}

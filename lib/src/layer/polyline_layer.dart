import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/map/flutter_map_state.dart';
import 'package:latlong2/latlong.dart';

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

  /// Bounding box from points.
  LatLngBounds get boundingBox => LatLngBounds.fromPoints(points);

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

  PolylineLayer({
    super.key,
    this.polylines = const [],
    this.polylineCulling = false,
    this.saveLayers = false,
  });

  @override
  Widget build(BuildContext context) {
    final map = FlutterMapState.maybeOf(context)!;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints bc) {
        final size = Size(bc.maxWidth, bc.maxHeight);

        return CustomPaint(
          painter: PolylinePainter(polylines, saveLayers, map, polylineCulling),
          size: size,
        );
      },
    );
  }
}

class PolylinePainter extends CustomPainter {
  final List<Polyline> polylines;

  /// {@template newPolylinePainter.saveLayers}
  /// If `true`, the canvas will be updated on every frame by calling the
  /// methods [Canvas.saveLayer] and [Canvas.restore].
  /// {@endtemplate}
  final bool saveLayers;
  final bool culling;

  final FlutterMapState map;

  PolylinePainter(this.polylines, this.saveLayers, this.map, this.culling);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final batches = <List<Polyline>>[];
    //Batch sequentially ordered polylines with the same rendering information
    int? lastHash;

    for (final polyline in polylines) {
      if (culling && !polyline.boundingBox.isOverlapping(map.bounds)) {
        // skip this polyline as it's offscreen
        continue;
      }
      final hash = polyline.renderHashCode;
      if (hash != lastHash) {
        batches.add([polyline]);
        lastHash = hash;
      } else {
        batches.last.add(polyline);
      }
    }

    canvas.clipRect(rect);

    for (final batch in batches) {
      //Only generate offsets for the first point in the batch
      //TODO this is also done later on the first iteration of the main loop redundantly
      final firstOffsets = List.generate(batch.first.points.length,
          (index) => map.getOffsetFromOrigin(batch.first.points[index]),
          growable: false);

      //TODO this one-liner might be better off not as one.
      final strokeWidth = batch.first.useStrokeWidthInMeter
          ? (firstOffsets.first -
                  map.getOffsetFromOrigin(const Distance().offset(
                    batch.first.points.first,
                    batch.first.strokeWidth,
                    180,
                  )))
              .distance
          : batch.first.strokeWidth;

      final paint = Paint()
        ..strokeWidth = strokeWidth
        ..strokeCap = batch.first.strokeCap
        ..strokeJoin = batch.first.strokeJoin
        ..blendMode = BlendMode.srcOver;

      if (batch.first.gradientColors == null) {
        paint.color = batch.first.color;
      } else {
        batch.first.gradientColors!.isNotEmpty
            ? paint.shader = ui.Gradient.linear(
                firstOffsets.first,
                firstOffsets.last,
                batch.first.gradientColors!,
                //_getColorsStop
                (batch.first.colorsStop != null &&
                        batch.first.colorsStop!.length ==
                            batch.first.gradientColors!.length)
                    ? batch.first.colorsStop
                    : _calculateColorsStop(batch.first))
            : paint.color = batch.first.color;
      }

      Paint? filterPaint;
      if (batch.first.borderColor != null) {
        filterPaint = Paint()
          ..color = batch.first.borderColor!.withAlpha(255)
          ..strokeWidth = strokeWidth
          ..strokeCap = batch.first.strokeCap
          ..strokeJoin = batch.first.strokeJoin
          ..blendMode = BlendMode.dstOut;
      }

      final borderPaint = batch.first.borderStrokeWidth > 0.0
          ? (Paint()
            ..color = batch.first.borderColor ?? const Color(0x00000000)
            ..strokeWidth = strokeWidth + batch.first.borderStrokeWidth
            ..strokeCap = batch.first.strokeCap
            ..strokeJoin = batch.first.strokeJoin
            ..blendMode = BlendMode.srcOver)
          : null;

      final radius = paint.strokeWidth / 2;
      final borderRadius = (borderPaint?.strokeWidth ?? 0) / 2;

      ui.Path polylinePaths = ui.Path();

      //Iterate through polylines and add their offsets using the material settings.
      for (final polyline in batch) {
        //Create offsets for each polyline
        final offsets = List.generate(polyline.points.length,
            (index) => map.getOffsetFromOrigin(polyline.points[index]),
            growable: false);

        if (polyline.isDotted) {
          //TODO optimize dotted polylines further than just 1 draw call per line.
          final spacing = strokeWidth * 1.5;
          if (saveLayers) canvas.saveLayer(rect, Paint());
          if (borderPaint != null && filterPaint != null) {
            _paintDottedLine(
                canvas, offsets, borderRadius, spacing, borderPaint);
            _paintDottedLine(canvas, offsets, radius, spacing, filterPaint);
          }
          _paintDottedLine(canvas, offsets, radius, spacing, paint);
          if (saveLayers) canvas.restore();
        } else {
          //Add offsets to path
          polylinePaths.addPolygon(offsets, false);
        }
      }

      if(batch.first.isDotted) {
        //Do nothing here for now.
      } else {
        paint.style = PaintingStyle.stroke;
        if (saveLayers) canvas.saveLayer(rect, Paint());
        if (borderPaint != null && filterPaint != null) {
          canvas.drawPath(polylinePaths, borderPaint);
          canvas.drawPath(polylinePaths, filterPaint);
        }
        canvas.drawPath(polylinePaths, paint);
        if (saveLayers) canvas.restore();
      }

    }
  }

  void _paintDottedLine(Canvas canvas, List<Offset> offsets, double radius,
      double stepLength, Paint paint) {
    final path = ui.Path();
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
    canvas.drawPath(path, paint);
  }

  List<double> _calculateColorsStop(Polyline polyline) {
    final colorsStopInterval = 1.0 / polyline.gradientColors!.length;
    return polyline.gradientColors!
        .map((gradientColor) =>
            polyline.gradientColors!.indexOf(gradientColor) *
            colorsStopInterval)
        .toList();
  }

  @override
  bool shouldRepaint(PolylinePainter oldDelegate) => false;
}


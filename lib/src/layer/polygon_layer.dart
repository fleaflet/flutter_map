import 'dart:math';

import 'package:flutter/material.dart';
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
  final List<List<LatLng>>? holePointsList;
  final Color color;
  final double borderStrokeWidth;
  final Color borderColor;
  final bool disableHolesBorder;
  final bool isDotted;
  final bool isFilled;
  final StrokeCap strokeCap;
  final StrokeJoin strokeJoin;
  final String? label;
  final TextStyle labelStyle;
  final PolygonLabelPlacement labelPlacement;
  final bool rotateLabel;

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
    this.rotateLabel = false,
  });

  /// Bounding box from points.
  LatLngBounds get boundingBox => LatLngBounds.fromPoints(points);

  /// Used to batch draw calls to the canvas.
  int get renderHashCode => Object.hash(color, borderStrokeWidth, borderColor,
      isDotted, isFilled, strokeCap, strokeJoin);
}

class PolygonLayer extends StatelessWidget {
  final List<Polygon> polygons;

  /// screen space culling of polygons based on bounding box
  final bool polygonCulling;

  const PolygonLayer({
    super.key,
    this.polygons = const [],
    this.polygonCulling = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints bc) {
        final map = FlutterMapState.maybeOf(context)!;
        final size = Size(bc.maxWidth, bc.maxHeight);

        return CustomPaint(
          painter: PolygonPainter(
              polygonOpts: polygons,
              rotationRad: map.rotationRad,
              map: map,
              polygonCulling: polygonCulling),
          size: size,
        );
      },
    );
  }
}

class PolygonPainter extends CustomPainter {
  final List<Polygon> polygonOpts;
  final double rotationRad;
  final FlutterMapState map;
  final bool polygonCulling;

  PolygonPainter(
      {required this.polygonOpts,
      required this.rotationRad,
      required this.map,
      required this.polygonCulling});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final batches = <List<Polygon>>[];
    //Batch sequentially ordered polygons with the same rendering information
    int? lastHash;
    for (final polygon in polygonOpts) {
      if (polygonCulling && !polygon.boundingBox.isOverlapping(map.bounds)) {
        // skip this polygon as it's offscreen
        continue;
      }
      final hash = polygon.renderHashCode;
      if (hash != lastHash) {
        batches.add([polygon]);
        lastHash = hash;
      } else {
        batches.last.add(polygon);
      }
    }

    // print("batch_rate ${1-(batches.length/polygonOpts.length)}");

    for (final batch in batches) {
      final fillPaint = Paint();
      final fillPath = Path();

      final borderPaint = Paint();
      final borderPath = Path();

      fillPaint
        ..style =
            batch.first.isFilled ? PaintingStyle.fill : PaintingStyle.stroke
        ..color = batch.first.color;

      borderPaint
        ..color = batch.first.borderColor
        ..strokeWidth = batch.first.borderStrokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = batch.first.strokeCap
        ..strokeJoin = batch.first.strokeJoin;

      //Render each polygon on the canvas.
      for (final polygon in batch) {
        //Offsets are potentially able to be pre-computed at a given projection
        //then transformed based on zoom + center.
        final polygonOffsets = List.generate(polygon.points.length,
            (index) => map.getOffsetFromOrigin(polygon.points[index]),
            growable: false);

        if (polygon.holePointsList == null) {
          //Polygon without holes
          fillPath.addPolygon(polygonOffsets, true);

          _paintBorder(canvas, polygon, polygonOffsets, null, borderPaint, borderPath);
        } else {
          //Polygon with holes
          final holePolygonPaint = Paint()
            ..style =
                batch.first.isFilled ? PaintingStyle.fill : PaintingStyle.stroke
            ..color = batch.first.color;

          //TODO this is kinda an ugly one-liner.
          final polygonHoleOffsets = List.generate(
              polygon.holePointsList!.length,
              (poly) => List.generate(
                  polygon.holePointsList![poly].length,
                  (index) => map.getOffsetFromOrigin(
                      polygon.holePointsList![poly][index]),
                  growable: false),
              growable: false);

          canvas.saveLayer(rect, holePolygonPaint);
          holePolygonPaint.style = PaintingStyle.fill;

          for (final offsets in polygonHoleOffsets) {
            final path = Path();
            path.addPolygon(offsets, true);
            canvas.drawPath(path, holePolygonPaint);
          }

          holePolygonPaint
            ..color = polygon.color
            ..blendMode = BlendMode.srcOut;

          final path = Path();
          fillPath.addPolygon(polygonOffsets, true);
          canvas.drawPath(path, holePolygonPaint);

          _paintBorder(
              canvas, polygon, polygonOffsets, polygonHoleOffsets, borderPaint, borderPath);

          canvas.restore();
        }
      }

      //Draw the polygon fills
      canvas.drawPath(fillPath, fillPaint);
      //Draw the polygon border
      canvas.drawPath(borderPath, borderPaint);

      //Draw labels
      for (final polygon in batch) {
        if (polygon.label != null) {
          //It's probably fine to do this since the calculation is fairly lightweight.
          final polygonOffsets = List.generate(polygon.points.length,
              (index) => map.getOffsetFromOrigin(polygon.points[index]),
              growable: false);
          Label.paintText(
            canvas,
            polygonOffsets,
            polygon.label,
            polygon.labelStyle,
            rotationRad,
            rotate: polygon.rotateLabel,
            labelPlacement: polygon.labelPlacement,
          );
        }
      }
    }
    canvas.clipRect(rect);
  }

  void _paintBorder(Canvas canvas, Polygon polygon, List<Offset> polygonOffsets,
      List<List<Offset>>? polygonHoleOffsets, Paint borderPaint, Path solidPath) {
    if (polygon.borderStrokeWidth > 0.0) {
      if (polygon.isDotted) {
        // Dotted polygon
        final borderRadius = (polygon.borderStrokeWidth / 2);

        final spacing = polygon.borderStrokeWidth * 1.5;
        _paintDottedLine(
            canvas, polygonOffsets, borderRadius, spacing, borderPaint);

        if (!polygon.disableHolesBorder && null != polygonHoleOffsets) {
          for (final offsets in polygonHoleOffsets) {
            _paintDottedLine(
                canvas, offsets, borderRadius, spacing, borderPaint);
          }
        }
      } else {
        //Solid polygon
        solidPath.addPolygon(polygonOffsets, true);
        if (!polygon.disableHolesBorder && null != polygonHoleOffsets) {
          for (final offsets in polygonHoleOffsets) {
            solidPath.addPolygon(offsets, true);
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

  @override
  bool shouldRepaint(PolygonPainter oldDelegate) => false;

  double _dist(Offset v, Offset w) => sqrt(_dist2(v, w));

  double _dist2(Offset v, Offset w) => _sqr(v.dx - w.dx) + _sqr(v.dy - w.dy);

  double _sqr(double x) => x * x;
}

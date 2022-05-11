import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/map/map.dart';
import 'package:latlong2/latlong.dart';

class PolylineLayerOptions extends LayerOptions {
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

  PolylineLayerOptions({
    Key? key,
    this.polylines = const [],
    this.polylineCulling = false,
    Stream<void>? rebuild,
    this.saveLayers = false,
  }) : super(key: key, rebuild: rebuild) {
    if (polylineCulling) {
      for (var polyline in polylines) {
        polyline.boundingBox = LatLngBounds.fromPoints(polyline.points);
      }
    }
  }
}

const double degToRad = pi / 180;
const double radToDeg = 180 / pi;

class Polyline {
  final List<LatLng> points;
  final List<Offset> offsets = [];
  final double strokeWidth;
  final Color color;
  final double borderStrokeWidth;
  final Color? borderColor;
  final List<Color>? gradientColors;
  final List<double>? colorsStop;
  final bool isDotted;
  final StrokeCap strokeCap;
  final StrokeJoin strokeJoin;
  final TextSpan? text;
  final double textPosition;
  final double textOffset;
  late LatLngBounds boundingBox;

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
    this.text,
    this.textPosition = 0.5,
    this.textOffset = 0,
  });
}

class PolylineLayerWidget extends StatelessWidget {
  final PolylineLayerOptions options;

  const PolylineLayerWidget({Key? key, required this.options})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final mapState = MapState.maybeOf(context)!;
    return PolylineLayer(options, mapState, mapState.onMoved);
  }
}

class PolylineLayer extends StatelessWidget {
  final PolylineLayerOptions polylineOpts;
  final MapState map;
  final Stream<void>? stream;

  PolylineLayer(this.polylineOpts, this.map, this.stream)
      : super(key: polylineOpts.key);

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
    return StreamBuilder<void>(
      stream: stream, // a Stream<void> or null
      builder: (BuildContext context, _) {
        var polylines = <Widget>[];

        for (var polylineOpt in polylineOpts.polylines) {
          polylineOpt.offsets.clear();

          if (polylineOpts.polylineCulling &&
              !polylineOpt.boundingBox.isOverlapping(map.bounds)) {
            // skip this polyline as it's offscreen
            continue;
          }

          _fillOffsets(polylineOpt.offsets, polylineOpt.points);

          polylines.add(CustomPaint(
            painter: PolylinePainter(polylineOpt, polylineOpts.saveLayers),
            size: size,
          ));
        }

        return Stack(
          children: polylines,
        );
      },
    );
  }

  void _fillOffsets(final List<Offset> offsets, final List<LatLng> points) {
    for (var i = 0, len = points.length; i < len; ++i) {
      var point = points[i];

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

class PolylinePainter extends CustomPainter {
  final Polyline polylineOpt;

  /// {@template newPolylinePainter.saveLayers}
  /// If `true`, the canvas will be updated on every frame by calling the
  /// methods [Canvas.saveLayer] and [Canvas.restore].
  /// {@endtemplate}
  final bool saveLayers;

  PolylinePainter(this.polylineOpt, this.saveLayers);

  @override
  void paint(Canvas canvas, Size size) {
    if (polylineOpt.offsets.isEmpty) {
      return;
    }
    final rect = Offset.zero & size;
    canvas.clipRect(rect);
    final paint = Paint()
      ..strokeWidth = polylineOpt.strokeWidth
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
        ..strokeWidth = polylineOpt.strokeWidth
        ..strokeCap = polylineOpt.strokeCap
        ..strokeJoin = polylineOpt.strokeJoin
        ..blendMode = BlendMode.dstOut;
    }

    final borderPaint = polylineOpt.borderStrokeWidth > 0.0
        ? (Paint()
          ..color = polylineOpt.borderColor ?? const Color(0x00000000)
          ..strokeWidth =
              polylineOpt.strokeWidth + polylineOpt.borderStrokeWidth
          ..strokeCap = polylineOpt.strokeCap
          ..strokeJoin = polylineOpt.strokeJoin
          ..blendMode = BlendMode.srcOver)
        : null;
    var radius = paint.strokeWidth / 2;
    var borderRadius = (borderPaint?.strokeWidth ?? 0) / 2;
    if (polylineOpt.isDotted) {
      var spacing = polylineOpt.strokeWidth * 1.5;
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
        _paintLine(
          canvas,
          polylineOpt.offsets,
          borderPaint,
          text: polylineOpt.text,
          textPosition: polylineOpt.textPosition,
          textOffset: polylineOpt.textOffset,
        );
        filterPaint.style = PaintingStyle.stroke;
        _paintLine(
          canvas,
          polylineOpt.offsets,
          filterPaint,
          text: polylineOpt.text,
          textPosition: polylineOpt.textPosition,
          textOffset: polylineOpt.textOffset,
        );
      }
      _paintLine(
        canvas,
        polylineOpt.offsets,
        paint,
        text: polylineOpt.text,
        textPosition: polylineOpt.textPosition,
        textOffset: polylineOpt.textOffset,
      );
      if (saveLayers) canvas.restore();
    }
  }

  void _paintDottedLine(Canvas canvas, List<Offset> offsets, double radius,
      double stepLength, Paint paint) {
    final path = ui.Path();
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

  void _paintLine(Canvas canvas, List<Offset> offsets, Paint paint,
      {TextSpan? text, double textPosition = 0.5, double textOffset = 0}) {
    var _textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      text: text ?? const TextSpan(text: ''),
    );

    if (offsets.isNotEmpty) {
      final path = ui.Path()..moveTo(offsets[0].dx, offsets[0].dy);
      for (var offset in offsets) {
        path.lineTo(offset.dx, offset.dy);
      }
      canvas.drawPath(path, paint);
      _textPainter.layout(
        minWidth: 0,
        maxWidth: double.maxFinite,
      );
      ui.Tangent? positionText;
      var metrics = path.computeMetrics();
      for (var metric in metrics) {
        positionText = metric.getTangentForOffset(metric.length * textPosition);

        if (metric.length < 100.0) {
          continue;
        }
      }
      var transformedPoint = positionText!.position;
      var drawPoint = Offset(0.0, -17.0 + textOffset);
      canvas.save();
      canvas.translate(transformedPoint.dx, transformedPoint.dy);
      var angleDeg = getNoneUpsideDownTextAngle(positionText.angle);

      canvas.rotate((angleDeg) * degToRad);
      _drawTextAt(drawPoint, canvas, 1, _textPainter);
      canvas.restore();
    }
  }

  double getNoneUpsideDownTextAngle(double angelDegree) {
    var angleDeg = -angelDegree * radToDeg;
    angleDeg += 90;

    if (angleDeg > 180) angleDeg -= 180;
    if (angleDeg < 0) angleDeg += 180;

    angleDeg -= 90;

    return angleDeg;
  }

  void _drawTextAt(Offset position, Canvas canvas, scale, textPainter) {
    var drawPosition = Offset(position.dx - textPainter.width / 2,
        position.dy + (textPainter.height / 2));
    textPainter.paint(canvas, drawPosition);
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

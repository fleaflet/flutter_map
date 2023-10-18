import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_map/src/layer/general/mobile_layer_transformer.dart';
import 'package:flutter_map/src/map/camera/camera.dart';
import 'package:latlong2/latlong.dart' hide Path;

/// Immutable marker options for circle markers
@immutable
class CircleMarker {
  final Key? key;
  final LatLng point;
  final double radius;
  final Color color;
  final double borderStrokeWidth;
  final Color borderColor;
  final bool useRadiusInMeter;

  const CircleMarker({
    required this.point,
    required this.radius,
    this.key,
    this.useRadiusInMeter = false,
    this.color = const Color(0xFF00FF00),
    this.borderStrokeWidth = 0.0,
    this.borderColor = const Color(0xFFFFFF00),
  });
}

@immutable
class CircleLayer extends StatelessWidget {
  final List<CircleMarker> circles;

  const CircleLayer({super.key, required this.circles});

  @override
  Widget build(BuildContext context) {
    final map = MapCamera.of(context);
    return MobileLayerTransformer(
      child: CustomPaint(
        painter: CirclePainter(circles, map),
        size: Size(map.size.x, map.size.y),
        isComplex: true,
      ),
    );
  }
}

@immutable
class CirclePainter extends CustomPainter {
  final List<CircleMarker> circles;
  final MapCamera map;

  const CirclePainter(this.circles, this.map);

  @override
  void paint(Canvas canvas, Size size) {
    const distance = Distance();
    final rect = Offset.zero & size;
    canvas.clipRect(rect);

    // Let's calculate all the points grouped by color and radius
    final points = <Color, Map<double, List<Offset>>>{};
    final pointsFilledBorder = <Color, Map<double, List<Offset>>>{};
    final pointsBorder = <Color, Map<double, Map<double, List<Offset>>>>{};
    for (final circle in circles) {
      final offset = map.getOffsetFromOrigin(circle.point);
      double radius = circle.radius;
      if (circle.useRadiusInMeter) {
        final r = distance.offset(circle.point, circle.radius, 180);
        final delta = offset - map.getOffsetFromOrigin(r);
        radius = delta.distance;
      }
      points[circle.color] ??= {};
      points[circle.color]![radius] ??= [];
      points[circle.color]![radius]!.add(offset);

      if (circle.borderStrokeWidth > 0) {
        // Check if color have some transparency or not
        // As drawPoints is more efficient than drawCircle
        if (circle.color.alpha == 0xFF) {
          double radiusBorder = circle.radius + circle.borderStrokeWidth;
          if (circle.useRadiusInMeter) {
            final rBorder = distance.offset(circle.point, radiusBorder, 180);
            final deltaBorder = offset - map.getOffsetFromOrigin(rBorder);
            radiusBorder = deltaBorder.distance;
          }
          pointsFilledBorder[circle.borderColor] ??= {};
          pointsFilledBorder[circle.borderColor]![radiusBorder] ??= [];
          pointsFilledBorder[circle.borderColor]![radiusBorder]!.add(offset);
        } else {
          double realRadius = circle.radius;
          if (circle.useRadiusInMeter) {
            final rBorder = distance.offset(circle.point, realRadius, 180);
            final deltaBorder = offset - map.getOffsetFromOrigin(rBorder);
            realRadius = deltaBorder.distance;
          }
          pointsBorder[circle.borderColor] ??= {};
          pointsBorder[circle.borderColor]![circle.borderStrokeWidth] ??= {};
          pointsBorder[circle.borderColor]![circle.borderStrokeWidth]![
              realRadius] ??= [];
          pointsBorder[circle.borderColor]![circle.borderStrokeWidth]![
                  realRadius]!
              .add(offset);
        }
      }
    }

    // Now that all the points are grouped, let's draw them
    final paintBorder = Paint()..style = PaintingStyle.stroke;
    for (final color in pointsBorder.keys) {
      final paint = paintBorder..color = color;
      for (final borderWidth in pointsBorder[color]!.keys) {
        final pointsByRadius = pointsBorder[color]![borderWidth]!;
        final radiusPaint = paint..strokeWidth = borderWidth;
        for (final radius in pointsByRadius.keys) {
          final pointsByRadiusColor = pointsByRadius[radius]!;
          for (final offset in pointsByRadiusColor) {
            _paintCircle(canvas, offset, radius, radiusPaint);
          }
        }
      }
    }

    // Then the filled border in order to be under the circle
    final paintPoint = Paint()
      ..isAntiAlias = false
      ..strokeCap = StrokeCap.round;
    for (final color in pointsFilledBorder.keys) {
      final paint = paintPoint..color = color;
      final pointsByRadius = pointsFilledBorder[color]!;
      for (final radius in pointsByRadius.keys) {
        final pointsByRadiusColor = pointsByRadius[radius]!;
        final radiusPaint = paint..strokeWidth = radius * 2;
        _paintPoints(canvas, pointsByRadiusColor, radiusPaint);
      }
    }

    // And then the circle
    for (final color in points.keys) {
      final paint = paintPoint..color = color;
      final pointsByRadius = points[color]!;
      for (final radius in pointsByRadius.keys) {
        final pointsByRadiusColor = pointsByRadius[radius]!;
        final radiusPaint = paint..strokeWidth = radius * 2;
        _paintPoints(canvas, pointsByRadiusColor, radiusPaint);
      }
    }
  }

  void _paintPoints(Canvas canvas, List<Offset> offsets, Paint paint) {
    canvas.drawPoints(PointMode.points, offsets, paint);
  }

  void _paintCircle(Canvas canvas, Offset offset, double radius, Paint paint) {
    canvas.drawCircle(offset, radius, paint);
  }

  @override
  bool shouldRepaint(CirclePainter oldDelegate) => false;
}

import 'package:flutter/widgets.dart';
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

  const CircleLayer({super.key, this.circles = const []});

  @override
  Widget build(BuildContext context) {
    final map = MapCamera.of(context);
    return LayoutBuilder(
      builder: (context, bc) {
        final size = Size(bc.maxWidth, bc.maxHeight);
        return CustomPaint(
          painter: CirclePainter(circles, map),
          size: size,
        );
      },
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
    final pointsBorder = <Color, Map<double, List<Offset>>>{};
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
        double radiusBorder = circle.radius + circle.borderStrokeWidth;
        if (circle.useRadiusInMeter) {
          final rBorder = distance.offset(circle.point, radiusBorder, 180);
          final deltaBorder = offset - map.getOffsetFromOrigin(rBorder);
          radiusBorder = deltaBorder.distance;
        }
        pointsBorder[circle.borderColor] ??= {};
        pointsBorder[circle.borderColor]![radiusBorder] ??= [];
        pointsBorder[circle.borderColor]![radiusBorder]!.add(offset);
      }
    }

    // Now that all the points are grouped, let's draw them
    // First by border in order to be under the circle
    for (final color in pointsBorder.keys) {
      final paint = Paint()
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = false
        ..color = color;
      final pointsByRadius = pointsBorder[color]!;
      for (final radius in pointsByRadius.keys) {
        final pointsByRadiusColor = pointsByRadius[radius]!;
        final radiusPaint = paint..strokeWidth = radius;
        _paintCircle(canvas, pointsByRadiusColor, radiusPaint);
      }
    }

    // And then the circle
    for (final color in points.keys) {
      final paint = Paint()
        ..isAntiAlias = false
        ..strokeCap = StrokeCap.round
        ..color = color;
      final pointsByRadius = points[color]!;
      for (final radius in pointsByRadius.keys) {
        final pointsByRadiusColor = pointsByRadius[radius]!;
        final radiusPaint = paint..strokeWidth = radius;
        _paintCircle(canvas, pointsByRadiusColor, radiusPaint);
      }
    }
  }

  void _paintCircle(Canvas canvas, List<Offset> offsets, Paint paint) {
    canvas.drawPoints(PointMode.points, offsets, paint);
  }

  @override
  bool shouldRepaint(CirclePainter oldDelegate) => false;
}

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
    const distance = Distance();
    return LayoutBuilder(
      builder: (context, bc) {
        final size = Size(bc.maxWidth, bc.maxHeight);
        final map = MapCamera.of(context);
        final circleWidgets = circles.map<Widget>((circle) {
          final offset = map.getOffsetFromOrigin(circle.point);
          double? realRadius;
          if (circle.useRadiusInMeter) {
            final r = distance.offset(circle.point, circle.radius, 180);
            final delta = offset - map.getOffsetFromOrigin(r);
            realRadius = delta.distance;
          }
          return CustomPaint(
            key: circle.key,
            painter: CirclePainter(
              circle,
              offset: offset,
              radius: realRadius ?? 0,
            ),
            size: size,
          );
        }).toList(growable: false);
        return Stack(children: circleWidgets);
      },
    );
  }
}

@immutable
class CirclePainter extends CustomPainter {
  final CircleMarker circle;
  final Offset offset;
  final double radius;

  const CirclePainter(
    this.circle, {
    this.offset = Offset.zero,
    this.radius = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.clipRect(rect);
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = circle.color;

    _paintCircle(canvas, offset,
        circle.useRadiusInMeter ? radius : circle.radius, paint);

    if (circle.borderStrokeWidth > 0) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..color = circle.borderColor
        ..strokeWidth = circle.borderStrokeWidth;

      _paintCircle(canvas, offset,
          circle.useRadiusInMeter ? radius : circle.radius, paint);
    }
  }

  void _paintCircle(Canvas canvas, Offset offset, double radius, Paint paint) {
    canvas.drawCircle(offset, radius, paint);
  }

  @override
  bool shouldRepaint(CirclePainter oldDelegate) => false;
}

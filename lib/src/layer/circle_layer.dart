import 'package:flutter/widgets.dart';
import 'package:flutter_map/src/map/flutter_map_state.dart';
import 'package:latlong2/latlong.dart' hide Path;

class CircleMarker {
  final LatLng point;
  final double radius;
  final Color color;
  final double borderStrokeWidth;
  final Color borderColor;
  final bool useRadiusInMeter;
  Offset offset = Offset.zero;
  num realRadius = 0;
  CircleMarker({
    required this.point,
    required this.radius,
    this.useRadiusInMeter = false,
    this.color = const Color(0xFF00FF00),
    this.borderStrokeWidth = 0.0,
    this.borderColor = const Color(0xFFFFFF00),
  });
}

class CircleLayer extends StatelessWidget {
  final List<CircleMarker> circles;
  const CircleLayer({
    super.key,
    this.circles = const [],
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints bc) {
        final size = Size(bc.maxWidth, bc.maxHeight);
        final map = FlutterMapState.maybeOf(context)!;
        final circleWidgets = <Widget>[];
        for (final circle in circles) {
          circle.offset = map.getOffsetFromOrigin(circle.point);

          if (circle.useRadiusInMeter) {
            final r = const Distance().offset(circle.point, circle.radius, 180);
            final delta = circle.offset - map.getOffsetFromOrigin(r);
            circle.realRadius = delta.distance;
          }

          circleWidgets.add(
            CustomPaint(
              painter: CirclePainter(circle),
              size: size,
            ),
          );
        }

        return Stack(
          children: circleWidgets,
        );
      },
    );
  }
}

class CirclePainter extends CustomPainter {
  final CircleMarker circle;
  CirclePainter(this.circle);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.clipRect(rect);
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = circle.color;

    _paintCircle(
        canvas,
        circle.offset,
        circle.useRadiusInMeter ? circle.realRadius as double : circle.radius,
        paint);

    if (circle.borderStrokeWidth > 0) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..color = circle.borderColor
        ..strokeWidth = circle.borderStrokeWidth;

      _paintCircle(
          canvas,
          circle.offset,
          circle.useRadiusInMeter ? circle.realRadius as double : circle.radius,
          paint);
    }
  }

  void _paintCircle(Canvas canvas, Offset offset, double radius, Paint paint) {
    canvas.drawCircle(offset, radius, paint);
  }

  @override
  bool shouldRepaint(CirclePainter oldDelegate) => false;
}

import 'package:flutter/widgets.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:latlong2/latlong.dart' hide Path;

class QuadraticCurveMarker {
  final LatLng startPoint;
  final LatLng endPoint;
  final LatLng handlePoint;

  final Color color;
  final double strokeWidth;
  final double borderStrokeWidth;
  final Color borderColor;

  QuadraticCurveMarker({
    required this.startPoint,
    required this.endPoint,
    required this.handlePoint,
    this.color = const Color.fromARGB(255, 255, 0, 0),
    this.strokeWidth = 2.0,
    this.borderStrokeWidth = 0.0,
    this.borderColor = const Color(0xFFFFFF00),
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is QuadraticCurveMarker &&
        other.startPoint == startPoint &&
        other.endPoint == endPoint &&
        other.handlePoint == handlePoint &&
        other.color == color &&
        other.strokeWidth == strokeWidth &&
        other.borderStrokeWidth == borderStrokeWidth &&
        other.borderColor == borderColor;
  }

  @override
  int get hashCode => Object.hash(
        startPoint,
        endPoint,
        handlePoint,
        color,
        strokeWidth,
        borderStrokeWidth,
        borderColor,
      );
}

class QuadraticCurveLayer extends StatelessWidget {
  final List<QuadraticCurveMarker> curves;
  const QuadraticCurveLayer({
    super.key,
    this.curves = const [],
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints bc) {
        final size = Size(bc.maxWidth, bc.maxHeight);
        final map = FlutterMapState.maybeOf(context)!;
        final curveWidgets = <Widget>[];
        for (final curve in curves) {
          curveWidgets.add(
            CustomPaint(
              painter: QuadraticCurvePainter(curve: curve, mapSate: map),
              size: size,
            ),
          );
        }

        return Stack(
          children: curveWidgets,
        );
      },
    );
  }
}

class QuadraticCurvePainter extends CustomPainter {
  final QuadraticCurveMarker curve;
  final FlutterMapState mapSate;
  QuadraticCurvePainter({
    required this.curve,
    required this.mapSate,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // LatLong to offset
    final start = mapSate.getOffsetFromOrigin(curve.startPoint);
    final end = mapSate.getOffsetFromOrigin(curve.endPoint);
    final handle = mapSate.getOffsetFromOrigin(curve.handlePoint);

    final rect = Offset.zero & size;
    canvas.clipRect(rect);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..color = curve.color
      ..strokeWidth = curve.strokeWidth;

    _paintCurve(canvas, paint, start, end, handle);

    if (curve.borderStrokeWidth > 0) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..color = curve.borderColor
        ..strokeWidth = curve.borderStrokeWidth;
      _paintCurve(canvas, paint, start, end, handle);
    }
  }

  void _paintCurve(
    Canvas canvas,
    Paint paint,
    Offset start,
    Offset end,
    Offset handle,
  ) {
    final path = Path();
    path.moveTo(start.dx, start.dy);
    path.quadraticBezierTo(handle.dx, handle.dy, end.dx, end.dy);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(QuadraticCurvePainter oldDelegate) => false;
}

// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/widgets.dart';
import 'package:flutter_map/plugin_api.dart';

import 'package:latlong2/latlong.dart' hide Path;

class QuadraticCurveMarker {
  final LatLng startPoint;
  final LatLng endPoint;
  final LatLng handlePoint;

  final Color color;
  final double borderStrokeWidth;
  final Color borderColor;

  Offset start = Offset.zero;
  Offset end = Offset.zero;
  Offset handle = Offset.zero;

  QuadraticCurveMarker({
    required this.startPoint,
    required this.endPoint,
    required this.handlePoint,
    this.color = const Color.fromARGB(255, 255, 0, 0),
    this.borderStrokeWidth = 0.0,
    this.borderColor = const Color(0xFFFFFF00),
  });

  @override
  bool operator ==(covariant QuadraticCurveMarker other) {
    if (identical(this, other)) return true;

    return other.startPoint == startPoint &&
        other.endPoint == endPoint &&
        other.handlePoint == handlePoint &&
        other.color == color &&
        other.borderStrokeWidth == borderStrokeWidth &&
        other.borderColor == borderColor &&
        other.start == start &&
        other.end == end &&
        other.handle == handle;
  }

  @override
  int get hashCode {
    return startPoint.hashCode ^
        endPoint.hashCode ^
        handlePoint.hashCode ^
        color.hashCode ^
        borderStrokeWidth.hashCode ^
        borderColor.hashCode ^
        start.hashCode ^
        end.hashCode ^
        handle.hashCode;
  }
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
          curve.start = map.getOffsetFromOrigin(curve.startPoint);
          curve.end = map.getOffsetFromOrigin(curve.endPoint);
          curve.handle = map.getOffsetFromOrigin(curve.handlePoint);

          curveWidgets.add(
            CustomPaint(
              painter: QuadraticCurvePainter(curve),
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
  QuadraticCurvePainter(this.curve);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.clipRect(rect);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..color = curve.color;

    _paintCurve(canvas, paint, curve.start, curve.end, curve.handle);

    if (curve.borderStrokeWidth > 0) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..color = curve.borderColor
        ..strokeWidth = curve.borderStrokeWidth;
      _paintCurve(canvas, paint, curve.start, curve.end, curve.handle);
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

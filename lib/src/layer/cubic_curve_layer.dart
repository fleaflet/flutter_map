import 'package:flutter/widgets.dart';
import 'package:flutter_map/src/map/flutter_map_state.dart';
import 'package:latlong2/latlong.dart' hide Path;

class CubicCurveMarker {
  final LatLng startPoint;
  final LatLng endPoint;
  final LatLng handlePointOne;
  final LatLng handlePointTwo;

  final Color color;
  final double borderStrokeWidth;
  final Color borderColor;

  Offset start = Offset.zero;
  Offset end = Offset.zero;
  Offset handleOne = Offset.zero;
  Offset handleTwo = Offset.zero;
  CubicCurveMarker({
    required this.startPoint,
    required this.endPoint,
    required this.handlePointOne,
    required this.handlePointTwo,
    this.color = const Color.fromARGB(255, 255, 0, 0),
    this.borderStrokeWidth = 0.0,
    this.borderColor = const Color(0xFFFFFF00),
  });

  @override
  bool operator ==(covariant CubicCurveMarker other) {
    if (identical(this, other)) return true;

    return other.startPoint == startPoint &&
        other.endPoint == endPoint &&
        other.handlePointOne == handlePointOne &&
        other.handlePointTwo == handlePointTwo &&
        other.color == color &&
        other.borderStrokeWidth == borderStrokeWidth &&
        other.borderColor == borderColor &&
        other.start == start &&
        other.end == end &&
        other.handleOne == handleOne &&
        other.handleTwo == handleTwo;
  }

  @override
  int get hashCode {
    return startPoint.hashCode ^
        endPoint.hashCode ^
        handlePointOne.hashCode ^
        handlePointTwo.hashCode ^
        color.hashCode ^
        borderStrokeWidth.hashCode ^
        borderColor.hashCode ^
        start.hashCode ^
        end.hashCode ^
        handleOne.hashCode ^
        handleTwo.hashCode;
  }
}

class CubicCurveLayer extends StatelessWidget {
  final List<CubicCurveMarker> curves;
  const CubicCurveLayer({
    super.key,
    this.curves = const [],
  });

  @override
  Widget build(BuildContext context) {
    final map = FlutterMapState.maybeOf(context)!;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints bc) {
        final size = Size(bc.maxWidth, bc.maxHeight);

        final curveWidgets = <Widget>[];
        for (final curve in curves) {
          curve.start = map.getOffsetFromOrigin(curve.startPoint);
          curve.end = map.getOffsetFromOrigin(curve.endPoint);
          curve.handleOne = map.getOffsetFromOrigin(curve.handlePointOne);
          curve.handleTwo = map.getOffsetFromOrigin(curve.handlePointTwo);
          curveWidgets.add(
            CustomPaint(
              painter: CubicCurvePainter(curve),
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

class CubicCurvePainter extends CustomPainter {
  final CubicCurveMarker curve;
  CubicCurvePainter(this.curve);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.clipRect(rect);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..color = curve.color;

    _paintCurve(canvas, paint, curve.start, curve.end, curve.handleOne,
        curve.handleTwo);

    if (curve.borderStrokeWidth > 0) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..color = curve.borderColor
        ..strokeWidth = curve.borderStrokeWidth;
      _paintCurve(canvas, paint, curve.start, curve.end, curve.handleOne,
          curve.handleTwo);
    }
  }

  void _paintCurve(Canvas canvas, Paint paint, Offset start, Offset end,
      Offset handleOne, Offset handleTwo) {
    final path = Path();
    path.moveTo(start.dx, start.dy);
    path.cubicTo(
        handleOne.dx, handleOne.dy, handleTwo.dx, handleTwo.dy, end.dx, end.dy);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CubicCurvePainter oldDelegate) => false;
}

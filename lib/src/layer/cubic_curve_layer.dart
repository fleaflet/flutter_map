import 'package:flutter/widgets.dart';
import 'package:flutter_map/src/map/flutter_map_state.dart';
import 'package:latlong2/latlong.dart' hide Path;

class CubicCurveMarker {
  final LatLng startPoint;
  final LatLng endPoint;
  final LatLng handlePointOne;
  final LatLng handlePointTwo;

  final Color color;
  final double strokeWidth;
  final double borderStrokeWidth;
  final Color borderColor;

  CubicCurveMarker({
    required this.startPoint,
    required this.endPoint,
    required this.handlePointOne,
    required this.handlePointTwo,
    this.color = const Color.fromARGB(255, 255, 0, 0),
    this.strokeWidth = 2.0,
    this.borderStrokeWidth = 0.0,
    this.borderColor = const Color(0xFFFFFF00),
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CubicCurveMarker &&
        other.startPoint == startPoint &&
        other.endPoint == endPoint &&
        other.handlePointOne == handlePointOne &&
        other.handlePointTwo == handlePointTwo &&
        other.color == color &&
        other.strokeWidth == strokeWidth &&
        other.borderStrokeWidth == borderStrokeWidth &&
        other.borderColor == borderColor;
  }

  @override
  int get hashCode => Object.hash(
        startPoint,
        endPoint,
        handlePointOne,
        handlePointTwo,
        color,
        strokeWidth,
        borderStrokeWidth,
        borderColor,
      );
}

class CubicCurveLayer extends StatelessWidget {
  final List<CubicCurveMarker> curves;
  const CubicCurveLayer({
    super.key,
    this.curves = const [],
  });

  @override
  Widget build(BuildContext context) {
    final mapState = FlutterMapState.maybeOf(context)!;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints bc) {
        final size = Size(bc.maxWidth, bc.maxHeight);

        final curveWidgets = <Widget>[];
        for (final curve in curves) {
          curveWidgets.add(
            CustomPaint(
              painter: CubicCurvePainter(curve: curve, mapState: mapState),
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
  final FlutterMapState mapState;
  CubicCurvePainter({required this.curve, required this.mapState});

  @override
  void paint(Canvas canvas, Size size) {
    // convert points from LatLng to offset
    final start = mapState.getOffsetFromOrigin(curve.startPoint);
    final end = mapState.getOffsetFromOrigin(curve.endPoint);
    final handleOne = mapState.getOffsetFromOrigin(curve.handlePointOne);
    final handleTwo = mapState.getOffsetFromOrigin(curve.handlePointTwo);

    final rect = Offset.zero & size;
    canvas.clipRect(rect);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..color = curve.color
      ..strokeWidth = curve.strokeWidth;

    _paintCurve(canvas, paint, start, end, handleOne, handleTwo);

    if (curve.borderStrokeWidth > 0) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..color = curve.borderColor
        ..strokeWidth = curve.borderStrokeWidth;
      _paintCurve(canvas, paint, start, end, handleOne, handleTwo);
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

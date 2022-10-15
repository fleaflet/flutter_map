import 'package:flutter/widgets.dart';
import 'package:flutter_map/src/map/flutter_map_state.dart';
import 'package:latlong2/latlong.dart' hide Path;

class ArcMarker {
  final LatLng centre;
  final double radius;

  final double startAngle;
  final double sweepAngle;

  final Color color;

  final double borderStrokeWidth;
  final Color borderColor;

  final bool useRadiusInMeter;

  Offset offset = Offset.zero;
  num realRadius = 0;

  ArcMarker({
    this.startAngle = 0,
    this.sweepAngle = 2 * pi,
    required this.centre,
    required this.radius,
    this.useRadiusInMeter = false,
    this.color = const Color.fromARGB(255, 255, 0, 0),
    this.borderStrokeWidth = 0.0,
    this.borderColor = const Color(0xFFFFFF00),
  });
}

class ArcLayer extends StatelessWidget {
  final List<ArcMarker> arcs;
  const ArcLayer({
    super.key,
    this.arcs = const [],
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints bc) {
        final size = Size(bc.maxWidth, bc.maxHeight);
        final map = FlutterMapState.maybeOf(context)!;
        final arcWidgets = <Widget>[];
        for (final arc in arcs) {
          arc.offset = map.getOffsetFromOrigin(arc.centre);

          if (arc.useRadiusInMeter) {
            final r = const Distance().offset(arc.centre, arc.radius, 180);
            final delta = arc.offset - map.getOffsetFromOrigin(r);
            arc.realRadius = delta.distance;
          }

          arcWidgets.add(
            CustomPaint(
              painter: ArcPainter(arc),
              size: size,
            ),
          );
        }

        return Stack(
          children: arcWidgets,
        );
      },
    );
  }
}

class ArcPainter extends CustomPainter {
  final ArcMarker arc;
  ArcPainter(this.arc);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.clipRect(rect);
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = arc.color
      ..isAntiAlias = true;

    _paintArc(canvas, arc.offset,
        arc.useRadiusInMeter ? arc.realRadius as double : arc.radius, paint,
        startAngle: arc.startAngle, sweepAngle: arc.sweepAngle);

    if (arc.borderStrokeWidth > 0) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..color = arc.borderColor
        ..strokeWidth = arc.borderStrokeWidth
        ..isAntiAlias = true;

      _paintArc(canvas, arc.offset,
          arc.useRadiusInMeter ? arc.realRadius as double : arc.radius, paint,
          startAngle: arc.startAngle, sweepAngle: arc.sweepAngle);
    }
  }

  void _paintArc(Canvas canvas, Offset offset, double radius, Paint paint,
      {required double startAngle, required double sweepAngle}) {
    canvas.drawArc(Rect.fromCircle(center: offset, radius: radius), startAngle,
        sweepAngle, false, paint);
        
  }

  @override
  bool shouldRepaint(ArcPainter oldDelegate) => false;
}

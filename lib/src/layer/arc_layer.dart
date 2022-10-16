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
  //TODO: add another constructor which calculates start and sweep angle form LatLong points

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ArcMarker &&
        other.centre == centre &&
        other.radius == radius &&
        other.startAngle == startAngle &&
        other.sweepAngle == sweepAngle &&
        other.color == color &&
        other.borderStrokeWidth == borderStrokeWidth &&
        other.borderColor == borderColor &&
        other.useRadiusInMeter == useRadiusInMeter;
  }

  @override
  int get hashCode => Object.hash(
        centre,
        radius,
        startAngle,
        sweepAngle,
        color,
        borderStrokeWidth,
        borderColor,
        useRadiusInMeter,
      );
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
        final mapState = FlutterMapState.maybeOf(context)!;
        final arcWidgets = <Widget>[];
        for (final arc in arcs) {
          arcWidgets.add(
            CustomPaint(
              painter: ArcPainter(arc: arc, mapState: mapState),
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
  final FlutterMapState mapState;
  ArcPainter({required this.arc, required this.mapState});

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    // centre of the arc
    final Offset centre = mapState.getOffsetFromOrigin(arc.centre);
    //calculations for radius
    double radius = arc.radius;
    if (arc.useRadiusInMeter) {
      final r = const Distance().offset(arc.centre, arc.radius, 180);
      final delta = centre - mapState.getOffsetFromOrigin(r);
      radius = delta.distance;
    }

    final rect = Offset.zero & size;
    canvas.clipRect(rect);
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = arc.color
      ..isAntiAlias = true;

    _paintArc(canvas, centre, radius, paint,
        startAngle: arc.startAngle, sweepAngle: arc.sweepAngle);

    if (arc.borderStrokeWidth > 0) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..color = arc.borderColor
        ..strokeWidth = arc.borderStrokeWidth
        ..isAntiAlias = true;

      _paintArc(canvas, centre, radius, paint,
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

import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/core/location_utils.dart';
import 'package:flutter_map/src/map/map.dart';
import 'package:latlong/latlong.dart' hide Path; // conflict with Path from UI

typedef CircleCallback(CircleMarker circle, LatLng location);

class CircleLayerOptions extends LayerOptions {
  final List<CircleMarker> circles;
  final CircleCallback onTap;
  final CircleCallback onLongPress;

  CircleLayerOptions({
    this.circles = const [],
    this.onTap,
    this.onLongPress,
  });
}

class CircleMarker {
  /// A [Key] to identify the [Circle]
  final Key key;

  /// The center of the Circle is specified as a [LatLng].
  final LatLng center;

  /// The radius of the circle, specified in meters. It should be zero or greater.
  final double radius;

  /// The color of the circle.
  final Color color;

  /// The width of the circle's outline.
  final double borderStrokeWidth;

  /// The color of the circle's outline.
  final Color borderColor;
  List<Offset> offsets = [];
  CircleMarker({
    this.key,
    this.center,
    this.radius,
    this.color = const Color(0xFF00FF00),
    this.borderStrokeWidth = 0.0,
    this.borderColor = const Color(0xFFFFFF00),
  });
}

class CircleLayer extends StatelessWidget {
  final CircleLayerOptions circleOpts;
  final MapState map;
  CircleLayer(this.circleOpts, this.map);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints bc) {
        final size = Size(bc.maxWidth, bc.maxHeight);
        return _build(context, size);
      },
    );
  }

  Widget _build(BuildContext context, Size size) {
    return StreamBuilder<int>(
      stream: map.onMoved, // a Stream<int> or null
      builder: (BuildContext context, _) {
        var circleWidgets = <Widget>[];
        for (var circle in circleOpts.circles) {
          circle.offsets.clear();
          var idx = 0;
          for (int i = 0; i <= 360; i++) {
            LatLng point = LocationUtils.computeOffset(
                circle.center, circle.radius, i.toDouble());
            var offset = map.latlngToOffset(point);
            circle.offsets.add(offset);
            if (idx > 0 && idx < 360) {
              circle.offsets.add(offset);
            }
            idx++;
          }
          circleWidgets.add(
            CustomPaint(
              key: circle.key,
              size: size,
              painter: CirclePainter(circle),
            ),
          );
        }
        return Container(
          child: Stack(
            children: circleWidgets,
          ),
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
    if (circle.offsets.isEmpty) {
      return;
    }
    final rect = Offset.zero & size;
    canvas.clipRect(rect);
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = circle.color;
    final borderPaint = circle.borderStrokeWidth > 0.0
        ? (Paint()
          ..style = PaintingStyle.stroke
          ..color = circle.borderColor
          ..strokeWidth = circle.borderStrokeWidth)
        : null;
    _paintCircle(canvas, paint);
    if (circle.borderStrokeWidth > 0.0) {
      _paintLine(canvas, borderPaint);
    }
  }

  void _paintLine(Canvas canvas, Paint paint) {
    canvas.drawPoints(PointMode.lines, circle.offsets, paint);
  }

  void _paintCircle(Canvas canvas, Paint paint) {
    Path path = Path();
    path.addPolygon(circle.offsets, true);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CirclePainter other) => false;
}

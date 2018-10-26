import 'dart:math';
import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/map/map.dart';
import 'package:latlong/latlong.dart' hide Path; // conflict with Path from UI

typedef PolygonCallback(Polygon polygon, LatLng location);

class PolygonLayerOptions extends LayerOptions {
  final List<Polygon> polygons;
  final PolygonCallback onTap;
  final PolygonCallback onLongPress;

  PolygonLayerOptions({
    this.polygons = const [],
    this.onTap,
    this.onLongPress,
  });
}

class Polygon {
  final Key key;
  final List<LatLng> points;
  final List<Offset> offsets = [];
  final Color color;
  final double borderStrokeWidth;
  final Color borderColor;
  final bool closeFigure;
  final bool displayPoints;
  final double pointsWidth;

  bool get isEmpty => this.points == null || this.points.isEmpty;

  bool get isNotEmpty => this.points != null && this.points.isNotEmpty;

  Polygon({
    this.key,
    this.points,
    this.color = const Color(0xFF00FF00),
    this.borderStrokeWidth = 0.0,
    this.borderColor = const Color(0xFFFFFF00),
    this.closeFigure = false,
    this.displayPoints = false,
    this.pointsWidth = 0.0,
  });
}

class PolygonLayer extends StatelessWidget {
  final PolygonLayerOptions polygonOpts;
  final MapState map;
  final Stream<Null> stream;

  PolygonLayer(this.polygonOpts, this.map, this.stream);

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
      builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
        return Container(
          child: Stack(
            children: _buildPolygons(size),
          ),
        );
      },
    );
  }

  List<Widget> _buildPolygons(Size size) {
    var list = polygonOpts.polygons
        .where((polygon) => polygon.isNotEmpty)
        .map((polygon) => _buildPolygonWidget(polygon, size))
        .toList();
    return list;
  }

  Widget _buildPolygonWidget(Polygon polygon, Size size) {
    polygon.offsets.clear();
    if (polygon.closeFigure && polygon.points.length > 2)
      polygon.points.add(polygon.points.first);
    var i = 0;
    for (var point in polygon.points) {
      var offset = map.latlngToOffset(point);
      polygon.offsets.add(offset);
      if (i > 0 && i < polygon.points.length) {
        polygon.offsets.add(offset);
      }
      i++;
    }
    return CustomPaint(
      key: polygon.key,
      painter: PolygonPainter(polygon),
      size: size,
    );
  }
}

class PolygonPainter extends CustomPainter {
  final Polygon polygon;
  PolygonPainter(this.polygon);

  @override
  void paint(Canvas canvas, Size size) {
    if (polygon.offsets.isEmpty) {
      return;
    }
    final rect = Offset.zero & size;
    canvas.clipRect(rect);
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = polygon.color;
    final borderPaint = polygon.borderStrokeWidth > 0.0
        ? (Paint()
          ..style = PaintingStyle.stroke
          ..color = polygon.borderColor
          ..strokeWidth = polygon.borderStrokeWidth)
        : null;
    _paintPolygon(canvas, paint);
    if (polygon.borderStrokeWidth > 0.0) {
      _paintLine(canvas, borderPaint);
    }
  }

  void _paintLine(Canvas canvas, Paint paint) {
    canvas.drawPoints(PointMode.lines, polygon.offsets, paint);
    if (polygon.displayPoints && polygon.pointsWidth > 0.0) {
      for (var offset in polygon.offsets) {
        canvas.drawCircle(offset, polygon.pointsWidth, paint);
      }
    }
  }

  void _paintPolygon(Canvas canvas, Paint paint) {
    Path path = Path();
    path.addPolygon(polygon.offsets, true);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(PolygonPainter other) => false;
}

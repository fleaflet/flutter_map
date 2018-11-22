import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/layer/editable_points.dart';
import 'package:flutter_map/src/map/map.dart';
import 'package:latlong/latlong.dart' hide Path;  // conflict with Path from UI

typedef PolygonCallback(Polygon polygon, LatLng location);
typedef PolygonMovedCallback(Polygon polygon, LatLng point);
typedef PolygonChangedCallback(Polygon polygon, LatLng point);

class PolygonLayerOptions extends LayerOptions {
  final List<Polygon> polygons;
  final PolygonCallback onTap;
  final PolygonCallback onLongPress;
  final bool editable;
  final PolygonMovedCallback onMoved;
  final PolygonChangedCallback onChanged;

  PolygonLayerOptions({
    this.polygons = const [],
    this.onTap,
    this.onLongPress,
    this.editable = false,
    this.onMoved,
    this.onChanged,
    rebuild}) : super(rebuild: rebuild);
}

class Polygon {
  final List<LatLng> points;
  final List<Offset> offsets = [];
  final Color color;
  final double borderStrokeWidth;
  final Color borderColor;

  Rect _bounds = Rect.zero;

  bool get isEmpty => this.points == null || this.points.isEmpty;
  bool get isNotEmpty => this.points != null && this.points.isNotEmpty;
  Rect get bounds => this._bounds;

  Polygon({
    this.points,
    this.color = const Color(0xFF00FF00),
    this.borderStrokeWidth = 0.0,
    this.borderColor = const Color(0xFFFFFF00),
  });
}

class PolygonLayer extends StatelessWidget {
  final PolygonLayerOptions polygonOpts;
  final MapState map;
  final Stream<Null> stream;

  PolygonLayer(this.polygonOpts, this.map, this.stream);

  Widget build(BuildContext context) {
    return new LayoutBuilder(
      builder: (BuildContext context, BoxConstraints bc) {
        final size = new Size(bc.maxWidth, bc.maxHeight);
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
        .map((polygon) => polygonOpts.editable
          ? EditablePointsWidget(
            builder: (BuildContext context) =>
                _buildPolygonWidget(polygon, size),
            points: polygon.points,
            map: map,
            closed: true,
          )
          : _buildPolygonWidget(polygon, size)
        ).toList();
    return list;
  }

  Widget _buildPolygonWidget(Polygon polygon, Size size) {
    polygon.offsets.clear();
    polygon._bounds = Rect.zero;
    var i = 0;
    for (var point in polygon.points) {
      var offset = map.latlngToOffset(point);
      polygon.offsets.add(offset);
      if (i > 0 && i < polygon.points.length) {
        polygon.offsets.add(offset);
        polygon._bounds = polygon._bounds.expandToInclude(
            Rect.fromPoints(polygon.offsets[i-1], offset)
        );
      }
      i++;
    }
    return CustomPaint(
      painter: PolygonPainter(polygon),
      size: size,
    );
  }
}

class PolygonPainter extends CustomPainter {
  final Polygon polygonOpt;
  PolygonPainter(this.polygonOpt);

  @override
  void paint(Canvas canvas, Size size) {
    if (polygonOpt.offsets.isEmpty) {
      return;
    }
    final rect = Offset.zero & size;
    canvas.clipRect(rect);
    final paint = new Paint()
      ..style = PaintingStyle.fill
      ..color = polygonOpt.color;
    final borderPaint = polygonOpt.borderStrokeWidth > 0.0
        ? (new Paint()
      ..style = PaintingStyle.stroke
      ..color = polygonOpt.borderColor
      ..strokeWidth = polygonOpt.borderStrokeWidth)
        : null;

    _paintPolygon(canvas, polygonOpt.offsets, paint);

    if (polygonOpt.borderStrokeWidth > 0.0) {
        _paintPolygon(canvas, polygonOpt.offsets, borderPaint);
    }
  }

  void _paintPolygon(Canvas canvas, List<Offset> offsets, Paint paint) {
    Path path = new Path();
    path.addPolygon(offsets, true);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(PolygonPainter other) => false;
}
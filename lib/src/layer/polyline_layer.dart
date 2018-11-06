import 'dart:math';
import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/map/map.dart';
import 'package:latlong/latlong.dart';

typedef PolylineCallback(Polyline polyline, LatLng location);


class PolylineLayerOptions extends LayerOptions {
  final List<Polyline> polylines;
  final PolylineCallback onTap;
  final PolylineCallback onLongPress;
  PolylineLayerOptions({
    this.polylines = const [],
    this.onTap,
    this.onLongPress,
    rebuild}) : super(rebuild: rebuild);
}

class Polyline {
  final List<LatLng> points;
  final List<Offset> offsets = [];
  final double strokeWidth;
  final Color color;
  final double borderStrokeWidth;
  final Color borderColor;
  final bool isDotted;

  Rect _bounds = Rect.zero;

  bool get isEmpty => this.points == null || this.points.isEmpty;
  bool get isNotEmpty => this.points != null && this.points.isNotEmpty;
  Rect get bounds => this._bounds;

  Polyline({
    this.points,
    this.strokeWidth = 1.0,
    this.color = const Color(0xFF00FF00),
    this.borderStrokeWidth = 0.0,
    this.borderColor = const Color(0xFFFFFF00),
    this.isDotted = false,
  });
}

class PolylineLayer extends StatelessWidget {
  final PolylineLayerOptions polylineOpts;
  final MapState map;
  final Stream<Null> stream;

  PolylineLayer(this.polylineOpts, this.map, this.stream);

  Widget build(BuildContext context) {
    return new LayoutBuilder(
      builder: (BuildContext context, BoxConstraints bc) {
        final size = new Size(bc.maxWidth, bc.maxHeight);
        return _build(context, size);
      },
    );
  }

  Widget _build(BuildContext context, Size size) {
    return new StreamBuilder<int>(
      stream: stream, // a Stream<int> or null
      builder: (BuildContext context, _) {
        return Container(
          child: Stack(
            children: _buildPolylines(size),
          ),
        );
      },
    );
  }

  List<Widget> _buildPolylines(Size size) {
    var list = polylineOpts.polylines
        .where((polyline) => polyline.isNotEmpty)
        .map((polyline) => _buildPolylineWidget(polyline, size))
        .toList();
    return list;
  }

  Widget _buildPolylineWidget(Polyline polyline, Size size) {
    polyline.offsets.clear();
    polyline._bounds = Rect.zero;
    var i = 0;
    for (var point in polyline.points) {
      var offset = map.latlngToOffset(point);
      polyline.offsets.add(offset);
      if (i > 0 && i < polyline.points.length) {
        polyline.offsets.add(offset);
        polyline._bounds = polyline._bounds.expandToInclude(
            Rect.fromPoints(polyline.offsets[i-1], offset)
        );
      }
      i++;
    }
    return CustomPaint(
      painter: PolylinePainter(polyline),
      size: size,
    );
  }
}

class PolylinePainter extends CustomPainter {
  final Polyline polylineOpt;
  PolylinePainter(this.polylineOpt);

  @override
  void paint(Canvas canvas, Size size) {
    if (polylineOpt.offsets.isEmpty) {
      return;
    }
    final rect = Offset.zero & size;
    canvas.clipRect(rect);
    final paint = new Paint()
      ..color = polylineOpt.color
      ..strokeWidth = polylineOpt.strokeWidth;
    final borderPaint = polylineOpt.borderStrokeWidth > 0.0
        ? (new Paint()
          ..color = polylineOpt.borderColor
          ..strokeWidth =
              polylineOpt.strokeWidth + polylineOpt.borderStrokeWidth)
        : null;
    double radius = polylineOpt.strokeWidth / 2;
    double borderRadius = radius + (polylineOpt.borderStrokeWidth / 2);
    if (polylineOpt.isDotted) {
      double spacing = polylineOpt.strokeWidth * 1.5;
      if (borderPaint != null) {
        _paintDottedLine(
            canvas, polylineOpt.offsets, borderRadius, spacing, borderPaint);
      }
      _paintDottedLine(canvas, polylineOpt.offsets, radius, spacing, paint);
    } else {
      if (borderPaint != null) {
        _paintLine(canvas, polylineOpt.offsets, borderRadius, borderPaint);
      }
      _paintLine(canvas, polylineOpt.offsets, radius, paint);
    }
  }

  void _paintDottedLine(Canvas canvas, List<Offset> offsets, double radius,
      double stepLength, Paint paint) {
    double startDistance = 0.0;
    for (int i = 0; i < offsets.length - 1; i++) {
      Offset o0 = offsets[i];
      Offset o1 = offsets[i + 1];
      double totalDistance = _dist(o0, o1);
      double distance = startDistance;
      while (distance < totalDistance) {
        double f1 = distance / totalDistance;
        double f0 = 1.0 - f1;
        var offset = Offset(o0.dx * f0 + o1.dx * f1, o0.dy * f0 + o1.dy * f1);
        canvas.drawCircle(offset, radius, paint);
        distance += stepLength;
      }
      startDistance = distance < totalDistance
          ? stepLength - (totalDistance - distance)
          : distance - totalDistance;
    }
    canvas.drawCircle(polylineOpt.offsets.last, radius, paint);
  }

  void _paintLine(
      Canvas canvas, List<Offset> offsets, double radius, Paint paint) {
    canvas.drawPoints(PointMode.lines, offsets, paint);
    for (var offset in offsets) {
      canvas.drawCircle(offset, radius, paint);
    }
  }

  @override
  bool shouldRepaint(PolylinePainter other) => false;
}

double _dist(Offset v, Offset w) {
  return sqrt(_dist2(v, w));
}

double _dist2(Offset v, Offset w) {
  return _sqr(v.dx - w.dx) + _sqr(v.dy - w.dy);
}

double _sqr(double x) {
  return x * x;
}

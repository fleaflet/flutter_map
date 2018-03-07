import 'package:flutter/widgets.dart';
import 'package:latlong/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'dart:ui';


class PolylineLayerOptions extends LayerOptions {
  final List<Polyline> polylines;
  PolylineLayerOptions({this.polylines = const []});
}

class Polyline {
  final List<LatLng> points;
  List<Offset> offsets;
  final double strokeWidth;
  final Color color;
  Polyline({
    this.points,
    this.strokeWidth = 1.0,
    this.color = const Color(0xFF00FF00),
  });
}

class PolylineLayer extends StatelessWidget {
  final PolylineLayerOptions polylineOpts;
  final MapState map;
  PolylineLayer(this.polylineOpts, this.map);

  Widget build(BuildContext context) {
    return new StreamBuilder<int>(
      stream: map.onMoved, // a Stream<int> or null
      builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
        for (var polylineOpt in this.polylineOpts.polylines) {
          polylineOpt.offsets = [];
          var i = 0;
          for (var point in polylineOpt.points) {
            i++;
            var pos = map.project(point);
            pos = pos.multiplyBy(map.getZoomScale(map.zoom, map.zoom)) -
                map.getPixelOrigin();
            polylineOpt.offsets.add(new Offset(pos.x, pos.y));
            if (i != 1 && i != polylineOpt.points.length) {
              polylineOpt.offsets.add(new Offset(pos.x, pos.y));
            }
          }
        }
        var polylines = <Widget>[];
        for (var polylineOpt in this.polylineOpts.polylines) {
          polylines.add(
            new CustomPaint(
                painter: new PolylinePainter(polylineOpt),
                child: new Container(
                  child: new Text(
                      "                                                                                                   "),
                )),
          );
        }
        return new Container(
          child: new Stack(
            children: polylines,
          ),
        );
      },
    );
  }
}

class PolylinePainter extends CustomPainter {
  final Polyline polylineOpt;
  PolylinePainter(this.polylineOpt);

  @override
  void paint(Canvas canvas, Size size) {
    if (polylineOpt.offsets == null) {
      return;
    }
    final Paint paint = new Paint()..color = polylineOpt.color;
    paint.strokeWidth = polylineOpt.strokeWidth;
    canvas.drawPoints(PointMode.lines, polylineOpt.offsets, paint);
  }

  @override
  bool shouldRepaint(PolylinePainter other) => false;
}

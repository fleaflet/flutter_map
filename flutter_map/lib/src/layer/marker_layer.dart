import 'package:flutter/widgets.dart';
import 'package:flutter_map/src/map/map.dart';
import 'package:latlong/latlong.dart';
import 'package:flutter_map/flutter_map.dart';

class MarkerLayerOptions extends LayerOptions {
  final List<Marker> markers;
  MarkerLayerOptions({this.markers = const []});
}

enum MarkerAnchor {
  left,
  right,
  top,
  bottom,
  center,
}

class Marker {
  final LatLng point;
  final WidgetBuilder builder;
  final double width;
  final double height;
  final MarkerAnchor anchor;
  Marker(
      {this.point,
      this.builder,
      this.width = 30.0,
      this.height = 30.0,
      this.anchor = MarkerAnchor.center});
}

class MarkerLayer extends StatelessWidget {
  final MarkerLayerOptions markerOpts;
  final MapState map;

  MarkerLayer(this.markerOpts, this.map);

  Widget build(BuildContext context) {
    return new StreamBuilder<int>(
      stream: map.onMoved, // a Stream<int> or null
      builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
        var markers = <Widget>[];
        for (var markerOpt in this.markerOpts.markers) {
          var pos = map.project(markerOpt.point);
          pos = pos.multiplyBy(map.getZoomScale(map.zoom, map.zoom)) -
              map.getPixelOrigin();
          markers.add(
            new Positioned(
              width: markerOpt.width,
              height: markerOpt.height,
              left: (pos.x -
                      (markerOpt.width -
                          _leftOffset(markerOpt.width, markerOpt.anchor)))
                  .toDouble(),
              top: (pos.y -
                      (markerOpt.height -
                          _topOffset(markerOpt.height, markerOpt.anchor)))
                  .toDouble(),
              child: markerOpt.builder(context),
            ),
          );
        }
        return new Container(
          child: new Stack(
            children: markers,
          ),
        );
      },
    );
  }

  static double _leftOffset(double width, MarkerAnchor anchor) {
    switch (anchor) {
      case MarkerAnchor.left:
        return 0.0;
      case MarkerAnchor.right:
        return width;
      case MarkerAnchor.top:
      case MarkerAnchor.bottom:
      case MarkerAnchor.center:
      default:
        return width / 2;
    }
  }

  static double _topOffset(double height, MarkerAnchor anchor) {
    switch (anchor) {
      case MarkerAnchor.top:
        return 0.0;
      case MarkerAnchor.bottom:
        return height;
      case MarkerAnchor.left:
      case MarkerAnchor.right:
      case MarkerAnchor.center:
      default:
        return height / 2;
    }
  }
}

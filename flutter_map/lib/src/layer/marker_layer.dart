import 'package:flutter/widgets.dart';
import 'package:flutter_map/src/map/map.dart';
import 'package:latlong/latlong.dart';
import 'package:flutter_map/flutter_map.dart';

class MarkerLayerOptions extends LayerOptions {
  final List<Marker> markers;
  MarkerLayerOptions({this.markers = const []});
}

class Marker {
  final LatLng point;
  final WidgetBuilder builder;
  final double width;
  final double height;
  final List<double> anchor;
  Marker({
    this.point,
    this.builder,
    this.width = 30.0,
    this.height = 30.0,
    this.anchor = const [15.0, 15.0]
  });
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
              left: (pos.x - (markerOpt.width - markerOpt.anchor[0])).toDouble(),
              top: (pos.y - (markerOpt.height - markerOpt.anchor[1])).toDouble(),
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
}

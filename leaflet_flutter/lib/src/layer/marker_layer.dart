import 'package:flutter/widgets.dart';
import 'package:latlong/latlong.dart';
import 'package:leaflet_flutter/leaflet_flutter.dart';

class MarkerLayerOptions extends LayerOptions {
  final List<Marker> markers;
  MarkerLayerOptions({this.markers = const []});
}

class Marker {
  final LatLng point;
  final WidgetBuilder builder;
  Marker({this.point, this.builder});
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
              left: pos.x,
              top: pos.y,
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

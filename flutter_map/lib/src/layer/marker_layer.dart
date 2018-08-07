import 'package:flutter/widgets.dart';
import '../map/map.dart';
import 'package:latlong/latlong.dart';
import '../../flutter_map.dart';

class MarkerLayerOptions extends LayerOptions {
  final List<Marker> markers;
  MarkerLayerOptions({this.markers = const []});
}

class Anchor {
  final double left;
  final double top;

  Anchor(this.left, this.top);

  Anchor._(double width, double height, AnchorPos anchor)
      : left = _leftOffset(width, anchor),
        top = _topOffset(width, anchor);

  static double _leftOffset(double width, AnchorPos anchor) {
    switch (anchor) {
      case AnchorPos.left:
        return 0.0;
      case AnchorPos.right:
        return width;
      case AnchorPos.top:
      case AnchorPos.bottom:
      case AnchorPos.center:
      default:
        return width / 2;
    }
  }

  static double _topOffset(double height, AnchorPos anchor) {
    switch (anchor) {
      case AnchorPos.top:
        return 0.0;
      case AnchorPos.bottom:
        return height;
      case AnchorPos.left:
      case AnchorPos.right:
      case AnchorPos.center:
      default:
        return height / 2;
    }
  }
}

enum AnchorPos {
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
  final Anchor _anchor;

  Marker({
    this.point,
    this.builder,
    this.width = 30.0,
    this.height = 30.0,
    AnchorPos anchor,
    Anchor anchorOverride,
  }) : this._anchor = anchorOverride ?? new Anchor._(width, height, anchor);
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
          var bounds = map.getPixelBounds(map.zoom);
          var latlngBounds = new LatLngBounds(
              map.unproject(bounds.bottomLeft), map.unproject(bounds.topRight));
          pos = pos.multiplyBy(map.getZoomScale(map.zoom, map.zoom)) -
              map.getPixelOrigin();

          var pixelPosX =
              (pos.x - (markerOpt.width - markerOpt._anchor.left)).toDouble();
          var pixelPosY =
              (pos.y - (markerOpt.height - markerOpt._anchor.top)).toDouble();

          if (!latlngBounds.contains(markerOpt.point)) {
            continue;
          }

          markers.add(
            new Positioned(
              width: markerOpt.width,
              height: markerOpt.height,
              left: pixelPosX,
              top: pixelPosY,
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

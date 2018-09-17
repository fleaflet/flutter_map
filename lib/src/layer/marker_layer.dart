import 'package:flutter/widgets.dart';
import 'package:flutter_map/src/map/map.dart';
import 'package:latlong/latlong.dart';
import 'package:flutter_map/flutter_map.dart';

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
        return new Container(
          child: new Stack(
            children: _buildMarkers(context),
          ),
        );
      },
    );
  }

  List<Widget> _buildMarkers(BuildContext context) {
    return markerOpts.markers
        .where((it) => map.bounds.contains(it.point))
        .map((it) => _buildMarkerWidget(context, it))
        .toList();
  }

  Widget _buildMarkerWidget(BuildContext context, Marker markerOpt) {
    final markerPos = _calcMarkerPosition(markerOpt);
    return Positioned(
      width: markerOpt.width,
      height: markerOpt.height,
      left: markerPos.x,
      top: markerPos.y,
      child: markerOpt.builder(context),
    );
  }

  Point _calcMarkerPosition(Marker markerOpt) {
    var scale = map.getZoomScale(map.zoom, map.zoom);
    var pos =
        map.project(markerOpt.point).multiplyBy(scale) - map.getPixelOrigin();
    var pixelPosX =
        (pos.x - (markerOpt.width - markerOpt._anchor.left)).toDouble();
    var pixelPosY =
        (pos.y - (markerOpt.height - markerOpt._anchor.top)).toDouble();
    return Point(pixelPosX, pixelPosY);
  }
}

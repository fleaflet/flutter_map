import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/map/map.dart';
import 'package:latlong/latlong.dart';

typedef void MarkerTapCallback(Marker marker);

class MarkerLayerOptions extends LayerOptions {
  final List<Marker> markers;
  final MarkerTapCallback onTap;
  MarkerLayerOptions({this.markers = const [], this.onTap, rebuild})
      : super(rebuild: rebuild);
}

class Anchor {
  final double left;
  final double top;

  Anchor(this.left, this.top);

  Anchor._(double width, double height, AnchorAlign alignOpt)
      : left = _leftOffset(width, alignOpt),
        top = _topOffset(width, alignOpt);

  static double _leftOffset(double width, AnchorAlign alignOpt) {
    switch (alignOpt) {
      case AnchorAlign.left:
        return 0.0;
      case AnchorAlign.right:
        return width;
      case AnchorAlign.top:
      case AnchorAlign.bottom:
      case AnchorAlign.center:
      default:
        return width / 2;
    }
  }

  static double _topOffset(double height, AnchorAlign alignOpt) {
    switch (alignOpt) {
      case AnchorAlign.top:
        return 0.0;
      case AnchorAlign.bottom:
        return height;
      case AnchorAlign.left:
      case AnchorAlign.right:
      case AnchorAlign.center:
      default:
        return height / 2;
    }
  }

  factory Anchor._forPos(AnchorPos pos, double width, double height) {
    if (pos == null) return Anchor._(width, height, null);
    if (pos.value is AnchorAlign) return Anchor._(width, height, pos.value);
    if (pos.value is Anchor) return pos.value;
    throw Exception('Unsupported AnchorPos value type: ${pos.runtimeType}.');
  }
}

class AnchorPos<T> {
  AnchorPos._(this.value);
  T value;
  static AnchorPos exactly(Anchor anchor) => AnchorPos._(anchor);
  static AnchorPos align(AnchorAlign alignOpt) => AnchorPos._(alignOpt);
}

enum AnchorAlign {
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
  final Anchor anchor;

  Marker({
    this.point,
    this.builder,
    this.width = 30.0,
    this.height = 30.0,
    AnchorPos anchorPos,
  }) : this.anchor = Anchor._forPos(anchorPos, width, height);
}

class MarkerLayer extends StatelessWidget {
  final MarkerLayerOptions markerOpts;
  final MapState map;
  final Stream<Null> stream;

  MarkerLayer(this.markerOpts, this.map, this.stream);

  Widget build(BuildContext context) {
    return new StreamBuilder<int>(
      stream: stream, // a Stream<int> or null
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
    final markerWidget = markerOpts.onTap == null
        ? markerOpt.builder(context)
        : GestureDetector(
            onTap: () => markerOpts.onTap(markerOpt),
            child: markerOpt.builder(context),
          );
    return Positioned(
      width: markerOpt.width,
      height: markerOpt.height,
      left: markerPos.x,
      top: markerPos.y,
      child: markerWidget,
    );
  }

  Point _calcMarkerPosition(Marker markerOpt) {
    var scale = map.getZoomScale(map.zoom, map.zoom);
    var pos =
        map.project(markerOpt.point).multiplyBy(scale) - map.getPixelOrigin();
    var pixelPosX =
        (pos.x - (markerOpt.width - markerOpt.anchor.left)).toDouble();
    var pixelPosY =
        (pos.y - (markerOpt.height - markerOpt.anchor.top)).toDouble();
    return Point(pixelPosX, pixelPosY);
  }
}

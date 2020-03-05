import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/core/bounds.dart';
import 'package:flutter_map/src/map/map.dart';
import 'package:latlong/latlong.dart';

class Anchor {
  final double left;
  final double top;

  Anchor(this.left, this.top);

  Anchor._(double width, double height, AnchorAlign alignOpt)
      : left = _leftOffset(width, alignOpt),
        top = _topOffset(height, alignOpt);

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

  factory Anchor.forPos(AnchorPos pos, double width, double height) {
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
  }) : anchor = Anchor.forPos(anchorPos, width, height);
}

class MarkerLayerWidget extends StatelessWidget {
  final List<Marker> markers;

  MarkerLayerWidget({
    Key key,
    @required this.markers,
  }) : super(key: key);

  bool _boundsContainsMarker(MapState mapState, Marker marker) {
    var pixelPoint = mapState.project(marker.point);

    final width = marker.width - marker.anchor.left;
    final height = marker.height - marker.anchor.top;

    var sw = CustomPoint(pixelPoint.x + width, pixelPoint.y - height);
    var ne = CustomPoint(pixelPoint.x - width, pixelPoint.y + height);
    return mapState.pixelBounds.containsPartialBounds(Bounds(sw, ne));
  }

  @override
  Widget build(BuildContext context) {
    final mapState = MapStateInheritedWidget.of(context).mapState;
    final children = <Widget>[];

    for (var marker in markers) {
      var pos = mapState.project(marker.point);
      pos = pos.multiplyBy(mapState.getZoomScale(
            mapState.zoom,
            mapState.zoom,
          )) -
          mapState.getPixelOrigin();

      var pixelPosX = (pos.x - (marker.width - marker.anchor.left)).toDouble();
      var pixelPosY = (pos.y - (marker.height - marker.anchor.top)).toDouble();

      if (!_boundsContainsMarker(mapState, marker)) {
        continue;
      }

      children.add(
        Positioned(
          width: marker.width,
          height: marker.height,
          left: pixelPosX,
          top: pixelPosY,
          child: marker.builder(context),
        ),
      );
    }

    return Container(
      child: Stack(
        children: children,
      ),
    );
  }
}

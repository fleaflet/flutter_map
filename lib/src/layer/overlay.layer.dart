import 'dart:ui';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/map/map.dart';

class OverlayImage {
  final LatLngBounds bounds;
  final ImageProvider imageProvider;
  final double opacity;
  final bool gaplessPlayback;

  OverlayImage({
    this.bounds,
    this.imageProvider,
    this.opacity = 1.0,
    this.gaplessPlayback = false,
  });
}

class OverlayImageLayerWidget extends StatelessWidget {
  final List<OverlayImage> images;

  OverlayImageLayerWidget({ this.images = const [] });

  @override
  Widget build(BuildContext context) {
    var mapState = MapStateInheritedWidget.of(context).mapState;

    return ClipRect(
      child: Stack(
        children: <Widget>[
          for (var overlayImage in images)
            _positionedForOverlay(overlayImage, mapState),
        ],
      ),
    );
  }

  Positioned _positionedForOverlay(OverlayImage overlayImage, MapState map) {
    final zoomScale =
        map.getZoomScale(map.zoom, map.zoom); // TODO replace with 1?
    final pixelOrigin = map.getPixelOrigin();
    final upperLeftPixel =
        map.project(overlayImage.bounds.northWest).multiplyBy(zoomScale) -
            pixelOrigin;
    final bottomRightPixel =
        map.project(overlayImage.bounds.southEast).multiplyBy(zoomScale) -
            pixelOrigin;
    return Positioned(
      left: upperLeftPixel.x.toDouble(),
      top: upperLeftPixel.y.toDouble(),
      width: (bottomRightPixel.x - upperLeftPixel.x).toDouble(),
      height: (bottomRightPixel.y - upperLeftPixel.y).toDouble(),
      child: Image(
        image: overlayImage.imageProvider,
        fit: BoxFit.fill,
        color: Color.fromRGBO(255, 255, 255, overlayImage.opacity),
        colorBlendMode: BlendMode.modulate,
        gaplessPlayback: overlayImage.gaplessPlayback,
      ),
    );
  }
}

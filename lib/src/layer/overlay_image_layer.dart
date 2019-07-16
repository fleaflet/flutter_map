import 'dart:async';
import 'dart:ui';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart' as img;
import 'package:flutter/services.dart' as img;
import 'package:flutter/widgets.dart' as img;
import 'package:flutter/painting.dart' as img;

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/map/map.dart';

class OverlayImageLayerOptions extends LayerOptions {
  final List<OverlayImage> overlayImages;
  OverlayImageLayerOptions({this.overlayImages = const [], rebuild})
      : super(rebuild: rebuild);
}

class OverlayImage {
  final LatLngBounds bounds;
  final img.ImageProvider imageProvider;
  final double opacity;

  OverlayImage({
    this.bounds,
    this.imageProvider,
    this.opacity = 1.0,
  });
}

class OverlayImageLayer extends StatelessWidget {
  final OverlayImageLayerOptions overlayImageOpts;
  final MapState map;
  final Stream<Null> stream;

  OverlayImageLayer(this.overlayImageOpts, this.map, this.stream);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: stream, // a Stream<int> or null
      builder: (BuildContext context, _) {
        final zoomScale = map.getZoomScale(map.zoom, map.zoom);
        final origin = map.getPixelOrigin();
        return ClipRect(
          child: Stack(
            children: <Widget>[
              for (var overlayImage in overlayImageOpts.overlayImages)
                Builder(
                  builder: (BuildContext context) {
                    final upperLeftPixel = map
                            .project(overlayImage.bounds.northWest)
                            .multiplyBy(zoomScale) -
                        origin;
                    final bottomRightPixel = map
                            .project(overlayImage.bounds.southEast)
                            .multiplyBy(zoomScale) -
                        origin;
                    return Positioned(
                      left: upperLeftPixel.x.toDouble(),
                      top: upperLeftPixel.y.toDouble(),
                      width: (bottomRightPixel.x - upperLeftPixel.x).toDouble(),
                      height:
                          (bottomRightPixel.y - upperLeftPixel.y).toDouble(),
                      child: Image(
                        image: overlayImage.imageProvider,
                        fit: img.BoxFit.fill,
                        color:Color.fromRGBO(255, 255, 255, overlayImage.opacity),
                        colorBlendMode: img.BlendMode.dstATop,
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

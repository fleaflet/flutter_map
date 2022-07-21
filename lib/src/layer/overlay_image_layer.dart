import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/map/map.dart';
import 'package:flutter_map/src/core/bounds.dart';
import 'package:latlong2/latlong.dart';

class OverlayImageLayerOptions extends LayerOptions {
  final List<OverlayImage> overlayImages;

  OverlayImageLayerOptions({
    Key? key,
    this.overlayImages = const [],
    Stream<void>? rebuild,
  }) : super(key: key, rebuild: rebuild);
}

class OverlayImage {
  final LatLngBounds bounds;
  final ImageProvider imageProvider;
  final double opacity;
  final bool gaplessPlayback;

  /// A third lat/lng point to span a rotated/skewed bounding box.
  /// This defines the bottom left corner of the image.
  ///
  /// The image is transformed so that its corners touch the following points:
  /// - top-left and bottom-right: the points from [bounds]
  /// - bottom-left: the [rotationPoint]
  /// - top-right: derived from the other points
  final LatLng? rotationPoint;

  /// The filter quality when rotating the image.
  final FilterQuality? filterQuality;

  OverlayImage(
      {required this.bounds,
      required this.imageProvider,
      this.opacity = 1.0,
      this.gaplessPlayback = false,
      this.rotationPoint,
      this.filterQuality = FilterQuality.medium});
}

class OverlayImageLayerWidget extends StatelessWidget {
  final OverlayImageLayerOptions options;

  const OverlayImageLayerWidget({Key? key, required this.options})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final mapState = MapState.maybeOf(context)!;
    return OverlayImageLayer(options, mapState, mapState.onMoved);
  }
}

class OverlayImageLayer extends StatelessWidget {
  final OverlayImageLayerOptions overlayImageOpts;
  final MapState map;
  final Stream<void>? stream;

  OverlayImageLayer(this.overlayImageOpts, this.map, this.stream)
      : super(key: overlayImageOpts.key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<void>(
      stream: stream,
      builder: (BuildContext context, _) {
        return ClipRect(
          child: Stack(
            children: <Widget>[
              for (var overlayImage in overlayImageOpts.overlayImages)
                _positionedForOverlay(overlayImage),
            ],
          ),
        );
      },
    );
  }

  Positioned _positionedForOverlay(OverlayImage overlayImage) {
    final pixelOrigin = map.getPixelOrigin();
    // northWest is not necessarily upperLeft depending on projection
    var bounds = Bounds<num>(
      map.project(overlayImage.bounds.northWest) - pixelOrigin,
      map.project(overlayImage.bounds.southEast) - pixelOrigin,
    );

    Widget child = Image(
      image: overlayImage.imageProvider,
      fit: BoxFit.fill,
      color: Color.fromRGBO(255, 255, 255, overlayImage.opacity),
      colorBlendMode: BlendMode.modulate,
      gaplessPlayback: overlayImage.gaplessPlayback,
    );

    if (overlayImage.rotationPoint != null) {
      final pxTopLeft = bounds.topLeft;
      final pxBottomRight = bounds.bottomRight;
      final pxBottomLeft =
          map.project(overlayImage.rotationPoint!) - pixelOrigin;
      // calculate pixel coordinate of top-right corner by calculating the
      // vector from bottom-left to top-left and adding it to bottom-right
      final pxTopRight = pxTopLeft - pxBottomLeft + pxBottomRight;

      // update/enlarge bounds so the new corner points fit within
      bounds = bounds.extend(pxTopRight).extend(pxBottomLeft);

      final vectorX = (pxTopRight - pxTopLeft) / bounds.size.x;
      final vectorY = (pxBottomLeft - pxTopLeft) / bounds.size.y;
      final offset = pxTopLeft - bounds.topLeft;

      final a = vectorX.x.toDouble();
      final b = vectorX.y.toDouble();
      final c = vectorY.x.toDouble();
      final d = vectorY.y.toDouble();
      final tx = offset.x.toDouble();
      final ty = offset.y.toDouble();

      child = Transform(
        transform: Matrix4(a, b, 0, 0, c, d, 0, 0, 0, 0, 1, 0, tx, ty, 0, 1),
        filterQuality: overlayImage.filterQuality,
        child: child,
      );
    }

    return Positioned(
        left: bounds.topLeft.x.toDouble(),
        top: bounds.topLeft.y.toDouble(),
        width: bounds.size.x.toDouble(),
        height: bounds.size.y.toDouble(),
        child: child);
  }
}

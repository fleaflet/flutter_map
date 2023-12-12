import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/src/geo/latlng_bounds.dart';
import 'package:flutter_map/src/layer/general/mobile_layer_transformer.dart';
import 'package:flutter_map/src/map/camera/camera.dart';
import 'package:flutter_map/src/misc/bounds.dart';
import 'package:flutter_map/src/misc/extensions.dart';
import 'package:latlong2/latlong.dart';

/// Base class for all overlay images.
@immutable
sealed class BaseOverlayImage extends StatelessWidget {
  final ImageProvider imageProvider;
  final double opacity;
  final bool gaplessPlayback;

  const BaseOverlayImage({
    super.key,
    required this.imageProvider,
    this.opacity = 1,
    this.gaplessPlayback = false,
  });

  Widget _render(
    BuildContext context, {
    required Image child,
    required MapCamera camera,
  });

  @override
  @nonVirtual
  Widget build(BuildContext context) => _render(
        context,
        child: Image(
          image: imageProvider,
          fit: BoxFit.fill,
          color: Color.fromRGBO(255, 255, 255, opacity),
          colorBlendMode: BlendMode.modulate,
          gaplessPlayback: gaplessPlayback,
        ),
        camera: MapCamera.of(context),
      );
}

/// Unrotated overlay image that spans between a given bounding box.
///
/// The shortest side of the image will be placed along the shortest side of the
/// bounding box to minimize distortion.
@immutable
class OverlayImage extends BaseOverlayImage {
  final LatLngBounds bounds;

  const OverlayImage({
    super.key,
    required super.imageProvider,
    required this.bounds,
    super.opacity,
    super.gaplessPlayback,
  });

  @override
  Widget _render(
    BuildContext context, {
    required Image child,
    required MapCamera camera,
  }) {
    // northWest is not necessarily upperLeft depending on projection
    final bounds = Bounds<double>(
      camera.project(this.bounds.northWest) - camera.pixelOrigin,
      camera.project(this.bounds.southEast) - camera.pixelOrigin,
    );

    return Positioned(
      left: bounds.topLeft.x,
      top: bounds.topLeft.y,
      width: bounds.size.x,
      height: bounds.size.y,
      child: child,
    );
  }
}

/// Spans an image across three corner points.
///
/// Therefore this layer can be used to rotate or skew an image on the map.
///
/// The image is transformed so that its corners touch the [topLeftCorner],
/// [bottomLeftCorner] and [bottomRightCorner] points while the top-right
/// corner point is derived from the other points.
@immutable
class RotatedOverlayImage extends BaseOverlayImage {
  final LatLng topLeftCorner;
  final LatLng bottomLeftCorner;
  final LatLng bottomRightCorner;
  final FilterQuality? filterQuality;

  const RotatedOverlayImage({
    super.key,
    required super.imageProvider,
    required this.topLeftCorner,
    required this.bottomLeftCorner,
    required this.bottomRightCorner,
    this.filterQuality = FilterQuality.medium,
    super.opacity,
    super.gaplessPlayback,
  });

  @override
  Widget _render(
    BuildContext context, {
    required Image child,
    required MapCamera camera,
  }) {
    final pxTopLeft = camera.project(topLeftCorner) - camera.pixelOrigin;
    final pxBottomRight =
        camera.project(bottomRightCorner) - camera.pixelOrigin;
    final pxBottomLeft = camera.project(bottomLeftCorner) - camera.pixelOrigin;

    /// calculate pixel coordinate of top-right corner by calculating the
    /// vector from bottom-left to top-left and adding it to bottom-right
    final pxTopRight = pxTopLeft - pxBottomLeft + pxBottomRight;

    /// update/enlarge bounds so the new corner points fit within
    final bounds = Bounds<double>(pxTopLeft, pxBottomRight)
        .extend(pxTopRight)
        .extend(pxBottomLeft);

    final vectorX = (pxTopRight - pxTopLeft) / bounds.size.x;
    final vectorY = (pxBottomLeft - pxTopLeft) / bounds.size.y;
    final offset = pxTopLeft - bounds.topLeft;

    final a = vectorX.x;
    final b = vectorX.y;
    final c = vectorY.x;
    final d = vectorY.y;
    final tx = offset.x;
    final ty = offset.y;

    return Positioned(
      left: bounds.topLeft.x,
      top: bounds.topLeft.y,
      width: bounds.size.x,
      height: bounds.size.y,
      child: Transform(
        transform: Matrix4(a, b, 0, 0, c, d, 0, 0, 0, 0, 1, 0, tx, ty, 0, 1),
        filterQuality: filterQuality,
        child: child,
      ),
    );
  }
}

@immutable
class OverlayImageLayer extends StatelessWidget {
  final List<BaseOverlayImage> overlayImages;

  const OverlayImageLayer({super.key, required this.overlayImages});

  @override
  Widget build(BuildContext context) => MobileLayerTransformer(
        child: ClipRect(child: Stack(children: overlayImages)),
      );
}

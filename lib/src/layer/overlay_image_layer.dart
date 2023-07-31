import 'package:flutter/widgets.dart';
import 'package:flutter_map/src/geo/latlng_bounds.dart';
import 'package:flutter_map/src/map/camera/camera.dart';
import 'package:flutter_map/src/misc/point_extensions.dart';
import 'package:flutter_map/src/misc/private/bounds.dart';
import 'package:latlong2/latlong.dart';

/// Base class for all overlay images.
@immutable
abstract class BaseOverlayImage {
  ImageProvider get imageProvider;

  double get opacity;

  bool get gaplessPlayback;

  Positioned buildPositionedForOverlay(MapCamera map);

  Image buildImageForOverlay() {
    return Image(
      image: imageProvider,
      fit: BoxFit.fill,
      color: Color.fromRGBO(255, 255, 255, opacity),
      colorBlendMode: BlendMode.modulate,
      gaplessPlayback: gaplessPlayback,
    );
  }
}

/// Unrotated overlay image that spans between a given bounding box.
///
/// The shortest side of the image will be placed along the shortest side of the
/// bounding box to minimize distortion.
@immutable
class OverlayImage extends BaseOverlayImage {
  final LatLngBounds bounds;
  @override
  final ImageProvider imageProvider;
  @override
  final double opacity;
  @override
  final bool gaplessPlayback;

  OverlayImage(
      {required this.bounds,
      required this.imageProvider,
      this.opacity = 1.0,
      this.gaplessPlayback = false});

  @override
  Positioned buildPositionedForOverlay(MapCamera map) {
    // northWest is not necessarily upperLeft depending on projection
    final bounds = Bounds<num>(
      map.project(this.bounds.northWest).subtract(map.pixelOrigin),
      map.project(this.bounds.southEast).subtract(map.pixelOrigin),
    );
    return Positioned(
        left: bounds.topLeft.x.toDouble(),
        top: bounds.topLeft.y.toDouble(),
        width: bounds.size.x.toDouble(),
        height: bounds.size.y.toDouble(),
        child: buildImageForOverlay());
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
  @override
  final ImageProvider imageProvider;

  final LatLng topLeftCorner;
  final LatLng bottomLeftCorner;
  final LatLng bottomRightCorner;

  @override
  final double opacity;

  @override
  final bool gaplessPlayback;

  /// The filter quality when rotating the image.
  final FilterQuality? filterQuality;

  RotatedOverlayImage(
      {required this.imageProvider,
      required this.topLeftCorner,
      required this.bottomLeftCorner,
      required this.bottomRightCorner,
      this.opacity = 1.0,
      this.gaplessPlayback = false,
      this.filterQuality = FilterQuality.medium});

  @override
  Positioned buildPositionedForOverlay(MapCamera map) {
    final pxTopLeft = map.project(topLeftCorner).subtract(map.pixelOrigin);
    final pxBottomRight =
        map.project(bottomRightCorner).subtract(map.pixelOrigin);
    final pxBottomLeft =
        map.project(bottomLeftCorner).subtract(map.pixelOrigin);

    /// calculate pixel coordinate of top-right corner by calculating the
    /// vector from bottom-left to top-left and adding it to bottom-right
    final pxTopRight = pxTopLeft - pxBottomLeft + pxBottomRight;

    /// update/enlarge bounds so the new corner points fit within
    final bounds = Bounds<num>(pxTopLeft, pxBottomRight)
        .extend(pxTopRight)
        .extend(pxBottomLeft);

    final vectorX = (pxTopRight - pxTopLeft) / bounds.size.x;
    final vectorY = (pxBottomLeft - pxTopLeft) / bounds.size.y;
    final offset = pxTopLeft.subtract(bounds.topLeft);

    final a = vectorX.x;
    final b = vectorX.y;
    final c = vectorY.x;
    final d = vectorY.y;
    final tx = offset.x;
    final ty = offset.y;

    return Positioned(
        left: bounds.topLeft.x.toDouble(),
        top: bounds.topLeft.y.toDouble(),
        width: bounds.size.x.toDouble(),
        height: bounds.size.y.toDouble(),
        child: Transform(
            transform:
                Matrix4(a, b, 0, 0, c, d, 0, 0, 0, 0, 1, 0, tx, ty, 0, 1),
            filterQuality: filterQuality,
            child: buildImageForOverlay()));
  }
}

@immutable
class OverlayImageLayer extends StatelessWidget {
  final List<BaseOverlayImage> overlayImages;

  const OverlayImageLayer({super.key, this.overlayImages = const []});

  @override
  Widget build(BuildContext context) {
    final map = MapCamera.of(context);
    return ClipRect(
      child: Stack(
        children: <Widget>[
          for (var overlayImage in overlayImages)
            overlayImage.buildPositionedForOverlay(map),
        ],
      ),
    );
  }
}

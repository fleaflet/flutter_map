part of 'overlay_image_layer.dart';

/// Display an [Image] on the map at a specific coordinate location, within an
/// [OverlayImageLayer]
///
/// Implemented by [OverlayImage] & [RotatedOverlayImage].
@immutable
abstract class BaseOverlayImage extends StatelessWidget {
  /// The [ImageProvider] to use within the [Image] widget.
  final ImageProvider imageProvider;

  /// The opacity in which the image should get rendered on the map.
  final double opacity;

  /// Whether to continue showing the old image (true), or briefly show nothing
  /// (false), when the image provider changes. The default value is false.
  final bool gaplessPlayback;

  /// The [FilterQuality] of the image, used to define how high quality the
  /// overlay image should have on the map.
  final FilterQuality filterQuality;

  /// Display an [Image] on the map at a specific coordinate location
  const BaseOverlayImage({
    super.key,
    required this.imageProvider,
    this.opacity = 1,
    this.gaplessPlayback = false,
    this.filterQuality = FilterQuality.medium,
  });

  /// Given the [child] image to display, return the layout (ie. position &
  /// transformation) of the child
  ///
  /// Use [MapCamera.of] to retrieve the ambient [MapCamera] useful for layout.
  ///
  /// If more control over the [Image] itself is required, prefer subclassing
  /// one of the existing subclasses and overriding [build].
  @protected
  Widget layout(
    BuildContext context, {
    required Image child,
  });

  @override
  Widget build(BuildContext context) => layout(
        context,
        child: Image(
          image: imageProvider,
          fit: BoxFit.fill,
          opacity: AlwaysStoppedAnimation(opacity),
          gaplessPlayback: gaplessPlayback,
          filterQuality: filterQuality,
        ),
      );
}

/// Unrotated overlay image that spans between a given bounding box.
///
/// The shortest side of the image will be placed along the shortest side of the
/// bounding box to minimize distortion.
@immutable
class OverlayImage extends BaseOverlayImage {
  /// The latitude / longitude corners of the image.
  final LatLngBounds bounds;

  /// Create a new [OverlayImage] used for the [OverlayImageLayer].
  const OverlayImage({
    super.key,
    required super.imageProvider,
    required this.bounds,
    super.opacity,
    super.gaplessPlayback,
    super.filterQuality,
  });

  @override
  Widget layout(
    BuildContext context, {
    required Image child,
  }) {
    final camera = MapCamera.of(context);
    

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
  /// The coordinates of the top left corner of the image.
  final LatLng topLeftCorner;

  /// The coordinates of the bottom left corner of the image.
  final LatLng bottomLeftCorner;

  /// The coordinates of the bottom right corner of the image.
  final LatLng bottomRightCorner;

  /// Create a new [RotatedOverlayImage] instance that can be provided to the
  /// [OverlayImageLayer].
  const RotatedOverlayImage({
    super.key,
    required super.imageProvider,
    required this.topLeftCorner,
    required this.bottomLeftCorner,
    required this.bottomRightCorner,
    super.filterQuality,
    super.opacity,
    super.gaplessPlayback,
  });

  @override
  Widget layout(
    BuildContext context, {
    required Image child,
  }) {
    final camera = MapCamera.of(context);

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

    final a = vectorX.dx;
    final b = vectorX.dy;
    final c = vectorY.dx;
    final d = vectorY.dy;
    final tx = offset.dx;
    final ty = offset.dy;

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

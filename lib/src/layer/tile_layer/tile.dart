import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';

/// The widget for a single tile used for the [TileLayer].
@immutable
class Tile extends StatefulWidget {
  /// [TileImage] is the model class that contains meta data for the Tile image.
  final TileImage tileImage;

  /// The [TileBuilder] is a reference to the [TileLayer]'s
  /// [TileLayer.tileBuilder].
  final TileBuilder? tileBuilder;

  /// The tile size for the given scale of the map.
  final double scaledTileDimension;

  /// Reference to the offset of the top-left corner of the bounding rectangle
  /// of the [MapCamera]. The origin will not equal the offset of the top-left
  /// visible pixel when the map is rotated.
  final Offset currentPixelOrigin;

  /// Position Coordinates.
  ///
  /// Most of the time, they are the same as in [tileImage].
  /// Except for multi-world or scrolled maps, for instance, scrolling from
  /// Europe to Alaska on zoom level 3 (i.e. tile coordinates between 0 and 7):
  /// * Alaska is first considered as from the next world (tile X: 8)
  /// * Scrolling again, Alaska is considered as part of the current world, as
  /// the center of the map is now in America (tile X: 0)
  /// In both cases, we reuse the same [tileImage] (tile X: 0) for different
  /// [positionCoordinates] (tile X: 0 and 8). This prevents a "flash" effect
  /// when scrolling beyond the end of the world: we skip the part where we
  /// create a new tileImage (for tile X: 0) as we've already downloaded it
  /// (for tile X: 8).
  final TileCoordinates positionCoordinates;

  /// Creates a new instance of [Tile].
  const Tile({
    super.key,
    required this.scaledTileDimension,
    required this.currentPixelOrigin,
    required this.tileImage,
    required this.tileBuilder,
    required this.positionCoordinates,
  });

  @override
  State<Tile> createState() => _TileState();
}

class _TileState extends State<Tile> {
  late final String tileKey;

  @override
  void initState() {
    super.initState();
    tileKey = '${widget.positionCoordinates}:${widget.tileImage.coordinates}';
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Used to prevent unnecessary rebuilds
  @override
  void didUpdateWidget(Tile oldWidget) {
    super.didUpdateWidget(oldWidget);
    // We only care about position changes for rebuilds, not image content changes
    // as those are handled by the TileImageWidget
    if (oldWidget.currentPixelOrigin != widget.currentPixelOrigin ||
        oldWidget.scaledTileDimension != widget.scaledTileDimension) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final tileImageWidget = RepaintBoundary(
      child: TileImageWidget(
        key: ValueKey(widget.tileImage.coordinates.toString()),
        tileImage: widget.tileImage,
      ),
    );

    return Positioned(
      left: widget.positionCoordinates.x * widget.scaledTileDimension -
          widget.currentPixelOrigin.dx,
      top: widget.positionCoordinates.y * widget.scaledTileDimension -
          widget.currentPixelOrigin.dy,
      width: widget.scaledTileDimension,
      height: widget.scaledTileDimension,
      child: widget.tileBuilder
              ?.call(context, tileImageWidget, widget.tileImage) ??
          tileImageWidget,
    );
  }
}

/// A widget that displays a tile image.
///
/// This widget is separated from the [Tile] class to prevent unnecessary rebuilds.
@immutable
class TileImageWidget extends StatefulWidget {
  /// The tile image data.
  final TileImage tileImage;

  /// Creates a new instance of [TileImageWidget].
  const TileImageWidget({
    super.key,
    required this.tileImage,
  });

  @override
  State<TileImageWidget> createState() => _TileImageWidgetState();
}

class _TileImageWidgetState extends State<TileImageWidget> {
  @override
  void initState() {
    super.initState();
    widget.tileImage.addListener(_onTileImageChange);
  }

  @override
  void dispose() {
    widget.tileImage.removeListener(_onTileImageChange);
    super.dispose();
  }

  void _onTileImageChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tileImage.loadError && widget.tileImage.errorImage != null) {
      return Image(
        image: widget.tileImage.errorImage!,
        opacity: widget.tileImage.opacity == 1
            ? null
            : AlwaysStoppedAnimation(widget.tileImage.opacity),
      );
    } else if (widget.tileImage.animation == null) {
      return RawImage(
        image: widget.tileImage.imageInfo?.image,
        fit: BoxFit.fill,
        opacity: widget.tileImage.opacity == 1
            ? null
            : AlwaysStoppedAnimation(widget.tileImage.opacity),
      );
    } else {
      return AnimatedBuilder(
        animation: widget.tileImage.animation!,
        builder: (context, child) => RawImage(
          image: widget.tileImage.imageInfo?.image,
          fit: BoxFit.fill,
          opacity: widget.tileImage.animation,
        ),
      );
    }
  }
}

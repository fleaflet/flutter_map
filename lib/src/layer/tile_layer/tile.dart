import 'dart:math';

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
  final double scaledTileSize;

  /// Reference to the offset of the top-left corner of the bounding rectangle
  /// of the [MapCamera]. The origin will not equal the offset of the top-left
  /// visible pixel when the map is rotated.
  final Point<double> currentPixelOrigin;

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
    required this.scaledTileSize,
    required this.currentPixelOrigin,
    required this.tileImage,
    required this.tileBuilder,
    required this.positionCoordinates,
  });

  @override
  State<Tile> createState() => _TileState();
}

class _TileState extends State<Tile> {
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
    return Positioned(
      left: widget.positionCoordinates.x * widget.scaledTileSize -
          widget.currentPixelOrigin.x,
      top: widget.positionCoordinates.y * widget.scaledTileSize -
          widget.currentPixelOrigin.y,
      width: widget.scaledTileSize,
      height: widget.scaledTileSize,
      child: widget.tileBuilder?.call(context, _tileImage, widget.tileImage) ??
          _tileImage,
    );
  }

  Widget get _tileImage {
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

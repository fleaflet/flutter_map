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

  /// Creates a new instance of [Tile].
  const Tile({
    super.key,
    required this.scaledTileSize,
    required this.currentPixelOrigin,
    required this.tileImage,
    required this.tileBuilder,
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
      left: widget.tileImage.coordinates.x * widget.scaledTileSize -
          widget.currentPixelOrigin.x,
      top: widget.tileImage.coordinates.y * widget.scaledTileSize -
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

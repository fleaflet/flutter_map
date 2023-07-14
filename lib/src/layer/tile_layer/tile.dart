import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_builder.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_image.dart';

@immutable
class Tile extends StatefulWidget {
  final TileImage tileImage;
  final TileBuilder? tileBuilder;
  final double scaledTileSize;
  final Point<double> currentPixelOrigin;

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
    if (widget.tileImage.animation == null) {
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

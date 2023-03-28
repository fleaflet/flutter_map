import 'package:flutter/widgets.dart';
import 'package:flutter_map/src/core/point.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_builder.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_image.dart';

class Tile extends StatefulWidget {
  final TileImage tileImage;
  final CustomPoint<double> currentPixelOrigin;
  final double scaledTileSize;
  final TileBuilder? tileBuilder;

  const Tile({
    super.key,
    required this.tileImage,
    required this.currentPixelOrigin,
    required this.scaledTileSize,
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
      left: widget.tileImage.coordinate.x * widget.scaledTileSize -
          widget.currentPixelOrigin.x,
      top: widget.tileImage.coordinate.y * widget.scaledTileSize -
          widget.currentPixelOrigin.y,
      width: widget.scaledTileSize,
      height: widget.scaledTileSize,
      child: widget.tileBuilder?.call(context, _tileImage, widget.tileImage) ??
          _tileImage,
    );
  }

  Widget get _tileImage {
    if (widget.tileImage.loadError && widget.tileImage.errorImage != null) {
      return Image(image: widget.tileImage.errorImage!);
    } else if (widget.tileImage.animationController == null) {
      return RawImage(
        image: widget.tileImage.imageInfo?.image,
        fit: BoxFit.fill,
      );
    } else {
      return AnimatedBuilder(
        animation: widget.tileImage.animationController!,
        builder: (context, child) => RawImage(
          image: widget.tileImage.imageInfo?.image,
          fit: BoxFit.fill,
          opacity: widget.tileImage.animationController!,
        ),
      );
    }
  }
}

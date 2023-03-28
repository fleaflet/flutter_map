import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';

class AnimatedTile extends StatelessWidget {
  final Tile tile;
  final CustomPoint currentPixelOrigin;
  final double scaledTileSize;
  final ImageProvider? errorImage;
  final TileBuilder? tileBuilder;

  const AnimatedTile({
    super.key,
    required this.tile,
    required this.currentPixelOrigin,
    required this.scaledTileSize,
    required this.errorImage,
    required this.tileBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final pos = tile.coordinate.multiplyBy(scaledTileSize) - currentPixelOrigin;

    Widget tileWidget;
    if (tile.loadError && errorImage != null) {
      tileWidget = Image(image: errorImage!);
    } else if (tile.animationController == null) {
      tileWidget = RawImage(image: tile.imageInfo?.image, fit: BoxFit.fill);
    } else {
      tileWidget = AnimatedBuilder(
        animation: tile.animationController!,
        builder: (context, child) => RawImage(
          image: tile.imageInfo?.image,
          fit: BoxFit.fill,
          opacity: tile.animationController!,
        ),
      );
    }

    return Positioned(
      left: pos.x.toDouble(),
      top: pos.y.toDouble(),
      width: scaledTileSize,
      height: scaledTileSize,
      child: tileBuilder?.call(context, tileWidget, tile) ?? tileWidget,
    );
  }
}

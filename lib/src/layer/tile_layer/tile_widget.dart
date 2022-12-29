import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_transformation.dart';

class AnimatedTile extends StatelessWidget {
  final Tile tile;
  final CustomPoint size;
  final TileTransformation tileTransformation;
  final ImageProvider? errorImage;
  final TileBuilder? tileBuilder;

  const AnimatedTile({
    required this.tile,
    required this.size,
    required this.tileTransformation,
    required this.errorImage,
    required this.tileBuilder,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final pos = tile.tilePos.multiplyBy(tileTransformation.scale) +
        tileTransformation.translate;
    final num width = size.x * tileTransformation.scale;
    final num height = size.y * tileTransformation.scale;

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
            opacity: tile.animationController!),
      );
    }

    return Positioned(
      left: pos.x.toDouble(),
      top: pos.y.toDouble(),
      width: width.toDouble(),
      height: height.toDouble(),
      child: tileBuilder?.call(context, tileWidget, tile) ?? tileWidget,
    );
  }
}

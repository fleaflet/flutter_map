import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_transformation.dart';
import 'package:vector_math/vector_math_64.dart';

class AnimatedTile extends StatelessWidget {
  static final Vector3 _tileVectorStorage = Vector3.all(1);
  static final Vector3 _transformedTileVectorStorage = Vector3.zero();

  final Tile tile;
  final CustomPoint size;
  final TileTransformation tileTransformation;

  const AnimatedTile({
    required this.tile,
    required this.size,
    required this.tileTransformation,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    _tileVectorStorage.x = tile.tilePos.x.toDouble();
    _tileVectorStorage.y = tile.tilePos.y.toDouble();

    final transformedTilePos = tileTransformation.transformation.transformed(
      _tileVectorStorage,
      _transformedTileVectorStorage,
    );

    return Positioned(
      left: transformedTilePos.x,
      top: transformedTilePos.y,
      width: tileTransformation.scaledTileSize.x.toDouble(),
      height: tileTransformation.scaledTileSize.y.toDouble(),
      child: RawImage(
        image: tile.imageInfo?.image,
        fit: BoxFit.fill,
      ),
    );
  }
}

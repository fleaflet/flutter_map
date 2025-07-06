import 'package:flutter/widgets.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/base_tile_layer.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/options.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/tile_loader/loader.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/tile_loader/source_fetchers/network/network.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/tile_loader/source_generators/slippy.dart';

class RasterTileLayer extends StatefulWidget {
  const RasterTileLayer({super.key});

  @override
  State<RasterTileLayer> createState() => _RasterTileLayerState();
}

class _RasterTileLayerState extends State<RasterTileLayer> {
  @override
  Widget build(BuildContext context) => BaseTileLayer(
        options: const TileLayerOptions(),
        tileLoader: TileLoader(
          sourceGenerator: const SlippyMapGenerator(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          ),
          sourceFetcher:
              NetworkBytesFetcher.withUAIdentifier('com.example.app'),
        ),
        renderer: (context, visibleTiles, options) {
          throw UnimplementedError();
        },
      );
}

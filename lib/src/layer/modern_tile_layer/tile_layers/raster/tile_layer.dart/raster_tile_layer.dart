import 'package:flutter/widgets.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/base_tile_layer.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/options.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/tile_loader/loader.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/tile_loader/source_fetchers/bytes_fetchers/bytes_fetcher.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/tile_loader/source_fetchers/bytes_fetchers/network/network.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/tile_loader/source_fetchers/raster/raster_tile_fetcher.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/tile_loader/source_fetchers/raster/tile_data.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/tile_loader/source_generator_fetcher.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/tile_loader/source_generators/xyz.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/tile_loader/tile_source.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_coordinates.dart';

class RasterTileLayer extends StatefulWidget {
  const RasterTileLayer({
    super.key,
    this.options = const TileLayerOptions(),
    required this.sourceGenerator,
    required this.bytesFetcher,
  });

  RasterTileLayer.simple({
    super.key,
    this.options = const TileLayerOptions(),
    required String urlTemplate,
    required String uaIdentifier,
  })  : sourceGenerator = XYZGenerator(uriTemplate: urlTemplate),
        bytesFetcher = NetworkBytesFetcher(uaIdentifier: uaIdentifier);

  final TileLayerOptions options;
  final TileSourceGenerator<TileSource> sourceGenerator;
  final TileBytesFetcher<TileSource> bytesFetcher;

  @override
  State<RasterTileLayer> createState() => _RasterTileLayerState();
}

class _RasterTileLayerState extends State<RasterTileLayer> {
  @override
  Widget build(BuildContext context) => BaseTileLayer(
        options: widget.options,
        tileLoader: TileLoader(
          sourceGenerator: widget.sourceGenerator,
          sourceFetcher: RasterTileFetcher(bytesFetcher: widget.bytesFetcher),
        ),
        renderer: (context, layerKey, options, visibleTiles) => _RasterRenderer(
          layerKey: layerKey,
          options: options,
          visibleTiles: visibleTiles,
        ),
      );
}

class _RasterRenderer extends StatefulWidget {
  _RasterRenderer({
    required Object layerKey,
    required this.options,
    required this.visibleTiles,
  }) : super(key: ValueKey(layerKey));

  final TileLayerOptions options;
  final Map<({TileCoordinates coordinates, Object layerKey}), RasterTileData>
      visibleTiles;

  @override
  State<_RasterRenderer> createState() => __RasterRendererState();
}

class __RasterRendererState extends State<_RasterRenderer> {
  //final Map<({TileCoordinates coordinates, Object layerKey}),
  //    TileData<Uint8List>> visibleTiles = {};

  @override
  void didUpdateWidget(covariant _RasterRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      willChange: true,
      painter: _RasterPainter(
        options: widget.options,
        visibleTiles: widget.visibleTiles,
        //tiles: tiles..sort(renderOrder),
        //tilePaint: widget.tilePaint,
        //tileOverlayPainter: widget.tileOverlayPainter,
      ),
    );
  }
}

class _RasterPainter extends CustomPainter {
  final TileLayerOptions options;
  final Map<({TileCoordinates coordinates, Object layerKey}), RasterTileData>
      visibleTiles;

  _RasterPainter({
    super.repaint,
    required this.options,
    required this.visibleTiles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final MapEntry(key: (:coordinates, layerKey: _), value: tile)
        in visibleTiles.entries) {
      //final image = tile.imageInfo.
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    // TODO: implement shouldRepaint
    throw UnimplementedError();
  }
}

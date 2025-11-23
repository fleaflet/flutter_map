import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/base_tile_layer.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/options.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/source_generators/source_generator.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/source_generators/xyz.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/tile_loader/bytes_fetchers/bytes_fetcher.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/tile_loader/bytes_fetchers/network/fetcher/network.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/tile_loader/raster/tile_data.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/tile_loader/raster/tile_loader.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/tile_loader/tile_source.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_coordinates.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_scale_calculator.dart';

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
  })  : sourceGenerator = XYZSourceGenerator(uriTemplates: [urlTemplate]),
        bytesFetcher = NetworkBytesFetcher(uaIdentifier: uaIdentifier);

  final TileLayerOptions options;
  final SourceGenerator<TileSource> sourceGenerator;
  final SourceBytesFetcher<Iterable<String>> bytesFetcher;

  @override
  State<RasterTileLayer> createState() => _RasterTileLayerState();
}

class _RasterTileLayerState extends State<RasterTileLayer> {
  @override
  Widget build(BuildContext context) => BaseTileLayer(
        options: widget.options,
        tileLoader: RasterTileLoader(
          sourceGenerator: widget.sourceGenerator,
          bytesFetcher: widget.bytesFetcher,
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

  final _tileScaleCalculator =
      TileScaleCalculator(crs: Epsg3857(), tileDimension: 256);

  @override
  void didUpdateWidget(covariant _RasterRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    final map = MapCamera.of(context);

    _tileScaleCalculator.clearCacheUnlessZoomMatches(map.zoom);

    return CustomPaint(
      size: Size.infinite,
      willChange: true,
      painter: _RasterPainter(
        options: widget.options,
        visibleTiles: widget.visibleTiles.entries.map(
          (tile) => (
            coordinates: tile.key.coordinates,
            scaledTileDimension: _tileScaleCalculator.scaledTileDimension(
              map.zoom,
              tile.key.coordinates.z,
            ),
            currentPixelOrigin: map.pixelOrigin,
            data: tile.value,
          ),
        ),
        //tiles: tiles..sort(renderOrder),
        //tilePaint: widget.tilePaint,
        //tileOverlayPainter: widget.tileOverlayPainter,
      ),
    );
  }
}

class _RasterPainter extends CustomPainter {
  final TileLayerOptions options;
  final Iterable<
      ({
        TileCoordinates coordinates,
        double scaledTileDimension,
        Offset currentPixelOrigin,
        RasterTileData data
      })> visibleTiles;

  _RasterPainter({
    super.repaint,
    required this.options,
    required this.visibleTiles,
  });

  final Paint _basePaint = (null ?? Paint())
    ..filterQuality = FilterQuality.high
    ..isAntiAlias = true;

  @override
  void paint(Canvas canvas, Size size) {
    for (final tile in visibleTiles) {
      if (tile.data.loaded?.successfulImageInfo?.image case final image?) {
        final origin = Offset(
          tile.coordinates.x * tile.scaledTileDimension -
              tile.currentPixelOrigin.dx,
          tile.coordinates.y * tile.scaledTileDimension -
              tile.currentPixelOrigin.dy,
        );
        final destSize = Size.square(tile.scaledTileDimension);

        //final paint = _basePaint
        //  ..color = (null?.color.withOpacity(tile.tileImage.opacity) ??
        //      Color.fromRGBO(0, 0, 0, tile.tileImage.opacity));

        canvas.drawImageRect(
          image,
          Offset.zero &
              Size(image.width.toDouble(), image.height.toDouble()), // src
          origin & destSize, // dest
          _basePaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

part of 'tile_layer.dart';

class _RasterRenderer extends StatefulWidget {
  _RasterRenderer({
    required Object layerKey,
    required this.visibleTiles,
    required this.options,
    required this.rasterOptions,
  }) : super(key: ValueKey(layerKey));

  final Map<({TileCoordinates coordinates, Object layerKey}), RasterTileData>
      visibleTiles;
  final TileLayerOptions options;
  final RasterTileLayerOptions rasterOptions;

  @override
  State<_RasterRenderer> createState() => __RasterRendererState();
}

class __RasterRendererState extends State<_RasterRenderer> {
  late var _tileScaleCalculator = _generateTileScaleCalculator();
  TileScaleCalculator _generateTileScaleCalculator() => TileScaleCalculator(
        crs: widget.rasterOptions.crs ?? const Epsg3857(),
        tileDimension: widget.options.tileDimension,
      );

  @override
  void didUpdateWidget(covariant _RasterRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.rasterOptions.crs != oldWidget.rasterOptions.crs ||
        widget.options.tileDimension != oldWidget.options.tileDimension) {
      _tileScaleCalculator = _generateTileScaleCalculator();
    }
  }

  @override
  Widget build(BuildContext context) {
    final map = MapCamera.of(context);

    _tileScaleCalculator.clearCacheUnlessZoomMatches(map.zoom);

    return MobileLayerTransformer(
      child: CustomPaint(
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

        //final paint = _basePaint
        //  ..color = (null?.color.withOpacity(tile.tileImage.opacity) ??
        //      Color.fromRGBO(0, 0, 0, tile.tileImage.opacity));

        canvas.drawImageRect(
          image,
          Offset.zero &
              Size(image.width.toDouble(), image.height.toDouble()), // src
          origin & Size.square(tile.scaledTileDimension), // dest
          _basePaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

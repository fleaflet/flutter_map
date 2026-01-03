part of 'tile_layer.dart';

class _RasterRenderer extends StatefulWidget {
  _RasterRenderer({
    required Object layerKey,
    required this.visibleTiles,
    required this.options,
    required this.rasterOptions,
  }) : super(key: ValueKey(layerKey));

  final Map<({TileCoordinates coordinates, Object layerKey}),
      InternalRasterTileData> visibleTiles;
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
          rasterOptions: widget.rasterOptions,
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
          // TODO: Really? No sorting?
        ),
      ),
    );
  }
}

class _RasterPainter extends CustomPainter {
  final TileLayerOptions options;
  final RasterTileLayerOptions rasterOptions;
  final Iterable<
      ({
        TileCoordinates coordinates,
        double scaledTileDimension,
        Offset currentPixelOrigin,
        InternalRasterTileData data
      })> visibleTiles;

  _RasterPainter({
    super.repaint,
    required this.options,
    required this.rasterOptions,
    required this.visibleTiles,
  });

  late final _paint = rasterOptions.basePaint ??
      (Paint()
        ..filterQuality = FilterQuality.high
        ..isAntiAlias = false);

  @override
  void paint(Canvas canvas, Size size) {
    for (final tile in visibleTiles) {
      final tileSize = Size.square(tile.scaledTileDimension);
      final originDx = tile.coordinates.x * tile.scaledTileDimension -
          tile.currentPixelOrigin.dx;
      final originDy = tile.coordinates.y * tile.scaledTileDimension -
          tile.currentPixelOrigin.dy;

      if (rasterOptions.paintTile == null) {
        if (tile.data.imageInfo?.image case final image?) {
          //_basePaint..color = _basePaint.color.withAlpha(tile.data.opacity);

          canvas.drawImageRect(
            image,
            Offset.zero &
                Size(image.width.toDouble(), image.height.toDouble()), // src
            Offset(originDx, originDy) & tileSize, // dest
            _paint,
          );
        }

        continue;
      }

      final subCanvasPictureRecorder = PictureRecorder();
      final subCanvas = Canvas(subCanvasPictureRecorder);

      rasterOptions.paintTile!(
        subCanvas,
        tileSize,
        tile.coordinates,
        tile.data.currentPublicData,
        _paint,
        ({destRect}) {
          if (tile.data.imageInfo?.image case final image?) {
            //_paint.color = _paint.color.withAlpha(255 ~/ 2);

            subCanvas.drawImageRect(
              image,
              Offset.zero &
                  Size(image.width.toDouble(), image.height.toDouble()), // src
              destRect ?? (Offset.zero & tileSize), // dest
              _paint,
            );
          }
        },
      );

      canvas
        ..save()
        ..translate(originDx, originDy)
        ..drawPicture(subCanvasPictureRecorder.endRecording())
        ..restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    // TODO
    return true;
  }
}

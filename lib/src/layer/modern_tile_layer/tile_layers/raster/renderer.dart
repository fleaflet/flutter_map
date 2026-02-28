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
  @override
  Widget build(BuildContext context) {
    return TileLayerCanvasRenderer(
      visibleTiles: widget.visibleTiles,
      options: widget.options,
      canvasRendererOptions: widget.rasterOptions,
      draw: _draw,
    );
  }

  void _draw({
    required Canvas canvas,
    required Rect destRect,
    required Paint tilePaint,
    required TileCoordinates tileCoordinates,
    required covariant InternalRasterTileData tileData,
  }) {
    if (tileData.imageInfo?.image case final image?) {
      canvas.drawImageRect(
        image,
        Offset.zero &
            Size(image.width.toDouble(), image.height.toDouble()), // src
        destRect, // dest
        tilePaint,
      );
    }
  }
}

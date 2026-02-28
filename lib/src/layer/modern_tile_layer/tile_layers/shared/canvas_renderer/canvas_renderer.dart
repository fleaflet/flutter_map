import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/tile_layers/shared/canvas_renderer/options.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_scale_calculator.dart';

typedef ImplementerSingleTilePainterCallback<D extends BaseTileData> = void
    Function({
  required Canvas canvas,
  required Rect destRect,
  required Paint tilePaint,
  required TileCoordinates tileCoordinates,
  required D tileData,
});

class TileLayerCanvasRenderer<D extends BaseTileData> extends StatefulWidget {
  const TileLayerCanvasRenderer({
    super.key,
    required this.visibleTiles,
    required this.options,
    required this.canvasRendererOptions,
    required this.draw,
  });

  final ImplementerSingleTilePainterCallback<D> draw;
  final Map<({TileCoordinates coordinates, Object layerKey}), D> visibleTiles;
  final TileLayerOptions options;
  final CanvasRendererOptions canvasRendererOptions;

  @override
  State<TileLayerCanvasRenderer> createState() =>
      _TileLayerCanvasRendererState();
}

class _TileLayerCanvasRendererState extends State<TileLayerCanvasRenderer> {
  late var _tileScaleCalculator = _generateTileScaleCalculator();
  TileScaleCalculator _generateTileScaleCalculator() => TileScaleCalculator(
        crs: widget.options.crs ?? const Epsg3857(),
        tileDimension: widget.options.tileDimension,
      );

  @override
  void didUpdateWidget(covariant TileLayerCanvasRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.options.crs != oldWidget.options.crs ||
        widget.options.tileDimension != oldWidget.options.tileDimension) {
      _tileScaleCalculator = _generateTileScaleCalculator();
    }
  }

  @override
  Widget build(BuildContext context) {
    final map = MapCamera.of(context);

    _tileScaleCalculator.clearCacheUnlessZoomMatches(map.zoom);

    return CustomPaint(
      size: Size.infinite,
      willChange: true,
      painter: _CanvasPainter(
        draw: widget.draw,
        options: widget.options,
        canvasRendererOptions: widget.canvasRendererOptions,
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
    );
  }
}

class _CanvasPainter<D extends BaseTileData> extends CustomPainter {
  final TileLayerOptions options;
  final CanvasRendererOptions canvasRendererOptions;
  final Iterable<
      ({
        TileCoordinates coordinates,
        double scaledTileDimension,
        Offset currentPixelOrigin,
        D data
      })> visibleTiles;
  final ImplementerSingleTilePainterCallback<D> draw;

  _CanvasPainter({
    super.repaint,
    required this.options,
    required this.canvasRendererOptions,
    required this.visibleTiles,
    required this.draw,
  });

  late final _paint = canvasRendererOptions.basePaint ??
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

      if (canvasRendererOptions.paintTile case final paintCallback?) {
        final subCanvasPictureRecorder = PictureRecorder();
        final subCanvas = Canvas(subCanvasPictureRecorder);

        paintCallback(
          subCanvas,
          tileSize,
          _paint,
          tile.coordinates,
          tile.data.loadStatus,
          ({destRect}) => draw(
            canvas: subCanvas,
            destRect: destRect ?? Offset.zero & tileSize,
            tilePaint: _paint,
            tileCoordinates: tile.coordinates,
            tileData: tile.data,
          ),
        );

        canvas
          ..save()
          ..translate(originDx, originDy)
          ..drawPicture(subCanvasPictureRecorder.endRecording())
          ..restore();

        continue;
      }

      draw(
        canvas: canvas,
        destRect: Offset(originDx, originDy) & tileSize,
        tilePaint: _paint,
        tileCoordinates: tile.coordinates,
        tileData: tile.data,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    // TODO
    return true;
  }
}

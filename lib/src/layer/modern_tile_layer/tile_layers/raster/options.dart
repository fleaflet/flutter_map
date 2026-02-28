import 'package:flutter_map/src/layer/modern_tile_layer/tile_layers/shared/canvas_renderer/options.dart';

class RasterTileLayerOptions extends CanvasRendererOptions {
  const RasterTileLayerOptions({super.basePaint, super.paintTile});

  @override
  // ignore: unnecessary_overrides
  bool operator ==(Object other) => super == other;

  @override
  // ignore: unnecessary_overrides
  int get hashCode => super.hashCode;
}

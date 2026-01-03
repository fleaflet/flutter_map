import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/tile_loader/raster/internal_tile_data.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_scale_calculator.dart';

part 'renderer.dart';

/// A specialised [BaseTileLayer] where the tiles' contents are raster images.
class RasterTileLayer extends StatefulWidget {
  /// Construct a raster tile layer.
  ///
  /// Using this constructor instead of [RasterTileLayer.simple] allows more
  /// flexibility, but comes with additional responsibilities.
  ///
  /// [RasterTileLayer.simple] allows the internals to manage the
  /// [RasterTileLoader], [XYZSourceGenerator], and particularly the
  /// [NetworkBytesFetcher]. This reduces unnecessary rebuilding of the map and
  /// maximises the lifespan of certain objects to improve performance.
  ///
  /// When using this constructor, construct these objects (or the equivalents
  /// for your use-case) outside of your widget's `build` method wherever
  /// possible, then pass them to the [loader] argument. Where a part of the
  /// loader depends on the `build` method (such as inheriting via the
  /// `BuildContext`), construct as many non-dependent components outside
  /// as possible. This is particularly important when using the
  /// [NetworkBytesFetcher] - constructing the HTTP client once is much cheaper
  /// and allows connections to remain open, improving performance.
  const RasterTileLayer({
    super.key,
    this.options = const TileLayerOptions(),
    this.rasterOptions = const RasterTileLayerOptions(),
    required this.loader,
  }) : _simpleLoaderParams = null;

  /// Construct a raster tile layer which loads tiles from a network URL which
  /// uses the XYZ format for referencing tiles.
  ///
  /// If more control over the [SourceGenerator] or [SourceBytesFetcher] is
  /// required, use [RasterTileLayer.new].
  ///
  /// [urlTemplate] is an endpoint for tile resources, in XYZ template format.
  /// See [XYZSourceGenerator.uriTemplates] for more info.
  ///
  /// [uaIdentifier] is the 'User-Agent' unique identifier for your project,
  /// which tile servers can use to monitor traffic. See
  /// [NetworkBytesFetcher.new] for more info.
  const RasterTileLayer.simple({
    super.key,
    this.options = const TileLayerOptions(),
    this.rasterOptions = const RasterTileLayerOptions(),
    required String urlTemplate,
    required String uaIdentifier,
  })  : _simpleLoaderParams =
            (urlTemplate: urlTemplate, uaIdentifier: uaIdentifier),
        loader = null;

  /// Configuration of the base [BaseTileLayer].
  final TileLayerOptions options;

  /// Configuration of options specific to the [RasterTileLayer].
  final RasterTileLayerOptions rasterOptions;

  /// [RasterTileLoader] defined by the [RasterTileLayer.new] constructor.
  ///
  /// `null` if the [RasterTileLayer.simple] constructor was used.
  final RasterTileLoader? loader;

  /// Immutable parameters for the internally-managed [RasterTileLoader] defined
  /// by the [RasterTileLayer.simple] constructor.
  ///
  /// `null` if the [RasterTileLayer.new] constructor was used.
  final ({String urlTemplate, String uaIdentifier})? _simpleLoaderParams;

  @override
  State<RasterTileLayer> createState() => _RasterTileLayerState();
}

class _RasterTileLayerState extends State<RasterTileLayer> {
  // When the user is using the `.simple` constructor, we try to minimise
  // rebuilding, new `layerKey`s, and new HTTP clients.
  late RasterTileLoader _loader = widget.loader ?? _generateLoaderFromSimple();
  RasterTileLoader _generateLoaderFromSimple() {
    assert(
      widget.loader == null,
      'May only be called when using `.simple` constructor',
    );
    return RasterTileLoader(
      sourceGenerator: XYZSourceGenerator(
        uriTemplates: [widget._simpleLoaderParams!.urlTemplate],
      ),
      bytesFetcher: NetworkBytesFetcher(
        uaIdentifier: widget._simpleLoaderParams!.uaIdentifier,
      ),
    );
  }

  @override
  void didUpdateWidget(covariant RasterTileLayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.loader != oldWidget.loader ||
        widget._simpleLoaderParams != oldWidget._simpleLoaderParams) {
      _loader = widget.loader ?? _generateLoaderFromSimple();
    }
  }

  @override
  Widget build(BuildContext context) => BaseTileLayer(
        options: widget.options,
        tileLoader: _loader,
        renderer: _renderer,
      );

  Widget _renderer(
    BuildContext context,
    Object layerKey,
    Map<({TileCoordinates coordinates, Object layerKey}),
            InternalRasterTileData>
        visibleTiles,
  ) =>
      _RasterRenderer(
        layerKey: layerKey,
        visibleTiles: visibleTiles,
        options: widget.options,
        rasterOptions: widget.rasterOptions,
      );
}

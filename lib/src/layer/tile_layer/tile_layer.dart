import 'dart:async';
import 'dart:math';

import 'package:collection/collection.dart' show MapEquality;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/layer/tile_layer/tile.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_bounds/tile_bounds.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_bounds/tile_bounds_at_zoom.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_image_manager.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_range.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_range_calculator.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_scale_calculator.dart';
import 'package:http/http.dart';
import 'package:http/retry.dart';
import 'package:logger/logger.dart';

part 'retina_mode.dart';
part 'tile_error_evict_callback.dart';
part 'wms_tile_layer_options.dart';

/// Describes the needed properties to create a tile-based layer. A tile is an
/// image bound to a specific geographical position.
///
/// You should read up about the options by exploring each one, or visiting
/// https://docs.fleaflet.dev/usage/layers/tile-layer. Some are important to
/// avoid issues.
@immutable
class TileLayer extends StatefulWidget {
  /// The URL template is a string that contains placeholders, which, when filled
  /// in, create a URL/URI to a specific tile.
  ///
  /// For more information, see <https://docs.fleaflet.dev/layers/tile-layer>.
  final String? urlTemplate;

  /// Fallback URL template, used if an error occurs when fetching tiles from
  /// the [urlTemplate].
  ///
  /// Note that specifying this (non-null) will result in tiles not being cached
  /// in memory. This is to avoid issues where the [urlTemplate] is flaky, to
  /// prevent different tilesets being displayed at the same time.
  ///
  /// It is expected that this follows the same retina support behaviour as
  /// [urlTemplate].
  ///
  /// Avoid specifying this when using [AssetTileProvider] or [FileTileProvider],
  /// as these providers are less performant and efficient when this is
  /// specified. See their documentation for more information.
  final String? fallbackUrl;

  /// If `true`, inverses Y axis numbering for tiles (turn this on for
  /// [TMS](https://en.wikipedia.org/wiki/Tile_Map_Service) services).
  final bool tms;

  /// If not `null`, then tiles will pull's WMS protocol requests
  final WMSTileLayerOptions? wmsOptions;

  /// Size for the tile.
  /// Default is 256
  late final double tileSize;

  /// The minimum zoom level down to which this layer will be displayed
  /// (inclusive)
  ///
  /// This should usually be 0 (as default).
  late final double minZoom;

  /// The maximum zoom level up to which this layer will be displayed
  /// (inclusive).
  ///
  /// Prefer [maxNativeZoom] for setting the maximum zoom level supported by the
  /// tile source. The main usage for this is to display a different [TileLayer]
  /// when zoomed far in.
  ///
  /// Otherwise, this should usually be infinite (as default), so that there are
  /// tiles always displayed.
  late final double maxZoom;

  /// Minimum zoom level supported by the tile source
  ///
  /// Tiles from below this zoom level will not be displayed, instead tiles at
  /// this zoom level will be displayed and scaled.
  ///
  /// This should usually be 0 (as default), as most tile sources will support
  /// zoom levels onwards from this.
  late final int minNativeZoom;

  /// Maximum zoom number supported by the tile source has available.
  ///
  /// Tiles from above this zoom level will not be displayed, instead tiles at
  /// this zoom level will be displayed and scaled.
  ///
  /// Most tile servers support up to zoom level 19, which is the default.
  /// Otherwise, this should be specified.
  late final int maxNativeZoom;

  /// If set to true, the zoom number used in tile URLs will be reversed
  /// (`maxZoom - zoom` instead of `zoom`)
  final bool zoomReverse;

  /// The zoom number used in tile URLs will be offset with this value.
  late final double zoomOffset;

  /// List of subdomains for the URL.
  ///
  /// Example:
  ///
  /// Subdomains = {a,b,c}
  ///
  /// and the URL is as follows:
  ///
  /// https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png
  ///
  /// then:
  ///
  /// https://a.tile.openstreetmap.org/{z}/{x}/{y}.png
  /// https://b.tile.openstreetmap.org/{z}/{x}/{y}.png
  /// https://c.tile.openstreetmap.org/{z}/{x}/{y}.png
  final List<String> subdomains;

  /// Control how tiles are displayed and whether they are faded in when loaded.
  /// Defaults to TileDisplay.fadeIn().
  final TileDisplay tileDisplay;

  /// Provider with which to load map tiles
  ///
  /// The default is [NetworkTileProvider] which supports both IO and web
  /// platforms, with basic session-only caching. It uses a [RetryClient] backed
  /// by a standard [Client] to retry failed requests.
  ///
  /// `userAgentPackageName` is a [TileLayer] parameter, which should be passed
  /// the application's correct package name, such as 'com.example.app'. See
  /// https://docs.fleaflet.dev/layers/tile-layer#useragentpackagename for
  /// more information.
  ///
  /// For information about other prebuilt tile providers, see
  /// https://docs.fleaflet.dev/layers/tile-layer/tile-providers.
  late final TileProvider tileProvider;

  /// When panning the map, keep this many rows and columns of tiles before
  /// unloading them.
  final int keepBuffer;

  /// When loading tiles only visible tiles are loaded by default. This option
  /// increases the loaded tiles by the given number on both axis which can help
  /// prevent the user from seeing loading tiles whilst panning. Setting the
  /// pan buffer too high can impact performance, typically this is set to zero
  /// or one.
  final int panBuffer;

  /// Tile image to show in place of the tile that failed to load.
  final ImageProvider? errorImage;

  /// Static information that should replace placeholders in the [urlTemplate].
  /// Applying API keys is a good example on how to use this parameter.
  ///
  /// Example:
  ///
  /// ```dart
  ///
  /// TileLayerOptions(
  ///     urlTemplate: "https://api.tiles.mapbox.com/v4/"
  ///                  "{id}/{z}/{x}/{y}{r}.png?access_token={accessToken}",
  ///     additionalOptions: {
  ///         'accessToken': '<PUT_ACCESS_TOKEN_HERE>',
  ///          'id': 'mapbox.streets',
  ///     },
  /// ),
  /// ```
  final Map<String, String> additionalOptions;

  /// Resolved retina mode, based on the `retinaMode` passed in the constructor
  /// and the [urlTemplate]
  ///
  /// See [RetinaMode] for more information.
  late final RetinaMode resolvedRetinaMode;

  /// This callback will be executed if an error occurs when fetching tiles.
  final ErrorTileCallBack? errorTileCallback;

  /// Function which may Wrap Tile with custom Widget
  /// There are predefined examples in 'tile_builder.dart'
  final TileBuilder? tileBuilder;

  /// If a Tile was loaded with error and if strategy isn't `none` then TileProvider
  /// will be asked to evict Image based on current strategy
  /// (see #576 - even Error Images are cached in flutter)
  final EvictErrorTileStrategy evictErrorTileStrategy;

  /// Stream to notify the [TileLayer] that it needs resetting
  ///
  /// The tile layer will not listen to this stream if it is not specified on
  /// initial building, then later specified.
  final Stream<void>? reset;

  /// Only load tiles that are within these bounds
  final LatLngBounds? tileBounds;

  /// Restricts and limits [TileUpdateEvent]s (which are emitted 'by'
  /// [MapEvent]s), which cause tiles to update.
  ///
  /// For more information, see [TileUpdateTransformer].
  ///
  /// Defaults to [TileUpdateTransformers.ignoreTapEvents], which disables
  /// updates for map taps, secondary taps and long presses, which alone should
  /// not cause the camera to change position.
  ///
  /// Note that changing this after the layer has already been built will have
  /// no effect. If necessary, force a rebuild of the entire layer by changing
  /// the [key].
  final TileUpdateTransformer tileUpdateTransformer;

  /// Create a new [TileLayer] for the [FlutterMap] widget.
  TileLayer({
    super.key,
    this.urlTemplate,
    this.fallbackUrl,
    double tileSize = 256,
    double minZoom = 0,
    double maxZoom = double.infinity,
    int minNativeZoom = 0,
    int maxNativeZoom = 19,
    this.zoomReverse = false,
    double zoomOffset = 0.0,
    this.additionalOptions = const {},
    this.subdomains = const ['a', 'b', 'c'],
    this.keepBuffer = 2,
    this.panBuffer = 1,
    this.errorImage,
    final TileProvider? tileProvider,
    this.tms = false,
    this.wmsOptions,
    this.tileDisplay = const TileDisplay.fadeIn(),

    /// See [RetinaMode] for more information
    ///
    /// Defaults to `false` when `null`.
    final bool? retinaMode,
    this.errorTileCallback,
    this.tileBuilder,
    this.evictErrorTileStrategy = EvictErrorTileStrategy.none,
    this.reset,
    this.tileBounds,
    TileUpdateTransformer? tileUpdateTransformer,
    String userAgentPackageName = 'unknown',
  })  : assert(
          tileDisplay.when(
            instantaneous: (_) => true,
            fadeIn: (fadeIn) => fadeIn.duration > Duration.zero,
          )!,
          'The tile fade in duration needs to be bigger than zero',
        ),
        assert(
          urlTemplate == null || wmsOptions == null,
          'Cannot specify both `urlTemplate` and `wmsOptions`',
        ),
        tileProvider = tileProvider ?? NetworkTileProvider(),
        tileUpdateTransformer =
            tileUpdateTransformer ?? TileUpdateTransformers.ignoreTapEvents {
    // Debug Logging
    if (kDebugMode &&
        urlTemplate != null &&
        urlTemplate!.contains('{s}.tile.openstreetmap.org')) {
      Logger(printer: PrettyPrinter(methodCount: 0)).w(
        '\x1B[1m\x1B[3mflutter_map\x1B[0m\nAvoid using subdomains with OSM\'s tile '
        'server. Support may be become slow or be removed in future.\nSee '
        'https://github.com/openstreetmap/operations/issues/737 for more info.',
      );
    }
    if (kDebugMode &&
        retinaMode == null &&
        urlTemplate != null &&
        urlTemplate!.contains('{r}')) {
      Logger(printer: PrettyPrinter(methodCount: 0)).w(
        '\x1B[1m\x1B[3mflutter_map\x1B[0m\nThe URL template includes a retina '
        "mode placeholder ('{r}') to retrieve native high-resolution\ntiles, "
        'which improve appearance especially on high-density displays.\n'
        'However, `TileLayer.retinaMode` was left unset, meaning flutter_map '
        'will never retrieve these tiles.\nConsider using '
        '`RetinaMode.isHighDensity` to toggle this property automatically, '
        'otherwise ensure\nit is set appropriately.\n'
        'See https://docs.fleaflet.dev/layers/tile-layer#retina-mode for '
        'more info.',
      );
    }
    if (kDebugMode && kIsWeb && tileProvider is NetworkTileProvider?) {
      Logger(printer: PrettyPrinter(methodCount: 0)).i(
        '\x1B[1m\x1B[3mflutter_map\x1B[0m\nConsider installing the official '
        "'flutter_map_cancellable_tile_provider' plugin for improved\n"
        'performance on the web.\nSee '
        'https://pub.dev/packages/flutter_map_cancellable_tile_provider for '
        'more info.',
      );
    }

    // Tile Provider Setup
    if (!kIsWeb) {
      this.tileProvider.headers.putIfAbsent(
          'User-Agent', () => 'flutter_map ($userAgentPackageName)');
    }

    // Retina Mode Setup
    resolvedRetinaMode = (retinaMode ?? false)
        ? wmsOptions == null && (urlTemplate?.contains('{r}') ?? false)
            ? RetinaMode.server
            : RetinaMode.simulation
        : RetinaMode.disabled;
    final useSimulatedRetina = resolvedRetinaMode == RetinaMode.simulation;

    this.maxZoom = useSimulatedRetina && !zoomReverse ? maxZoom - 1 : maxZoom;
    this.maxNativeZoom =
        useSimulatedRetina && !zoomReverse ? maxNativeZoom - 1 : maxNativeZoom;
    this.minZoom =
        useSimulatedRetina && zoomReverse ? max(minZoom + 1.0, 0) : minZoom;
    this.minNativeZoom = useSimulatedRetina && zoomReverse
        ? max(minNativeZoom + 1, 0)
        : minNativeZoom;
    this.zoomOffset = useSimulatedRetina
        ? (zoomReverse ? zoomOffset - 1.0 : zoomOffset + 1.0)
        : zoomOffset;
    this.tileSize =
        useSimulatedRetina ? (tileSize / 2.0).floorToDouble() : tileSize;
  }

  @override
  State<StatefulWidget> createState() => _TileLayerState();
}

class _TileLayerState extends State<TileLayer> with TickerProviderStateMixin {
  bool _initializedFromMapCamera = false;

  final _tileImageManager = TileImageManager();
  late TileBounds _tileBounds;
  late TileRangeCalculator _tileRangeCalculator;
  late TileScaleCalculator _tileScaleCalculator;

  // We have to hold on to the mapController hashCode to determine whether we
  // need to reinitialize the listeners. didChangeDependencies is called on
  // every map movement and if we unsubscribe and resubscribe every time we
  // miss events.
  int? _mapControllerHashCode;

  StreamSubscription<TileUpdateEvent>? _tileUpdateSubscription;
  Timer? _pruneLater;

  StreamSubscription<void>? _resetSub;

  @override
  void initState() {
    super.initState();
    _resetSub = widget.reset?.listen(_resetStreamHandler);
    _tileRangeCalculator = TileRangeCalculator(tileSize: widget.tileSize);
  }

  // This is called on every map movement so we should avoid expensive logic
  // where possible, or filter as necessary
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final camera = MapCamera.of(context);
    final mapController = MapController.of(context);

    if (_mapControllerHashCode != mapController.hashCode) {
      _tileUpdateSubscription?.cancel();

      _mapControllerHashCode = mapController.hashCode;
      _tileUpdateSubscription = mapController.mapEventStream
          .map((mapEvent) => TileUpdateEvent(mapEvent: mapEvent))
          .transform(widget.tileUpdateTransformer)
          .listen(_onTileUpdateEvent);
    }

    var reloadTiles = false;
    if (!_initializedFromMapCamera ||
        _tileBounds.shouldReplace(
            camera.crs, widget.tileSize, widget.tileBounds)) {
      reloadTiles = true;
      _tileBounds = TileBounds(
        crs: camera.crs,
        tileSize: widget.tileSize,
        latLngBounds: widget.tileBounds,
      );
    }

    if (!_initializedFromMapCamera ||
        _tileScaleCalculator.shouldReplace(camera.crs, widget.tileSize)) {
      reloadTiles = true;
      _tileScaleCalculator = TileScaleCalculator(
        crs: camera.crs,
        tileSize: widget.tileSize,
      );
    }

    if (reloadTiles) _loadAndPruneInVisibleBounds(camera);

    _initializedFromMapCamera = true;
  }

  @override
  void didUpdateWidget(TileLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    var reloadTiles = false;

    // There is no caching in TileRangeCalculator so we can just replace it.
    _tileRangeCalculator = TileRangeCalculator(tileSize: widget.tileSize);

    if (_tileBounds.shouldReplace(
        _tileBounds.crs, widget.tileSize, widget.tileBounds)) {
      _tileBounds = TileBounds(
        crs: _tileBounds.crs,
        tileSize: widget.tileSize,
        latLngBounds: widget.tileBounds,
      );
      reloadTiles = true;
    }

    if (_tileScaleCalculator.shouldReplace(
        _tileScaleCalculator.crs, widget.tileSize)) {
      _tileScaleCalculator = TileScaleCalculator(
        crs: _tileScaleCalculator.crs,
        tileSize: widget.tileSize,
      );
    }

    if (oldWidget.resolvedRetinaMode != widget.resolvedRetinaMode) {
      reloadTiles = true;
    }

    if (oldWidget.minZoom != widget.minZoom ||
        oldWidget.maxZoom != widget.maxZoom) {
      reloadTiles |=
          !_tileImageManager.allWithinZoom(widget.minZoom, widget.maxZoom);
    }

    if (!reloadTiles) {
      final oldUrl =
          oldWidget.wmsOptions?._encodedBaseUrl ?? oldWidget.urlTemplate;
      final newUrl = widget.wmsOptions?._encodedBaseUrl ?? widget.urlTemplate;

      final oldOptions = oldWidget.additionalOptions;
      final newOptions = widget.additionalOptions;

      if (oldUrl != newUrl ||
          !(const MapEquality<String, String>())
              .equals(oldOptions, newOptions)) {
        _tileImageManager.reloadImages(widget, _tileBounds);
      }
    }

    if (reloadTiles) {
      _tileImageManager.removeAll(widget.evictErrorTileStrategy);
      _loadAndPruneInVisibleBounds(MapCamera.maybeOf(context)!);
    } else if (oldWidget.tileDisplay != widget.tileDisplay) {
      _tileImageManager.updateTileDisplay(widget.tileDisplay);
    }

    if (widget.reset != oldWidget.reset) {
      _resetSub?.cancel();
      _resetSub = widget.reset?.listen(_resetStreamHandler);
    }
  }

  @override
  void dispose() {
    _tileUpdateSubscription?.cancel();
    _tileImageManager.removeAll(widget.evictErrorTileStrategy);
    _resetSub?.cancel();
    _pruneLater?.cancel();
    widget.tileProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final map = MapCamera.of(context);

    if (_outsideZoomLimits(map.zoom.round())) return const SizedBox.shrink();

    final tileZoom = _clampToNativeZoom(map.zoom);
    final tileBoundsAtZoom = _tileBounds.atZoom(tileZoom);
    final visibleTileRange = _tileRangeCalculator.calculate(
      camera: map,
      tileZoom: tileZoom,
    );

    // For a given map event both this rebuild method and the tile
    // loading/pruning logic will be fired. Any TileImages which are not
    // rendered in a corresponding Tile after this build will not become
    // visible until the next build. Therefore, in case this build is executed
    // before the loading/updating, we must pre-create the missing TileImages
    // and add them to the widget tree so that when they are loaded they notify
    // the Tile and become visible. We don't need to prune here as any new tiles
    // will be pruned when the map event triggers tile loading.
    _tileImageManager.createMissingTiles(
      visibleTileRange,
      tileBoundsAtZoom,
      createTile: (coordinates) => _createTileImage(
        coordinates: coordinates,
        tileBoundsAtZoom: tileBoundsAtZoom,
        pruneAfterLoad: false,
      ),
    );

    _tileScaleCalculator.clearCacheUnlessZoomMatches(map.zoom);

    // Note: `renderTiles` filters out all tiles that are either off-screen or
    // tiles at non-target zoom levels that are would be completely covered by
    // tiles that are *ready* and at the target zoom level.
    // We're happy to do a bit of diligent work here, since tiles not rendered are
    // cycles saved later on in the render pipeline.
    final tiles = _tileImageManager
        .getTilesToRender(visibleRange: visibleTileRange)
        .map((tileRenderer) => Tile(
              // Must be an ObjectKey, not a ValueKey using the coordinates, in
              // case we remove and replace the TileImage with a different one.
              key: ObjectKey(tileRenderer),
              scaledTileSize: _tileScaleCalculator.scaledTileSize(
                map.zoom,
                tileRenderer.positionCoordinates.z,
              ),
              currentPixelOrigin: map.pixelOrigin,
              tileImage: tileRenderer.tileImage,
              positionCoordinates: tileRenderer.positionCoordinates,
              tileBuilder: widget.tileBuilder,
            ))
        .toList();

    // Sort in render order. In reverse:
    //   1. Tiles at the current zoom.
    //   2. Tiles at the current zoom +/- 1.
    //   3. Tiles at the current zoom +/- 2.
    //   4. ...etc
    int renderOrder(Tile a, Tile b) {
      final (za, zb) = (a.tileImage.coordinates.z, b.tileImage.coordinates.z);
      final cmp = (zb - tileZoom).abs().compareTo((za - tileZoom).abs());
      if (cmp == 0) {
        // When compare parent/child tiles of equal distance, prefer higher res images.
        return za.compareTo(zb);
      }
      return cmp;
    }

    return MobileLayerTransformer(
      child: Stack(children: tiles..sort(renderOrder)),
    );
  }

  TileImage _createTileImage({
    required TileCoordinates coordinates,
    required TileBoundsAtZoom tileBoundsAtZoom,
    required bool pruneAfterLoad,
  }) {
    final cancelLoading = Completer<void>();

    final imageProvider = widget.tileProvider.supportsCancelLoading
        ? widget.tileProvider.getImageWithCancelLoadingSupport(
            tileBoundsAtZoom.wrap(coordinates),
            widget,
            cancelLoading.future,
          )
        : widget.tileProvider.getImage(
            tileBoundsAtZoom.wrap(coordinates),
            widget,
          );

    return TileImage(
      vsync: this,
      coordinates: coordinates,
      imageProvider: imageProvider,
      onLoadError: _onTileLoadError,
      onLoadComplete: (coordinates) {
        if (pruneAfterLoad) _pruneIfAllTilesLoaded(coordinates);
      },
      tileDisplay: widget.tileDisplay,
      errorImage: widget.errorImage,
      cancelLoading: cancelLoading,
    );
  }

  /// Load and/or prune tiles according to the visible bounds of the [event]
  /// center/zoom, or the current center/zoom if not specified.
  void _onTileUpdateEvent(TileUpdateEvent event) {
    final tileZoom = _clampToNativeZoom(event.zoom);
    final visibleTileRange = _tileRangeCalculator.calculate(
      camera: event.camera,
      tileZoom: tileZoom,
      center: event.center,
      viewingZoom: event.zoom,
    );

    if (event.load && !_outsideZoomLimits(tileZoom)) {
      _loadTiles(visibleTileRange, pruneAfterLoad: event.prune);
    }

    if (event.prune) {
      _tileImageManager.evictAndPrune(
        visibleRange: visibleTileRange,
        pruneBuffer: widget.panBuffer + widget.keepBuffer,
        evictStrategy: widget.evictErrorTileStrategy,
      );
    }
  }

  /// Load new tiles in the visible bounds and prune those outside.
  void _loadAndPruneInVisibleBounds(MapCamera camera) {
    final tileZoom = _clampToNativeZoom(camera.zoom);
    final visibleTileRange = _tileRangeCalculator.calculate(
      camera: camera,
      tileZoom: tileZoom,
    );

    if (!_outsideZoomLimits(tileZoom)) {
      _loadTiles(
        visibleTileRange,
        pruneAfterLoad: true,
      );
    }

    _tileImageManager.evictAndPrune(
      visibleRange: visibleTileRange,
      pruneBuffer: max(widget.panBuffer, widget.keepBuffer),
      evictStrategy: widget.evictErrorTileStrategy,
    );
  }

  // For all valid TileCoordinates in the [tileLoadRange], expanded by the
  // [TileLayer.panBuffer], this method will do the following depending on
  // whether a matching TileImage already exists or not:
  //   * Exists: Mark it as current and initiate image loading if it has not
  //     already been initiated.
  //   * Does not exist: Creates the TileImage (they are current when created)
  //     and initiates loading.
  //
  // Additionally, any current TileImages outside of the [tileLoadRange],
  // expanded by the [TileLayer.panBuffer] + [TileLayer.keepBuffer], are marked
  // as not current.
  void _loadTiles(
    DiscreteTileRange tileLoadRange, {
    required bool pruneAfterLoad,
  }) {
    final tileZoom = tileLoadRange.zoom;
    final expandedTileLoadRange = tileLoadRange.expand(widget.panBuffer);

    // Build the queue of tiles to load. Marks all tiles with valid coordinates
    // in the tileLoadRange as current.
    final tileBoundsAtZoom = _tileBounds.atZoom(tileZoom);
    final tilesToLoad = _tileImageManager.createMissingTiles(
      expandedTileLoadRange,
      tileBoundsAtZoom,
      createTile: (coordinates) => _createTileImage(
        coordinates: coordinates,
        tileBoundsAtZoom: tileBoundsAtZoom,
        pruneAfterLoad: pruneAfterLoad,
      ),
    );

    // Re-order the tiles by their distance to the center of the range.
    final tileCenter = expandedTileLoadRange.center;
    tilesToLoad.sort(
      (a, b) => _distanceSq(a.coordinates, tileCenter)
          .compareTo(_distanceSq(b.coordinates, tileCenter)),
    );

    // Create the new Tiles.
    for (final tile in tilesToLoad) {
      tile.load();
    }
  }

  /// Rounds the zoom to the nearest int and clamps it to the native zoom limits
  /// if there are any.
  int _clampToNativeZoom(double zoom) =>
      zoom.round().clamp(widget.minNativeZoom, widget.maxNativeZoom);

  void _onTileLoadError(TileImage tile, Object error, StackTrace? stackTrace) {
    debugPrint(error.toString());
    widget.errorTileCallback?.call(tile, error, stackTrace);
  }

  void _pruneIfAllTilesLoaded(TileCoordinates coordinates) {
    if (!_tileImageManager.containsTileAt(coordinates) ||
        !_tileImageManager.allLoaded) {
      return;
    }

    widget.tileDisplay.when(instantaneous: (_) {
      _pruneWithCurrentCamera();
    }, fadeIn: (fadeIn) {
      // Wait a bit more than tileFadeInDuration to trigger a pruning so that
      // we don't see tile removal under a fading tile.
      _pruneLater?.cancel();
      _pruneLater = Timer(
        fadeIn.duration + const Duration(milliseconds: 50),
        _pruneWithCurrentCamera,
      );
    });
  }

  void _pruneWithCurrentCamera() {
    final camera = MapCamera.of(context);
    final visibleTileRange = _tileRangeCalculator.calculate(
      camera: camera,
      tileZoom: _clampToNativeZoom(camera.zoom),
      center: camera.center,
      viewingZoom: camera.zoom,
    );
    _tileImageManager.prune(
      visibleRange: visibleTileRange,
      pruneBuffer: max(widget.panBuffer, widget.keepBuffer),
      evictStrategy: widget.evictErrorTileStrategy,
    );
  }

  bool _outsideZoomLimits(num zoom) =>
      zoom < widget.minZoom || zoom > widget.maxZoom;

  void _resetStreamHandler(void _) {
    _tileImageManager.removeAll(widget.evictErrorTileStrategy);
    if (mounted) _loadAndPruneInVisibleBounds(MapCamera.of(context));
  }
}

double _distanceSq(TileCoordinates coord, Point<double> center) {
  final dx = center.x - coord.x;
  final dy = center.y - coord.y;
  return dx * dx + dy * dy;
}

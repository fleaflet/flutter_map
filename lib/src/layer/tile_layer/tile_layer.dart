import 'dart:async';
import 'dart:math' as math;

import 'package:collection/collection.dart' show MapEquality;
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/src/core/bounds.dart';
import 'package:flutter_map/src/core/point.dart';
import 'package:flutter_map/src/core/util.dart' as util;
import 'package:flutter_map/src/geo/crs/crs.dart';
import 'package:flutter_map/src/geo/latlng_bounds.dart';
import 'package:flutter_map/src/gestures/map_events.dart';
import 'package:flutter_map/src/layer/tile_layer/tile.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_bounds/tile_bounds.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_bounds/tile_bounds_at_zoom.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_builder.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_coordinates.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_image.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_image_manager.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_provider/base_tile_provider.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_provider/tile_provider_web.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_range.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_range_calculator.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_scale_calculator.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_transition.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_update_event.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_update_transformer.dart';
import 'package:flutter_map/src/map/flutter_map_state.dart';

part 'tile_layer_options.dart';

/// Describes the needed properties to create a tile-based layer. A tile is an
/// image bound to a specific geographical position.
///
/// You should read up about the options by exploring each one, or visiting
/// https://docs.fleaflet.dev/usage/layers/tile-layer. Some are important to
/// avoid issues.
class TileLayer extends StatefulWidget {
  /// Defines the structure to create the URLs for the tiles. `{s}` means one of
  /// the available subdomains (can be omitted) `{z}` zoom level `{x}` and `{y}`
  /// — tile coordinates `{r}` can be used to add "&commat;2x" to the URL to
  /// load retina tiles (can be omitted)
  ///
  /// Example:
  ///
  /// https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png
  ///
  /// Is translated to this:
  ///
  /// https://a.tile.openstreetmap.org/12/2177/1259.png
  final String? urlTemplate;

  /// Follows the same structure as [urlTemplate]. If specified, this URL is
  /// used only if an error occurs when loading the [urlTemplate].
  final String? fallbackUrl;

  /// If `true`, inverses Y axis numbering for tiles (turn this on for
  /// [TMS](https://en.wikipedia.org/wiki/Tile_Map_Service) services).
  final bool tms;

  /// If not `null`, then tiles will pull's WMS protocol requests
  final WMSTileLayerOptions? wmsOptions;

  /// Size for the tile.
  /// Default is 256
  final double tileSize;

  // The minimum zoom level down to which this layer will be
  // displayed (inclusive).
  final double minZoom;

  /// The maximum zoom level up to which this layer will be displayed
  /// (inclusive). In most tile providers goes from 0 to 19.
  final double maxZoom;

  /// Minimum zoom number the tile source has available. If it is specified, the
  /// tiles on all zoom levels lower than minNativeZoom will be loaded from
  /// minNativeZoom level and auto-scaled.
  final int? minNativeZoom;

  /// Maximum zoom number the tile source has available. If it is specified, the
  /// tiles on all zoom levels higher than maxNativeZoom will be loaded from
  /// maxNativeZoom level and auto-scaled.
  final int? maxNativeZoom;

  /// If set to true, the zoom number used in tile URLs will be reversed
  /// (`maxZoom - zoom` instead of `zoom`)
  final bool zoomReverse;

  /// The zoom number used in tile URLs will be offset with this value.
  final double zoomOffset;

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

  /// Color shown behind the tiles
  final Color backgroundColor;

  /// Provider with which to load map tiles
  ///
  /// The default is [NetworkNoRetryTileProvider]. Alternatively, use
  /// [NetworkTileProvider] for a network provider which will retry requests.
  ///
  /// Both network providers will use some form of caching, although not reliable. For
  /// better options, see https://docs.fleaflet.dev/usage/layers/tile-layer#caching.
  ///
  /// `userAgentPackageName` is a construction parameter, which should be passed
  /// the application's correct package name, such as 'com.example.app'. If no
  /// value is passed, it defaults to 'unknown'. This parameter is used to form
  /// part of the 'User-Agent' header, which is important to avoid blocking by
  /// tile servers. Namely, the header is the following 'flutter_map (<packageName>)'.
  ///
  /// Header rules are as follows, after 'User-Agent' is generated as above:
  ///
  /// * If no provider is specified here, the default will be used with
  /// 'User-Agent' header injected (recommended)
  /// * If a provider is specified here with no 'User-Agent' header, that
  /// provider will be used and the 'User-Agent' header will be injected
  /// * If a provider is specified here with a 'User-Agent' header, that
  /// provider will be used and the 'User-Agent' header will not be changed to any created here
  ///
  /// [AssetTileProvider] and [FileTileProvider] are alternatives to network
  /// providers, which use the [urlTemplate] as a path instead.
  /// For example, 'assets/map/{z}/{x}/{y}.png' or
  /// '/storage/emulated/0/map_app/tiles/{z}/{x}/{y}.png'.
  ///
  /// Custom [TileProvider]s can also be used, but these will not follow the header
  /// rules above.
  final TileProvider tileProvider;

  /// When panning the map, keep this many rows and columns of tiles before
  /// unloading them.
  final int keepBuffer;

  /// When panning the map, extend the tilerange by this many tiles in each
  /// direction.
  /// Will cause extra tile loads, and impact performance.
  /// Be careful increasing this beyond 0 or 1.
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

  /// `false`: current Tiles will be first dropped and then reload via new url
  /// (default) `true`: current Tiles will be visible until new ones aren't
  /// loaded (new Tiles are loaded independently) @see
  /// https://github.com/johnpryan/flutter_map/issues/583
  final bool overrideTilesWhenUrlChanges;

  /// If `true`, it will request four tiles of half the specified size and a
  /// bigger zoom level in place of one to utilize the high resolution.
  ///
  /// If `true` then MapOptions's `maxZoom` should be `maxZoom - 1` since
  /// retinaMode just simulates retina display by playing with `zoomOffset`. If
  /// geoserver supports retina `@2` tiles then it it advised to use them
  /// instead of simulating it (use {r} in the [urlTemplate])
  ///
  /// It is advised to use retinaMode if display supports it, write code like
  /// this:
  ///
  /// ```dart
  /// TileLayerOptions(
  ///     retinaMode: true && MediaQuery.of(context).devicePixelRatio > 1.0,
  /// ),
  /// ```
  final bool retinaMode;

  /// This callback will be executed if an error occurs when fetching tiles.
  final ErrorTileCallBack? errorTileCallback;

  final TemplateFunction templateFunction;

  /// Function which may Wrap Tile with custom Widget
  /// There are predefined examples in 'tile_builder.dart'
  final TileBuilder? tileBuilder;

  // If a Tile was loaded with error and if strategy isn't `none` then TileProvider
  // will be asked to evict Image based on current strategy
  // (see #576 - even Error Images are cached in flutter)
  final EvictErrorTileStrategy evictErrorTileStrategy;

  /// Stream to notify the [TileLayer] that it needs resetting
  final Stream<void>? reset;

  /// Only load tiles that are within these bounds
  final LatLngBounds? tileBounds;

  /// If provided this transformer may be used to modify how/when tile updates
  /// are triggered. It is a StreamTransformer from MapEvent to TilUpdateEvent
  /// and therefore filtering/modifying/debouncing may be perfored based on the
  /// MapEvent.
  final TileUpdateTransformer? tileUpdateTransformer;

  /// Used internally to encapsulate the tile transition options.
  final TileTransition _tileTransition;

  TileLayer({
    super.key,
    this.urlTemplate,
    this.fallbackUrl,
    double tileSize = 256.0,
    double minZoom = 0.0,
    double maxZoom = 18.0,
    this.minNativeZoom,
    this.maxNativeZoom,
    this.zoomReverse = false,
    double zoomOffset = 0.0,
    Map<String, String>? additionalOptions,
    this.subdomains = const <String>[],
    this.keepBuffer = 2,
    this.panBuffer = 0,
    this.backgroundColor = const Color(0xFFE0E0E0),

    /// Sets the opacity of tile images to the given value (0.0 - 1.0), default
    /// 1.0. When opacity is not 1.0 [fastReplace] is always enabled to prevent
    /// overlapping tiles from being simultaneously visible. This disables fade
    /// in and is not suitable for interactive maps, see [fastReplace] for more
    /// information.
    ///
    /// If you need the map to be interactive and transparent you should wrap
    /// [TileLayer] in an [Opacity] widget. This is less performant but avoids
    /// flickering when moving the map.
    double opacity = 1.0,
    this.errorImage,
    TileProvider? tileProvider,
    this.tms = false,
    this.wmsOptions,

    /// Options for fading in tiles when they are loaded. If this is set to null
    /// no fade is performed.
    TileFadeIn? tileFadeIn,
    this.overrideTilesWhenUrlChanges = false,
    this.retinaMode = false,
    this.errorTileCallback,
    this.templateFunction = util.template,
    this.tileBuilder,
    this.evictErrorTileStrategy = EvictErrorTileStrategy.none,

    /// This option is useful when you have a transparent layer: rather than
    /// keeping the old layer visible when zooming (resulting in both layers
    /// being temporarily visible), the old layer is removed as quickly as
    /// possible when this is set to `true` (default `false`).
    ///
    /// This option is likely to cause some flickering of the transparent layer,
    /// most noticeable when using pinch-to-zoom. It's best used with maps that
    /// have `interactive` set to `false`, and zoom using buttons that call
    /// `MapController.move()`.
    ///
    /// When set to `true`, the `tileFadeIn*` options will be ignored.
    bool? fastReplace,
    this.reset,
    this.tileBounds,
    this.tileUpdateTransformer,
    String userAgentPackageName = 'unknown',
  })  : assert(tileFadeIn == null || tileFadeIn.duration > Duration.zero),
        maxZoom =
            wmsOptions == null && retinaMode && maxZoom > 0.0 && !zoomReverse
                ? maxZoom - 1.0
                : maxZoom,
        minZoom =
            wmsOptions == null && retinaMode && maxZoom > 0.0 && zoomReverse
                ? math.max(minZoom + 1.0, 0)
                : minZoom,
        zoomOffset = wmsOptions == null && retinaMode && maxZoom > 0.0
            ? (zoomReverse ? zoomOffset - 1.0 : zoomOffset + 1.0)
            : zoomOffset,
        tileSize = wmsOptions == null && retinaMode && maxZoom > 0.0
            ? (tileSize / 2.0).floorToDouble()
            : tileSize,
        additionalOptions = additionalOptions == null
            ? const <String, String>{}
            : Map.from(additionalOptions),
        tileProvider = tileProvider == null
            ? NetworkNoRetryTileProvider(
                headers: {'User-Agent': 'flutter_map ($userAgentPackageName)'},
              )
            : (tileProvider
              ..headers = <String, String>{
                ...tileProvider.headers,
                if (!tileProvider.headers.containsKey('User-Agent'))
                  'User-Agent': 'flutter_map ($userAgentPackageName)',
              }),
        _tileTransition = TileTransition.from(
          opacity: opacity,
          fastReplace: fastReplace,
          tileFadeIn: tileFadeIn,
        );

  @override
  State<StatefulWidget> createState() => _TileLayerState();
}

class _TileLayerState extends State<TileLayer> with TickerProviderStateMixin {
  bool _initializedFromMapState = false;

  final TileImageManager _tileImageManager = TileImageManager();
  late TileBounds _tileBounds;
  late TileRangeCalculator _tileRangeCalculator;
  late TileScaleCalculator _tileScaleCalculator;

  // We have to hold on to the mapController hashCode to determine whether we
  // need to reinitialize the listeners. didChangeDependencies is called on
  // every map movement and if we unsubscribe and resubscribe every time we
  // miss events.
  int? _mapControllerHashCode;

  // Only one of these two subscriptions will be initialized. If
  // TileLayer.tileUpdateTransformer is null then we subscribe to map movement
  // otherwise we subscribe to tile update events which are transformed from
  // map movements.
  StreamSubscription<MapEvent>? _mapMoveSubscription;
  StreamSubscription<TileUpdateEvent>? _tileUpdateSubscription;

  StreamSubscription<void>? _resetSub;
  Timer? _pruneLater;

  @override
  void initState() {
    super.initState();

    if (widget.reset != null) {
      _resetSub = widget.reset?.listen(
        (_) => _tileImageManager.removeAll(
          widget.evictErrorTileStrategy,
        ),
      );
    }

    _tileRangeCalculator = TileRangeCalculator(tileSize: widget.tileSize);
  }

  // This is called on every map movement so we should avoid expensive logic
  // where possible.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final mapState = FlutterMapState.maybeOf(context)!;

    final mapController = mapState.mapController;
    if (_mapControllerHashCode != mapController.hashCode) {
      _mapMoveSubscription?.cancel();
      _tileUpdateSubscription?.cancel();

      _mapControllerHashCode = mapController.hashCode;
      if (widget.tileUpdateTransformer == null) {
        _mapMoveSubscription = mapController.mapEventStream.listen((event) {
          _loadAndPruneInVisibleBounds(mapState);
        });
      } else {
        _tileUpdateSubscription = mapController.mapEventStream
            .transform(widget.tileUpdateTransformer!)
            .listen((event) => _onTileUpdateEvent(mapState, event));
      }
    }

    bool reloadTiles = false;
    if (!_initializedFromMapState ||
        _tileBounds.shouldReplace(
            mapState.options.crs, widget.tileSize, widget.tileBounds)) {
      reloadTiles = true;
      _tileBounds = TileBounds(
        crs: mapState.options.crs,
        tileSize: widget.tileSize,
        latLngBounds: widget.tileBounds,
      );
    }

    if (!_initializedFromMapState ||
        _tileScaleCalculator.shouldReplace(
            mapState.options.crs, widget.tileSize)) {
      reloadTiles = true;
      _tileScaleCalculator = TileScaleCalculator(
        crs: mapState.options.crs,
        tileSize: widget.tileSize,
      );
    }

    if (reloadTiles) {
      _tryWaitForSizeToBeInitialized(
        mapState,
        () => _loadAndPruneInVisibleBounds(mapState),
      );
    }

    _initializedFromMapState = true;
  }

  @override
  void didUpdateWidget(TileLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    bool reloadTiles = false;

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

    if (oldWidget.retinaMode != widget.retinaMode) {
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
        if (widget.overrideTilesWhenUrlChanges) {
          _tileImageManager.reloadImages(widget, _tileBounds);
          _loadAndPruneInVisibleBounds(FlutterMapState.maybeOf(context)!);
        } else {
          reloadTiles = true;
        }
      }
    }

    if (reloadTiles) {
      _tileImageManager.removeAll(widget.evictErrorTileStrategy);
      _loadAndPruneInVisibleBounds(FlutterMapState.maybeOf(context)!);
    } else if (oldWidget._tileTransition != widget._tileTransition) {
      _tileImageManager.updateTileTransition(widget._tileTransition);
    }
  }

  @override
  void dispose() {
    _mapMoveSubscription?.cancel();
    _tileUpdateSubscription?.cancel();
    _tileImageManager.removeAll(widget.evictErrorTileStrategy);
    _resetSub?.cancel();
    _pruneLater?.cancel();
    widget.tileProvider.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final map = FlutterMapState.maybeOf(context)!;

    if (_outsideZoomLimits(map.zoom.round())) return const SizedBox.shrink();

    final tileZoom = _clampToNativeZoom(map.zoom);
    final tileBoundsAtZoom = _tileBounds.atZoom(tileZoom);
    final visibleTileRange = _tileRangeCalculator.calculate(
      mapState: map,
      tileZoom: tileZoom,
    );

    // For a given map event both this rebuild method and the tile
    // loading/pruning logic will be fired. Any TileImages which are not
    // rendered in a corresponding Tile after this build will not become
    // visible until the next build. Therefore, in case this build is executed
    // before the loading/updating, we must pre-create the missing TileImages
    // and add them to the widget tree so that when they are loaded they notify
    // the Tile and become visible.
    _tileImageManager.createMissingTiles(
      visibleTileRange,
      tileBoundsAtZoom,
      createTileImage: (coordinate) => _createTileImage(
        coordinate,
        tileBoundsAtZoom,
      ),
    );

    final currentPixelOrigin = CustomPoint<double>(
      map.pixelOrigin.x.toDouble(),
      map.pixelOrigin.y.toDouble(),
    );

    _tileScaleCalculator.clearCacheUnlessZoomMatches(map.zoom);

    return Container(
      color: widget.backgroundColor,
      child: Stack(
        children: [
          ..._tileImageManager
              .inRenderOrder(widget.maxZoom, tileZoom)
              .map((tileImage) {
            return Tile(
              // Must be an ObjectKey, not a ValueKey using the coordinates, in
              // case we remove and replace the TileImage with a different one.
              key: ObjectKey(tileImage),
              scaledTileSize: _tileScaleCalculator.scaledTileSize(
                map.zoom,
                tileImage.coordinates.z,
              ),
              currentPixelOrigin: currentPixelOrigin,
              tileImage: tileImage,
              tileBuilder: widget.tileBuilder,
            );
          }),
        ],
      ),
    );
  }

  TileImage _createTileImage(
    TileCoordinates coordinates,
    TileBoundsAtZoom tileBoundsAtZoom,
  ) {
    return TileImage(
      vsync: this,
      coordinates: coordinates,
      imageProvider: widget.tileProvider.getImage(
        tileBoundsAtZoom.wrap(coordinates),
        widget,
      ),
      onLoadError: _onTileLoadError,
      onLoadComplete: _onTileLoadComplete,
      transition: widget._tileTransition,
      errorImage: widget.errorImage,
    );
  }

  // Load and/or prune tiles according to the visible bounds of the [event]
  // center/zoom, or the current center/zoom if not specified.
  void _onTileUpdateEvent(FlutterMapState mapState, TileUpdateEvent event) {
    final zoom = event.loadZoomOverride ?? mapState.zoom;
    final center = event.loadCenterOverride ?? mapState.center;
    final tileZoom = _clampToNativeZoom(zoom);
    final visibleTileRange = _tileRangeCalculator.calculate(
      mapState: mapState,
      tileZoom: tileZoom,
      center: center,
      viewingZoom: zoom,
    );

    if (event.load) {
      if (!_outsideZoomLimits(tileZoom)) _loadTiles(visibleTileRange);
    }

    if (event.prune) {
      _tileImageManager.evictErrorTiles(
          visibleTileRange, widget.evictErrorTileStrategy);
      _tileImageManager.prune(widget.evictErrorTileStrategy);
    }
  }

  // Load new tiles in the visible bounds and prune those outside.
  void _loadAndPruneInVisibleBounds(FlutterMapState mapState) {
    final tileZoom = _clampToNativeZoom(mapState.zoom);
    final visibleTileRange = _tileRangeCalculator.calculate(
      mapState: mapState,
      tileZoom: tileZoom,
    );

    if (!_outsideZoomLimits(tileZoom)) _loadTiles(visibleTileRange);

    _tileImageManager.evictErrorTiles(
        visibleTileRange, widget.evictErrorTileStrategy);
    _tileImageManager.prune(widget.evictErrorTileStrategy);
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
  void _loadTiles(DiscreteTileRange tileLoadRange) {
    final tileZoom = tileLoadRange.zoom;
    tileLoadRange = tileLoadRange.expand(widget.panBuffer);

    // Mark tiles outside of the tile load range as no longer current.
    _tileImageManager.markAsNoLongerCurrentOutside(
      tileZoom,
      tileLoadRange.expand(widget.keepBuffer),
    );

    // Build the queue of tiles to load. Marks all tiles with valid coordinates
    // in the tileLoadRange as current.
    final tileBoundsAtZoom = _tileBounds.atZoom(tileZoom);
    final tilesToLoad = _tileImageManager.setCurrentAndReturnNotLoadedTiles(
        tileBoundsAtZoom.validCoordinatesIn(tileLoadRange),
        createTile: (coordinates) =>
            _createTileImage(coordinates, tileBoundsAtZoom));

    // Re-order the tiles by their distance to the center of the range.
    final tileCenter = tileLoadRange.center;
    tilesToLoad.sort(
      (a, b) => a.coordinates
          .distanceTo(tileCenter)
          .compareTo(b.coordinates.distanceTo(tileCenter)),
    );

    // Create the new Tiles.
    for (final tile in tilesToLoad) {
      tile.load();
    }
  }

  // Rounds the zoom to the nearest int and clamps it to the native zoom limits
  // if there are any.
  int _clampToNativeZoom(double zoom) {
    int result = zoom.round();

    if (widget.minNativeZoom != null) {
      result = math.max(result, widget.minNativeZoom!);
    }
    if (widget.maxNativeZoom != null) {
      result = math.min(result, widget.maxNativeZoom!);
    }

    return result;
  }

  void _onTileLoadError(TileImage tile, Object error, StackTrace? stackTrace) {
    debugPrint(error.toString());
    widget.errorTileCallback?.call(tile, error, stackTrace);
  }

  // This is called whether the tile loads successfully or with an error.
  void _onTileLoadComplete(TileCoordinates coordinates) {
    if (!_tileImageManager.containsTileAt(coordinates) ||
        !_tileImageManager.allLoaded) {
      return;
    }

    widget._tileTransition.when(instantaneous: (_) {
      _tileImageManager.prune(widget.evictErrorTileStrategy);
    }, faded: (faded) {
      // Wait a bit more than tileFadeInDuration to trigger a pruning so that
      // we don't see tile removal under a fading tile.
      _pruneLater?.cancel();
      _pruneLater = Timer(
        faded.duration + const Duration(milliseconds: 50),
        () => _tileImageManager.prune(widget.evictErrorTileStrategy),
      );
    });
  }

  bool _outsideZoomLimits(num zoom) =>
      zoom < widget.minZoom || zoom > widget.maxZoom;

  // A workaround for the fact that FlutterMapState size initialization has a
  // race condition where sometimes the size is set to CustomPoint(0,0) before
  // it is set to the correct value. When this occurs, code that relies on the
  // visible bounds will not work correctly. Sometimes it requires more than
  // one postFrameCallback to get a non zero size.
  void _tryWaitForSizeToBeInitialized(
    FlutterMapState mapState,
    VoidCallback callback, {
    int retries = 3,
  }) {
    if (retries >= 0 && mapState.size == const CustomPoint(0, 0)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _tryWaitForSizeToBeInitialized(
          mapState,
          callback,
          retries: retries - 1,
        );
      });
    } else {
      callback();
    }
  }
}

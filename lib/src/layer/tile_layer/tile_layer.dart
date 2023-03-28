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
import 'package:flutter_map/src/layer/tile_layer/tile_builder.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_coordinate.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_manager.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_provider/base_tile_provider.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_provider/tile_provider_web.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_range.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_scale_calculator.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_widget.dart';
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

  /// Opacity of the rendered tile
  final double opacity;

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

  /// Tiles fade in duration in milliseconds (default 100). This can be null to
  /// avoid fade in.
  final Duration? tileFadeInDuration;

  /// Opacity start value when Tile starts fade in (0.0 - 1.0) Takes effect if
  /// `tileFadeInDuration` is not null
  final double tileFadeInStart;

  /// Opacity start value when an exists Tile starts fade in with different Url
  /// (0.0 - 1.0) Takes effect when `tileFadeInDuration` is not null and if
  /// `overrideTilesWhenUrlChanges` if true
  final double tileFadeInStartWhenOverride;

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

  /// This callback will be execute if some errors occur when fetching tiles.
  final ErrorTileCallBack? errorTileCallback;

  final TemplateFunction templateFunction;

  /// Function which may Wrap Tile with custom Widget
  /// There are predefined examples in 'tile_builder.dart'
  final TileBuilder? tileBuilder;

  /// Function which may wrap Tiles Container with custom Widget
  /// There are predefined examples in 'tile_builder.dart'
  final TilesContainerBuilder? tilesContainerBuilder;

  // If a Tile was loaded with error and if strategy isn't `none` then TileProvider
  // will be asked to evict Image based on current strategy
  // (see #576 - even Error Images are cached in flutter)
  final EvictErrorTileStrategy evictErrorTileStrategy;

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
  final bool fastReplace;

  /// Stream to notify the [TileLayer] that it needs resetting
  final Stream<void>? reset;

  /// Only load tiles that are within these bounds
  final LatLngBounds? tileBounds;

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
    this.errorImage,
    TileProvider? tileProvider,
    this.tms = false,
    this.wmsOptions,
    this.opacity = 1.0,
    Duration tileFadeInDuration = const Duration(milliseconds: 100),
    this.tileFadeInStart = 0.0,
    this.tileFadeInStartWhenOverride = 0.0,
    this.overrideTilesWhenUrlChanges = false,
    this.retinaMode = false,
    this.errorTileCallback,
    this.templateFunction = util.template,
    this.tileBuilder,
    this.tilesContainerBuilder,
    this.evictErrorTileStrategy = EvictErrorTileStrategy.none,
    this.fastReplace = false,
    this.reset,
    this.tileBounds,
    String userAgentPackageName = 'unknown',
  })  : tileFadeInDuration =
            tileFadeInDuration <= Duration.zero ? null : tileFadeInDuration,
        assert(tileFadeInStart >= 0.0 && tileFadeInStart <= 1.0),
        assert(tileFadeInStartWhenOverride >= 0.0 &&
            tileFadeInStartWhenOverride <= 1.0),
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
              });

  @override
  State<StatefulWidget> createState() => _TileLayerState();
}

class _TileLayerState extends State<TileLayer> with TickerProviderStateMixin {
  bool _initializedFromMapState = false;

  late TileBounds _tileBounds;
  late TileScaleCalculator _tileScaleCalculator;

  int? _tileZoom;

  StreamSubscription<MapEvent>? _movementSubscription;
  StreamSubscription<void>? _resetSub;

  late final TileManager _tileManager;

  Timer? _pruneLater;

  @override
  void initState() {
    super.initState();
    _tileManager = TileManager();

    if (widget.reset != null) {
      _resetSub = widget.reset?.listen(
        (_) => _tileManager.removeAll(
          widget.evictErrorTileStrategy,
        ),
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final mapState = FlutterMapState.maybeOf(context)!;

    _movementSubscription?.cancel();
    _movementSubscription = mapState.mapController.mapEventStream.listen(
      (mapEvent) => _loadAndPruneTiles(mapState),
    );

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
      _loadAndPruneTiles(mapState);
    }

    _initializedFromMapState = true;
  }

  @override
  void didUpdateWidget(TileLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    var reloadTiles = false;

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

    reloadTiles |= !_tileManager.allWithinZoom(widget.minZoom, widget.maxZoom);

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
          _tileManager.reloadImages(widget, _tileBounds);
        } else {
          reloadTiles = true;
        }
      }
    }

    if (reloadTiles) {
      _tileManager.removeAll(widget.evictErrorTileStrategy);
      _loadAndPruneTiles(FlutterMapState.maybeOf(context)!);
    }
  }

  @override
  void dispose() {
    _movementSubscription?.cancel();
    _tileManager.removeAll(widget.evictErrorTileStrategy);
    _resetSub?.cancel();
    _pruneLater?.cancel();
    widget.tileProvider.dispose();

    super.dispose();
  }

  void _loadAndPruneTiles(FlutterMapState mapState) {
    _tileZoom = _clampToNativeZoom(mapState.zoom.round());

    if (_outsideZoomLimits(_tileZoom!)) {
      _tileZoom = null;
    } else {
      _update(mapState, _tileZoom!);
    }

    _pruneTiles();
  }

  @override
  Widget build(BuildContext context) {
    final map = FlutterMapState.maybeOf(context)!;
    final roundedMapZoom = map.zoom.round();
    if (_outsideZoomLimits(roundedMapZoom)) {
      return const SizedBox.shrink();
    }

    final tileZoom = _clampToNativeZoom(roundedMapZoom);
    final tilesToRender = _tileManager.sortedByDistanceToZoomAscending(
      widget.maxZoom,
      tileZoom,
    );

    _tileScaleCalculator.clearCacheUnlessZoomMatches(map.zoom);
    final tileWidgets = <Widget>[
      for (var tile in tilesToRender)
        AnimatedTile(
          key: ValueKey(tile.coordsKey),
          tile: tile,
          currentPixelOrigin: map.pixelOrigin,
          scaledTileSize: _tileScaleCalculator.scaledTileSize(
            map.zoom,
            tile.coordinate.z,
          ),
          errorImage: widget.errorImage,
          tileBuilder: widget.tileBuilder,
        )
    ];

    return Opacity(
      opacity: widget.opacity,
      child: Container(
        color: widget.backgroundColor,
        child: Stack(
          children: tileWidgets,
        ),
      ),
    );
  }

  int _clampToNativeZoom(int zoom) {
    if (widget.minNativeZoom != null) {
      zoom = math.max(zoom, widget.minNativeZoom!);
    }
    if (widget.maxNativeZoom != null) {
      zoom = math.min(zoom, widget.maxNativeZoom!);
    }

    return zoom;
  }

  // Load tiles in the grid's active zoom level according to map bounds
  void _update(FlutterMapState map, int tileZoom) {
    _tileManager.abortLoading(_tileZoom, widget.evictErrorTileStrategy);

    final tileLoadRange = DiscreteTileRange.fromPixelBounds(
      zoom: tileZoom,
      tileSize: widget.tileSize,
      pixelBounds: _visiblePixelBoundsAtZoom(map, tileZoom.toDouble()),
    )..expand(widget.panBuffer);

    // Mark tiles for pruning.
    _tileManager.markToPrune(
      tileZoom,
      tileLoadRange.expand(widget.keepBuffer),
    );

    // Build the queue of tiles to load. Unmarks queued tiles for pruning.
    final tileBoundsAtZoom = _tileBounds.atZoom(tileZoom);
    final queue = tileBoundsAtZoom
        .validCoordinatesIn(tileLoadRange)
        .where((coord) => !_tileManager.markTileWithCoordsAsCurrent(coord))
        .toList();

    // Evict tiles which have been marked for pruning.
    _tileManager.evictErrorTilesBasedOnStrategy(
      tileLoadRange,
      widget.evictErrorTileStrategy,
    );

    // Sort the queued tiles by their distance to the center.
    final tileCenter = tileLoadRange.center;
    queue.sort(
      (a, b) => a.distanceTo(tileCenter).compareTo(b.distanceTo(tileCenter)),
    );

    // Create the new Tiles.
    for (final coords in queue) {
      _tileManager.add(
        coords,
        Tile(
          coordinate: coords,
          current: true,
          imageProvider: widget.tileProvider.getImage(
            tileBoundsAtZoom.wrap(coords),
            widget,
          ),
          tileReady: _tileReady,
          vsync: this,
          duration: widget.tileFadeInDuration,
        ),
      );
    }
  }

  /// Returns the bounds of the visible pixels at the target [zoom].
  Bounds<num> _visiblePixelBoundsAtZoom(FlutterMapState map, double zoom) {
    final scale = map.getZoomScale(map.zoom, zoom);
    final pixelCenter = map.project(map.center, zoom).floor();
    final halfSize = map.size / (scale * 2);

    return Bounds(pixelCenter - halfSize, pixelCenter + halfSize);
  }

  void _tileReady(TileCoordinate tileCoords, dynamic error, Tile? tile) {
    if (null != error) {
      debugPrint(error.toString());

      tile!.loadError = true;

      if (widget.errorTileCallback != null) {
        widget.errorTileCallback!(tile, error);
      }
    } else {
      tile!.loadError = false;
    }

    tile = _tileManager.tileAt(tile.coordinate);
    if (tile == null) return;

    if (widget.fastReplace && mounted) {
      setState(() {
        tile!.active = true;

        if (_tileManager.allLoaded) {
          // We're not waiting for anything, prune the tiles immediately.
          _pruneTiles();
        }
      });
      return;
    }

    final fadeInStart = tile.loaded == null
        ? widget.tileFadeInStart
        : widget.tileFadeInStartWhenOverride;
    tile.loaded = DateTime.now();
    if (widget.tileFadeInDuration == null ||
        fadeInStart == 1.0 ||
        (tile.loadError && null == widget.errorImage)) {
      tile.active = true;
    } else {
      tile.startFadeInAnimation(from: fadeInStart);
    }

    if (mounted) {
      setState(() {});
    }

    if (_tileManager.allLoaded) {
      // Wait a bit more than tileFadeInDuration (the duration of the tile
      // fade-in) to trigger a pruning.
      _pruneLater?.cancel();
      _pruneLater = Timer(
        widget.tileFadeInDuration != null
            ? widget.tileFadeInDuration! + const Duration(milliseconds: 50)
            : const Duration(milliseconds: 50),
        () {
          if (mounted) {
            setState(() {
              _pruneTiles();
            });
          }
        },
      );
    }
  }

  void _pruneTiles() {
    if (_tileZoom == null) {
      _tileManager.removeAll(widget.evictErrorTileStrategy);
    } else {
      _tileManager.prune(widget.evictErrorTileStrategy);
    }
  }

  bool _outsideZoomLimits(num zoom) =>
      zoom < widget.minZoom || zoom > widget.maxZoom;
}

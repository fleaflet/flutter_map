import 'dart:async';
import 'dart:math' as math;

import 'package:collection/collection.dart' show MapEquality;
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/core/bounds.dart';
import 'package:flutter_map/src/core/util.dart' as util;
import 'package:flutter_map/src/layer/tile_layer/level.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_manager.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_transformation.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_widget.dart';
import 'package:flutter_map/src/layer/tile_layer/transformation_calculator.dart';
import 'package:flutter_map/src/map/flutter_map_state.dart';
import 'package:latlong2/latlong.dart';
import 'package:tuple/tuple.dart';

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

  /// Follows the same structure as [urlTemplate]. If precised, this URL is used
  /// only if an error occurs when loading the [urlTemplate].
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
  final double? minNativeZoom;

  /// Maximum zoom number the tile source has available. If it is specified, the
  /// tiles on all zoom levels higher than maxNativeZoom will be loaded from
  /// maxNativeZoom level and auto-scaled.
  final double? maxNativeZoom;

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

  /// Tiles will not update more than once every `updateInterval` (default 200
  /// milliseconds) when panning. It can be null (but it will calculating for
  /// loading tiles every frame when panning / zooming, flutter is fast) This
  /// can save some fps and even bandwidth (ie. when fast panning / animating
  /// between long distances in short time)
  final Duration? updateInterval;

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
    this.backgroundColor = const Color(0xFFE0E0E0),
    this.errorImage,
    TileProvider? tileProvider,
    this.tms = false,
    this.wmsOptions,
    this.opacity = 1.0,

    /// Tiles will not update more than once every `updateInterval` milliseconds
    /// (default 200) when panning. It can be 0 (but it will calculating for
    /// loading tiles every frame when panning / zooming, flutter is fast) This
    /// can save some fps and even bandwidth (ie. when fast panning / animating
    /// between long distances in short time)
    Duration updateInterval = const Duration(milliseconds: 200),
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
  })  : updateInterval =
            updateInterval <= Duration.zero ? null : updateInterval,
        tileFadeInDuration =
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
  late Bounds _globalTileRange;
  Tuple2<double, double>? _wrapX;
  Tuple2<double, double>? _wrapY;
  double? _tileZoom;

  StreamSubscription<void>? _resetSub;
  StreamController<LatLng?>? _throttleUpdate;
  late CustomPoint _tileSize;

  late final TileManager _tileManager;
  late final TransformationCalculator _transformationCalculator;

  Timer? _pruneLater;

  @override
  void initState() {
    super.initState();
    _tileManager = TileManager();
    _transformationCalculator = TransformationCalculator();
    _tileSize = CustomPoint(widget.tileSize, widget.tileSize);

    if (widget.reset != null) {
      _resetSub = widget.reset?.listen((_) => _resetTiles());
    }

    //TODO fix
    // _initThrottleUpdate();
  }

  @override
  void didUpdateWidget(TileLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    var reloadTiles = false;

    if (oldWidget.tileSize != widget.tileSize) {
      _tileSize = CustomPoint(widget.tileSize, widget.tileSize);
      reloadTiles = true;
    }

    if (oldWidget.retinaMode != widget.retinaMode) {
      reloadTiles = true;
    }

    reloadTiles |= !_tileManager.allWithinZoom(widget.minZoom, widget.maxZoom);

    if (oldWidget.updateInterval != widget.updateInterval) {
      _throttleUpdate?.close();
      //TODO fix
      // _initThrottleUpdate();
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
          _tileManager.reloadImages(widget, _wrapX, _wrapY);
        } else {
          reloadTiles = true;
        }
      }
    }

    if (reloadTiles) {
      _tileManager.removeAll(widget.evictErrorTileStrategy);
    }
  }

//TODO fix
  // void _initThrottleUpdate() {
  //   if (widget.updateInterval == null) {
  //     _throttleUpdate = null;
  //   } else {
  //     _throttleUpdate = StreamController<LatLng?>(sync: true);
  //     _throttleUpdate!.stream
  //         .transform(
  //           util.throttleStreamTransformerWithTrailingCall<LatLng?>(
  //             widget.updateInterval!,
  //           ),
  //         )
  //         .listen(_update);
  //   }
  // }

  @override
  void dispose() {
    _tileManager.removeAll(widget.evictErrorTileStrategy);
    _resetSub?.cancel();
    _pruneLater?.cancel();
    widget.tileProvider.dispose();
    _throttleUpdate?.close();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final map = FlutterMapState.maybeOf(context)!;

    //Handle movement
    final tileZoom = _clampZoom(map.zoom.roundToDouble());

    if (_tileZoom == null) {
      // if there is no _tileZoom available it means we are out within zoom level
      // we will restore fully via _setView call if we are back on trail
      if ((tileZoom <= widget.maxZoom) && (tileZoom >= widget.minZoom)) {
        _tileZoom = tileZoom;
        _setView(map, map.center, tileZoom);
      }
    } else {
      if ((tileZoom - _tileZoom!).abs() >= 1) {
        // It was a zoom lvl change
        _setView(map, map.center, tileZoom);
      } else {
        if (_throttleUpdate == null) {
          //TODO what is this for?
          // _update(null);
        } else {
          _throttleUpdate!.add(null);
        }
      }
    }

    _setView(map, map.center, map.zoom);

    final tilesToRender = _tileZoom == null
        ? _tileManager.all()
        : _tileManager.sortedByDistanceToZoomAscending(
            widget.maxZoom, _tileZoom!);
    final Map<double, TileTransformation> zoomToTransformation = {};

    final tileWidgets = <Widget>[
      for (var tile in tilesToRender)
        TileWidget(
          tile: tile,
          size: _tileSize,
          tileTransformation: zoomToTransformation[tile.coords.z] ??
              (zoomToTransformation[tile.coords.z] =
                  _transformationCalculator.transformationFor(
                tile.coords.z,
                map,
              )),
          errorImage: widget.errorImage,
          tileBuilder: widget.tileBuilder,
          key: ValueKey(tile.coordsKey),
        )
    ];

    final tilesContainer = Stack(
      children: tileWidgets,
    );

    final tilesLayer = widget.tilesContainerBuilder == null
        ? tilesContainer
        : widget.tilesContainerBuilder!(
            context,
            tilesContainer,
            tilesToRender,
          );

    return Opacity(
      opacity: widget.opacity,
      child: Container(
        color: widget.backgroundColor,
        child: tilesLayer,
      ),
    );
  }

  CustomPoint getTileSize() => _tileSize;

  Level? _updateLevels(FlutterMapState map) {
    final zoom = _tileZoom;

    if (zoom == null) return null;

    final toRemove = _transformationCalculator.whereLevel((levelZoom) =>
        levelZoom != zoom && !_tileManager.anyWithZoomLevel(levelZoom));

    for (final z in toRemove) {
      _tileManager.removeAtZoom(z, widget.evictErrorTileStrategy);
      _transformationCalculator.removeLevel(z);
    }

    return _transformationCalculator.getOrCreateLevel(zoom, map);
  }

  ///removes all loaded tiles and resets the view
  void _resetTiles() {
    _tileManager.removeAll(widget.evictErrorTileStrategy);
  }

  double _clampZoom(double zoom) {
    if (null != widget.minNativeZoom && zoom < widget.minNativeZoom!) {
      return widget.minNativeZoom!;
    }

    if (null != widget.maxNativeZoom && widget.maxNativeZoom! < zoom) {
      return widget.maxNativeZoom!;
    }

    return zoom;
  }

  void _setView(FlutterMapState map, LatLng center, double zoom) {
    double? tileZoom = _clampZoom(zoom.roundToDouble());
    if ((tileZoom > widget.maxZoom) || (tileZoom < widget.minZoom)) {
      tileZoom = null;
    }

    _tileZoom = tileZoom;

    _tileManager.abortLoading(_tileZoom, widget.evictErrorTileStrategy);

    _updateLevels(map);
    _resetGrid(map);

    if (_tileZoom != null) {
      _update(map, center);
    }

    _tileManager.prune(_tileZoom, widget.evictErrorTileStrategy);
  }

  void _resetGrid(FlutterMapState map) {
    final crs = map.options.crs;
    final tileSize = getTileSize();
    final tileZoom = _tileZoom;

    final bounds = map.getPixelWorldBounds(_tileZoom);
    if (bounds != null) {
      _globalTileRange = _pxBoundsToTileRange(bounds);
    }

    // wrapping
    _wrapX = crs.wrapLng;
    if (_wrapX != null) {
      final first =
          (map.project(LatLng(0, crs.wrapLng!.item1), tileZoom).x / tileSize.x)
              .floorToDouble();
      final second =
          (map.project(LatLng(0, crs.wrapLng!.item2), tileZoom).x / tileSize.y)
              .ceilToDouble();
      _wrapX = Tuple2(first, second);
    }

    _wrapY = crs.wrapLat;
    if (_wrapY != null) {
      final first =
          (map.project(LatLng(crs.wrapLat!.item1, 0), tileZoom).y / tileSize.x)
              .floorToDouble();
      final second =
          (map.project(LatLng(crs.wrapLat!.item2, 0), tileZoom).y / tileSize.y)
              .ceilToDouble();
      _wrapY = Tuple2(first, second);
    }
  }

  Bounds _getTiledPixelBounds(FlutterMapState map, LatLng center) {
    final scale = map.getZoomScale(map.zoom, _tileZoom);
    final pixelCenter = map.project(center, _tileZoom).floor();
    final halfSize = map.size / (scale * 2);

    return Bounds(pixelCenter - halfSize, pixelCenter + halfSize);
  }

  // Private method to load tiles in the grid's active zoom level according to
  // map bounds
  void _update(FlutterMapState map, LatLng? center) {
    if (_tileZoom == null) {
      return;
    }

    final zoom = _clampZoom(map.zoom);
    center ??= map.center;

    final pixelBounds = _getTiledPixelBounds(map, center);
    final tileRange = _pxBoundsToTileRange(pixelBounds);
    final tileCenter = tileRange.center;
    final queue = <Coords<double>>[];
    final margin = widget.keepBuffer;
    final noPruneRange = Bounds(
      tileRange.bottomLeft - CustomPoint(margin, -margin),
      tileRange.topRight + CustomPoint(margin, -margin),
    );

    _tileManager.markToPrune(_tileZoom, noPruneRange);

    // _update just loads more tiles. If the tile zoom level differs too much
    // from the map's, let _setView reset levels and prune old tiles.
    if ((zoom - _tileZoom!).abs() > 1) {
      _setView(map, center, zoom);
      return;
    }

    // create a queue of coordinates to load tiles from
    for (var j = tileRange.min.y; j <= tileRange.max.y; j++) {
      for (var i = tileRange.min.x; i <= tileRange.max.x; i++) {
        final coords = Coords(i.toDouble(), j.toDouble());
        coords.z = _tileZoom!;

        if (widget.tileBounds != null) {
          final tilePxBounds = _pxBoundsToTileRange(
              _latLngBoundsToPixelBounds(map, widget.tileBounds!, _tileZoom!));
          if (!_areCoordsInsideTileBounds(coords, tilePxBounds)) {
            continue;
          }
        }

        if (!_isValidTile(map.options.crs, coords)) {
          continue;
        }

        if (!_tileManager.markTileWithCoordsAsCurrent(coords)) {
          queue.add(coords);
        }
      }
    }

    _tileManager.evictErrorTilesBasedOnStrategy(
        tileRange, widget.evictErrorTileStrategy);

    // sort tile queue to load tiles in order of their distance to center
    queue.sort((a, b) =>
        (a.distanceTo(tileCenter) - b.distanceTo(tileCenter)).toInt());

    for (final coords in queue) {
      final newTile = Tile(
        coords: coords,
        tilePos: _getTilePos(map, coords),
        current: true,
        imageProvider:
            widget.tileProvider.getImage(coords.wrap(_wrapX, _wrapY), widget),
        tileReady: _tileReady,
      );

      _tileManager.add(coords, newTile);
      // If we do this before adding the Tile to the TileManager the _tileReady
      // callback may be fired very fast and we won't find the Tile in the
      // TileManager since it's not added yet.
      newTile.loadTileImage();
    }
  }

  bool _isValidTile(Crs crs, Coords coords) {
    if (!crs.infinite) {
      // don't load tile if it's out of bounds and not wrapped
      final bounds = _globalTileRange;
      if ((crs.wrapLng == null &&
              (coords.x < bounds.min.x || coords.x > bounds.max.x)) ||
          (crs.wrapLat == null &&
              (coords.y < bounds.min.y || coords.y > bounds.max.y))) {
        return false;
      }
    }

    return true;
  }

  bool _areCoordsInsideTileBounds(Coords coords, Bounds? tileBounds) {
    final bounds = tileBounds ?? _globalTileRange;
    if ((coords.x < bounds.min.x || coords.x > bounds.max.x) ||
        (coords.y < bounds.min.y || coords.y > bounds.max.y)) {
      return false;
    }
    return true;
  }

  Bounds _latLngBoundsToPixelBounds(
      FlutterMapState map, LatLngBounds bounds, double thisZoom) {
    final swPixel = map.project(bounds.southWest!, thisZoom).floor();
    final nePixel = map.project(bounds.northEast!, thisZoom).ceil();
    final pxBounds = Bounds(swPixel, nePixel);
    return pxBounds;
  }

  void _tileReady(Coords<double> coords, dynamic error, Tile? tile) {
    if (null != error) {
      debugPrint(error.toString());

      tile!.loadError = true;

      if (widget.errorTileCallback != null) {
        widget.errorTileCallback!(tile, error);
      }
    } else {
      tile!.loadError = false;
    }

    tile = _tileManager.tileAt(tile.coords);
    if (tile == null) return;

    if (widget.fastReplace && mounted) {
      setState(() {
        tile!.active = true;

        if (_tileManager.allLoaded) {
          // We're not waiting for anything, prune the tiles immediately.
          _tileManager.prune(_tileZoom, widget.evictErrorTileStrategy);
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
      tile.startFadeInAnimation(
        widget.tileFadeInDuration!,
        this,
        from: fadeInStart,
      );
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
              _tileManager.prune(_tileZoom, widget.evictErrorTileStrategy);
            });
          }
        },
      );
    }
  }

  CustomPoint _getTilePos(FlutterMapState map, Coords coords) {
    final level =
        _transformationCalculator.getOrCreateLevel(coords.z as double, map);
    return coords.scaleBy(getTileSize()) - level.origin;
  }

  Bounds _pxBoundsToTileRange(Bounds bounds) {
    final tileSize = getTileSize();
    return Bounds(
      bounds.min.unscaleBy(tileSize).floor(),
      bounds.max.unscaleBy(tileSize).ceil() - const CustomPoint(1, 1),
    );
  }
}

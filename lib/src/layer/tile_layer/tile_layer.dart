import 'dart:async';
import 'dart:math' as math;

import 'package:collection/collection.dart' show MapEquality;
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/core/bounds.dart';
import 'package:flutter_map/src/core/util.dart' as util;
import 'package:flutter_map/src/layer/tile_layer/animated_tile.dart';
import 'package:flutter_map/src/layer/tile_layer/coords.dart';
import 'package:flutter_map/src/layer/tile_layer/level.dart';
import 'package:flutter_map/src/map/map.dart';
import 'package:latlong2/latlong.dart';
import 'package:tuple/tuple.dart';

part 'tile_layer_options.dart';

class TileLayerWidget extends StatelessWidget {
  final TileLayerOptions options;

  const TileLayerWidget({Key? key, required this.options}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final mapState = MapState.maybeOf(context)!;

    return TileLayer(
      mapState: mapState,
      stream: mapState.onMoved,
      options: options,
    );
  }
}

class TileLayer extends StatefulWidget {
  final TileLayerOptions options;
  final MapState mapState;
  final Stream<void> stream;

  TileLayer({
    required this.options,
    required this.mapState,
    required this.stream,
  }) : super(key: options.key);

  @override
  State<StatefulWidget> createState() {
    return _TileLayerState();
  }
}

class _TileLayerState extends State<TileLayer> with TickerProviderStateMixin {
  MapState get map => widget.mapState;

  TileLayerOptions get options => widget.options;
  late Bounds _globalTileRange;
  Tuple2<double, double>? _wrapX;
  Tuple2<double, double>? _wrapY;
  double? _tileZoom;

  //ignore: unused_field
  Level? _level;
  StreamSubscription? _moveSub;
  StreamSubscription? _resetSub;
  StreamController<LatLng?>? _throttleUpdate;
  late CustomPoint _tileSize;

  final Map<String, Tile> _tiles = {};
  final Map<double, Level> _levels = {};

  Timer? _pruneLater;

  @override
  void initState() {
    super.initState();
    _tileSize = CustomPoint(options.tileSize, options.tileSize);
    _resetView();
    _update(null);
    _moveSub = widget.stream.listen((_) => _handleMove());

    if (options.reset != null) {
      _resetSub = options.reset?.listen((_) => _resetTiles());
    }

    _initThrottleUpdate();
  }

  @override
  void didUpdateWidget(TileLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    var reloadTiles = false;

    if (oldWidget.options.tileSize != options.tileSize) {
      _tileSize = CustomPoint(options.tileSize, options.tileSize);
      reloadTiles = true;
    }

    if (oldWidget.options.retinaMode != options.retinaMode) {
      reloadTiles = true;
    }

    reloadTiles |= _isZoomOutsideMinMax();

    if (oldWidget.options.updateInterval != options.updateInterval) {
      _throttleUpdate?.close();
      _initThrottleUpdate();
    }

    if (!reloadTiles) {
      final oldUrl = oldWidget.options.wmsOptions?._encodedBaseUrl ??
          oldWidget.options.urlTemplate;
      final newUrl = options.wmsOptions?._encodedBaseUrl ?? options.urlTemplate;

      final oldOptions = oldWidget.options.additionalOptions;
      final newOptions = options.additionalOptions;

      if (oldUrl != newUrl ||
          !(const MapEquality<String, String>())
              .equals(oldOptions, newOptions)) {
        if (options.overrideTilesWhenUrlChanges) {
          for (final tile in _tiles.values) {
            tile.imageProvider = options.tileProvider
                .getImage(_wrapCoords(tile.coords), options);
            tile.loadTileImage();
          }
        } else {
          reloadTiles = true;
        }
      }
    }

    if (reloadTiles) {
      _removeAllTiles();
      _resetView();
      _update(null);
    }
  }

  bool _isZoomOutsideMinMax() {
    for (final tile in _tiles.values) {
      if (tile.level.zoom > (options.maxZoom) ||
          tile.level.zoom < (options.minZoom)) {
        return true;
      }
    }
    return false;
  }

  void _initThrottleUpdate() {
    if (options.updateInterval == null) {
      _throttleUpdate = null;
    } else {
      _throttleUpdate = StreamController<LatLng?>(sync: true);
      _throttleUpdate!.stream
          .transform(
            util.throttleStreamTransformerWithTrailingCall<LatLng?>(
              options.updateInterval!,
            ),
          )
          .listen(_update);
    }
  }

  @override
  void dispose() {
    _removeAllTiles();
    _resetSub?.cancel();
    _moveSub?.cancel();
    _pruneLater?.cancel();
    options.tileProvider.dispose();
    _throttleUpdate?.close();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tilesToRender = _tiles.values.toList()..sort();

    final tileWidgets = <Widget>[
      for (var tile in tilesToRender) _createTileWidget(tile)
    ];

    final tilesContainer = Stack(
      children: tileWidgets,
    );

    final tilesLayer = options.tilesContainerBuilder == null
        ? tilesContainer
        : options.tilesContainerBuilder!(
            context,
            tilesContainer,
            tilesToRender,
          );

    final attributionLayer = widget.options.attributionBuilder?.call(context);

    return Opacity(
      opacity: options.opacity,
      child: Container(
        color: options.backgroundColor,
        child: Stack(
          alignment: widget.options.attributionAlignment,
          children: [
            tilesLayer,
            if (attributionLayer != null) attributionLayer,
          ],
        ),
      ),
    );
  }

  Widget _createTileWidget(Tile tile) {
    final tilePos = tile.tilePos;
    final level = tile.level;
    final tileSize = getTileSize();
    final pos = (tilePos).multiplyBy(level.scale) + level.translatePoint;
    final num width = tileSize.x * level.scale;
    final num height = tileSize.y * level.scale;

    final Widget content = AnimatedTile(
      tile: tile,
      errorImage: options.errorImage,
      tileBuilder: options.tileBuilder,
    );

    return Positioned(
      key: ValueKey(tile.coordsKey),
      left: pos.x.toDouble(),
      top: pos.y.toDouble(),
      width: width.toDouble(),
      height: height.toDouble(),
      child: content,
    );
  }

  void _abortLoading() {
    final toRemove = <String>[];
    for (final entry in _tiles.entries) {
      final tile = entry.value;

      if (tile.coords.z != _tileZoom) {
        if (tile.loaded == null) {
          toRemove.add(entry.key);
        }
      }
    }

    for (final key in toRemove) {
      final tile = _tiles[key]!;

      tile.tileReady = null;
      tile.dispose(tile.loadError &&
          options.evictErrorTileStrategy != EvictErrorTileStrategy.none);
      _tiles.remove(key);
    }
  }

  CustomPoint getTileSize() {
    return _tileSize;
  }

  bool _hasLevelChildren(double lvl) {
    for (final tile in _tiles.values) {
      if (tile.coords.z == lvl) {
        return true;
      }
    }

    return false;
  }

  Level? _updateLevels() {
    final zoom = _tileZoom;
    final maxZoom = options.maxZoom;

    if (zoom == null) return null;

    final toRemove = <double>[];
    for (final entry in _levels.entries) {
      final z = entry.key;
      final lvl = entry.value;

      if (z == zoom || _hasLevelChildren(z)) {
        lvl.zIndex = maxZoom - (zoom - z).abs();
      } else {
        toRemove.add(z);
      }
    }

    for (final z in toRemove) {
      _removeTilesAtZoom(z);
      _levels.remove(z);
    }

    var level = _levels[zoom];
    final map = this.map;

    if (level == null) {
      level = _levels[zoom] = Level();
      level.zIndex = maxZoom;
      level.origin = map.project(map.unproject(map.getPixelOrigin()), zoom);
      level.zoom = zoom;

      _setZoomTransform(level, map.center, map.zoom);
    }

    return _level = level;
  }

  void _pruneTiles() {
    final zoom = _tileZoom;
    if (zoom == null) {
      _removeAllTiles();
      return;
    }

    for (final entry in _tiles.entries) {
      final tile = entry.value;
      tile.retain = tile.current;
    }

    for (final entry in _tiles.entries) {
      final tile = entry.value;

      if (tile.current && !tile.active) {
        final coords = tile.coords;
        if (!_retainParent(coords.x, coords.y, coords.z, coords.z - 5)) {
          _retainChildren(coords.x, coords.y, coords.z, coords.z + 2);
        }
      }
    }

    final toRemove = <String>[];
    for (final entry in _tiles.entries) {
      final tile = entry.value;

      if (!tile.retain) {
        toRemove.add(entry.key);
      }
    }

    for (final key in toRemove) {
      _removeTile(key);
    }
  }

  void _removeTilesAtZoom(double zoom) {
    final toRemove = <String>[];
    for (final entry in _tiles.entries) {
      if (entry.value.coords.z != zoom) {
        continue;
      }
      toRemove.add(entry.key);
    }

    for (final key in toRemove) {
      _removeTile(key);
    }
  }

  ///removes all loaded tiles and resets the view
  void _resetTiles() {
    _removeAllTiles();
    _resetView();
  }

  void _removeAllTiles() {
    final toRemove = Map<String, Tile>.from(_tiles);

    for (final key in toRemove.keys) {
      _removeTile(key);
    }
  }

  bool _retainParent(double x, double y, double z, double minZoom) {
    final x2 = (x / 2).floorToDouble();
    final y2 = (y / 2).floorToDouble();
    final z2 = z - 1;
    final coords2 = Coords(x2, y2);
    coords2.z = z2;

    final key = _tileCoordsToKey(coords2);

    final tile = _tiles[key];
    if (tile != null) {
      if (tile.active) {
        tile.retain = true;
        return true;
      } else if (tile.loaded != null) {
        tile.retain = true;
      }
    }

    if (z2 > minZoom) {
      return _retainParent(x2, y2, z2, minZoom);
    }

    return false;
  }

  void _retainChildren(double x, double y, double z, double maxZoom) {
    for (var i = 2 * x; i < 2 * x + 2; i++) {
      for (var j = 2 * y; j < 2 * y + 2; j++) {
        final coords = Coords(i, j);
        coords.z = z + 1;

        final key = _tileCoordsToKey(coords);

        final tile = _tiles[key];
        if (tile != null) {
          if (tile.active) {
            tile.retain = true;
            continue;
          } else if (tile.loaded != null) {
            tile.retain = true;
          }
        }

        if (z + 1 < maxZoom) {
          _retainChildren(i, j, z + 1, maxZoom);
        }
      }
    }
  }

  void _resetView() {
    _setView(map.center, map.zoom);
  }

  double _clampZoom(double zoom) {
    if (null != options.minNativeZoom && zoom < options.minNativeZoom!) {
      return options.minNativeZoom!;
    }

    if (null != options.maxNativeZoom && options.maxNativeZoom! < zoom) {
      return options.maxNativeZoom!;
    }

    return zoom;
  }

  void _setView(LatLng center, double zoom) {
    double? tileZoom = _clampZoom(zoom.roundToDouble());
    if ((tileZoom > options.maxZoom) || (tileZoom < options.minZoom)) {
      tileZoom = null;
    }

    _tileZoom = tileZoom;

    _abortLoading();

    _updateLevels();
    _resetGrid();

    if (_tileZoom != null) {
      _update(center);
    }

    _pruneTiles();
  }

  void _setZoomTransforms(LatLng center, double zoom) {
    for (final i in _levels.keys) {
      _setZoomTransform(_levels[i]!, center, zoom);
    }
  }

  void _setZoomTransform(Level level, LatLng center, double zoom) {
    final scale = map.getZoomScale(zoom, level.zoom);
    final pixelOrigin = map.getNewPixelOrigin(center, zoom).round();
    if (level.origin == null) {
      return;
    }
    final translate = level.origin!.multiplyBy(scale) - pixelOrigin;
    level.translatePoint = translate;
    level.scale = scale;
  }

  void _resetGrid() {
    final map = this.map;
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

  void _handleMove() {
    final tileZoom = _clampZoom(map.zoom.roundToDouble());

    if (_tileZoom == null) {
      // if there is no _tileZoom available it means we are out within zoom level
      // we will restore fully via _setView call if we are back on trail
      if ((tileZoom <= options.maxZoom) && (tileZoom >= options.minZoom)) {
        _tileZoom = tileZoom;
        setState(() {
          _setView(map.center, tileZoom);

          _setZoomTransforms(map.center, map.zoom);
        });
      }
    } else {
      setState(() {
        if ((tileZoom - _tileZoom!).abs() >= 1) {
          // It was a zoom lvl change
          _setView(map.center, tileZoom);

          _setZoomTransforms(map.center, map.zoom);
        } else {
          if (_throttleUpdate == null) {
            _update(null);
          } else {
            _throttleUpdate!.add(null);
          }

          _setZoomTransforms(map.center, map.zoom);
        }
      });
    }
  }

  Bounds _getTiledPixelBounds(LatLng center) {
    final scale = map.getZoomScale(map.zoom, _tileZoom);
    final pixelCenter = map.project(center, _tileZoom).floor();
    final halfSize = map.size / (scale * 2);

    return Bounds(pixelCenter - halfSize, pixelCenter + halfSize);
  }

  // Private method to load tiles in the grid's active zoom level according to
  // map bounds
  void _update(LatLng? center) {
    if (_tileZoom == null) {
      return;
    }

    final zoom = _clampZoom(map.zoom);
    center ??= map.center;

    final pixelBounds = _getTiledPixelBounds(center);
    final tileRange = _pxBoundsToTileRange(pixelBounds);
    final tileCenter = tileRange.center;
    final queue = <Coords<num>>[];
    final margin = options.keepBuffer;
    final noPruneRange = Bounds(
      tileRange.bottomLeft - CustomPoint(margin, -margin),
      tileRange.topRight + CustomPoint(margin, -margin),
    );

    for (final entry in _tiles.entries) {
      final tile = entry.value;
      final c = tile.coords;

      if (tile.current == true &&
          (c.z != _tileZoom || !noPruneRange.contains(CustomPoint(c.x, c.y)))) {
        tile.current = false;
      }
    }

    // _update just loads more tiles. If the tile zoom level differs too much
    // from the map's, let _setView reset levels and prune old tiles.
    if ((zoom - _tileZoom!).abs() > 1) {
      _setView(center, zoom);
      return;
    }

    // create a queue of coordinates to load tiles from
    for (var j = tileRange.min.y; j <= tileRange.max.y; j++) {
      for (var i = tileRange.min.x; i <= tileRange.max.x; i++) {
        final coords = Coords(i.toDouble(), j.toDouble());
        coords.z = _tileZoom!;

        if (options.tileBounds != null) {
          final tilePxBounds = _pxBoundsToTileRange(
              _latLngBoundsToPixelBounds(options.tileBounds!, _tileZoom!));
          if (!_areCoordsInsideTileBounds(coords, tilePxBounds)) {
            continue;
          }
        }

        if (!_isValidTile(coords)) {
          continue;
        }

        final tile = _tiles[_tileCoordsToKey(coords)];
        if (tile != null) {
          tile.current = true;
        } else {
          queue.add(coords);
        }
      }
    }

    _evictErrorTilesBasedOnStrategy(tileRange);

    // sort tile queue to load tiles in order of their distance to center
    queue.sort((a, b) =>
        (a.distanceTo(tileCenter) - b.distanceTo(tileCenter)).toInt());

    for (var i = 0; i < queue.length; i++) {
      _addTile(queue[i] as Coords<double>);
    }
  }

  bool _isValidTile(Coords coords) {
    final crs = map.options.crs;

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

  Bounds _latLngBoundsToPixelBounds(LatLngBounds bounds, double thisZoom) {
    final swPixel = map.project(bounds.southWest!, thisZoom).floor();
    final nePixel = map.project(bounds.northEast!, thisZoom).ceil();
    final pxBounds = Bounds(swPixel, nePixel);
    return pxBounds;
  }

  String _tileCoordsToKey(Coords coords) {
    return '${coords.x}:${coords.y}:${coords.z}';
  }

  //ignore: unused_element
  Coords _keyToTileCoords(String key) {
    final k = key.split(':');
    final coords = Coords(double.parse(k[0]), double.parse(k[1]));
    coords.z = double.parse(k[2]);

    return coords;
  }

  void _removeTile(String key) {
    final tile = _tiles[key];
    if (tile == null) {
      return;
    }

    tile.dispose(tile.loadError &&
        options.evictErrorTileStrategy != EvictErrorTileStrategy.none);
    _tiles.remove(key);
  }

  void _addTile(Coords<double> coords) {
    final tileCoordsToKey = _tileCoordsToKey(coords);
    final tile = _tiles[tileCoordsToKey] = Tile(
      coords: coords,
      coordsKey: tileCoordsToKey,
      tilePos: _getTilePos(coords),
      current: true,
      level: _levels[coords.z]!,
      imageProvider:
          options.tileProvider.getImage(_wrapCoords(coords), options),
      tileReady: _tileReady,
    );

    tile.loadTileImage();
  }

  void _evictErrorTilesBasedOnStrategy(Bounds tileRange) {
    if (options.evictErrorTileStrategy ==
        EvictErrorTileStrategy.notVisibleRespectMargin) {
      final toRemove = <String>[];
      for (final entry in _tiles.entries) {
        final tile = entry.value;

        if (tile.loadError && !tile.current) {
          toRemove.add(entry.key);
        }
      }

      for (final key in toRemove) {
        final tile = _tiles[key]!;

        tile.dispose(true);
        _tiles.remove(key);
      }
    } else if (options.evictErrorTileStrategy ==
        EvictErrorTileStrategy.notVisible) {
      final toRemove = <String>[];
      for (final entry in _tiles.entries) {
        final tile = entry.value;
        final c = tile.coords;

        if (tile.loadError &&
            (!tile.current || !tileRange.contains(CustomPoint(c.x, c.y)))) {
          toRemove.add(entry.key);
        }
      }

      for (final key in toRemove) {
        final tile = _tiles[key]!;

        tile.dispose(true);
        _tiles.remove(key);
      }
    }
  }

  void _tileReady(Coords<double> coords, dynamic error, Tile? tile) {
    if (null != error) {
      debugPrint(error.toString());

      tile!.loadError = true;

      if (options.errorTileCallback != null) {
        options.errorTileCallback!(tile, error);
      }
    } else {
      tile!.loadError = false;
    }

    final key = _tileCoordsToKey(coords);
    tile = _tiles[key];
    if (null == tile) {
      return;
    }

    if (options.fastReplace && mounted) {
      setState(() {
        tile!.active = true;

        if (_noTilesToLoad()) {
          // We're not waiting for anything, prune the tiles immediately.
          _pruneTiles();
        }
      });
      return;
    }

    final fadeInStart = tile.loaded == null
        ? options.tileFadeInStart
        : options.tileFadeInStartWhenOverride;
    tile.loaded = DateTime.now();
    if (options.tileFadeInDuration == null ||
        fadeInStart == 1.0 ||
        (tile.loadError && null == options.errorImage)) {
      tile.active = true;
    } else {
      tile.startFadeInAnimation(
        options.tileFadeInDuration!,
        this,
        from: fadeInStart,
      );
    }

    if (mounted) {
      setState(() {});
    }

    if (_noTilesToLoad()) {
      // Wait a bit more than tileFadeInDuration (the duration of the tile
      // fade-in) to trigger a pruning.
      _pruneLater?.cancel();
      _pruneLater = Timer(
        options.tileFadeInDuration != null
            ? options.tileFadeInDuration! + const Duration(milliseconds: 50)
            : const Duration(milliseconds: 50),
        () {
          if (mounted) {
            setState(_pruneTiles);
          }
        },
      );
    }
  }

  CustomPoint _getTilePos(Coords coords) {
    final level = _levels[coords.z as double]!;
    return coords.scaleBy(getTileSize()) - level.origin!;
  }

  Coords _wrapCoords(Coords coords) {
    final newCoords = Coords(
      _wrapX != null
          ? util.wrapNum(coords.x.toDouble(), _wrapX!)
          : coords.x.toDouble(),
      _wrapY != null
          ? util.wrapNum(coords.y.toDouble(), _wrapY!)
          : coords.y.toDouble(),
    );
    newCoords.z = coords.z.toDouble();
    return newCoords;
  }

  Bounds _pxBoundsToTileRange(Bounds bounds) {
    final tileSize = getTileSize();
    return Bounds(
      bounds.min.unscaleBy(tileSize).floor(),
      bounds.max.unscaleBy(tileSize).ceil() - const CustomPoint(1, 1),
    );
  }

  bool _noTilesToLoad() {
    for (final entry in _tiles.entries) {
      if (entry.value.loaded == null) {
        return false;
      }
    }
    return true;
  }
}

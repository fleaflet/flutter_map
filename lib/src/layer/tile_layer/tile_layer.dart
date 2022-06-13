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
  State<StatefulWidget> createState() => _TileLayerState();
}

class _TileLayerState extends State<TileLayer> with TickerProviderStateMixin {
  MapState get map => widget.mapState;

  TileLayerOptions get options => widget.options;
  late Bounds _globalTileRange;
  Tuple2<double, double>? _wrapX;
  Tuple2<double, double>? _wrapY;
  double? _tileZoom;

  StreamSubscription? _moveSub;
  StreamSubscription? _resetSub;
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

    reloadTiles |=
        !_tileManager.allWithinZoom(options.minZoom, options.maxZoom);

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
          _tileManager.reloadImages(options, _wrapX, _wrapY);
        } else {
          reloadTiles = true;
        }
      }
    }

    if (reloadTiles) {
      _tileManager.removeAll(options.evictErrorTileStrategy);
      _resetView();
      _update(null);
    }
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
    _tileManager.removeAll(options.evictErrorTileStrategy);
    _resetSub?.cancel();
    _moveSub?.cancel();
    _pruneLater?.cancel();
    options.tileProvider.dispose();
    _throttleUpdate?.close();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: widget.stream,
      builder: (context, snapshot) {
        final tilesToRender = _tileZoom == null
            ? _tileManager.all()
            : _tileManager.sortedByDistanceToZoomAscending(
                options.maxZoom, _tileZoom!);
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
              errorImage: options.errorImage,
              tileBuilder: options.tileBuilder,
              key: ValueKey(tile.coordsKey),
            )
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

        final attributionLayer =
            // ignore: deprecated_member_use_from_same_package
            widget.options.attributionBuilder?.call(context);

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
      },
    );
  }

  CustomPoint getTileSize() => _tileSize;

  Level? _updateLevels() {
    final zoom = _tileZoom;

    if (zoom == null) return null;

    final toRemove = _transformationCalculator.whereLevel((levelZoom) =>
        levelZoom != zoom && !_tileManager.anyWithZoomLevel(levelZoom));

    for (final z in toRemove) {
      _tileManager.removeAtZoom(z, options.evictErrorTileStrategy);
      _transformationCalculator.removeLevel(z);
    }

    return _transformationCalculator.getOrCreateLevel(zoom, map);
  }

  ///removes all loaded tiles and resets the view
  void _resetTiles() {
    _tileManager.removeAll(options.evictErrorTileStrategy);
    _resetView();
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

    _tileManager.abortLoading(_tileZoom, options.evictErrorTileStrategy);

    _updateLevels();
    _resetGrid();

    if (_tileZoom != null) {
      _update(center);
    }

    _tileManager.prune(_tileZoom, options.evictErrorTileStrategy);
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
        });
      }
    } else {
      setState(() {
        if ((tileZoom - _tileZoom!).abs() >= 1) {
          // It was a zoom lvl change
          _setView(map.center, tileZoom);
        } else {
          if (_throttleUpdate == null) {
            _update(null);
          } else {
            _throttleUpdate!.add(null);
          }
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
    final queue = <Coords<double>>[];
    final margin = options.keepBuffer;
    final noPruneRange = Bounds(
      tileRange.bottomLeft - CustomPoint(margin, -margin),
      tileRange.topRight + CustomPoint(margin, -margin),
    );

    _tileManager.markToPrune(_tileZoom, noPruneRange);

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

        if (!_tileManager.markTileWithCoordsAsCurrent(coords)) {
          queue.add(coords);
        }
      }
    }

    _tileManager.evictErrorTilesBasedOnStrategy(
        tileRange, options.evictErrorTileStrategy);

    // sort tile queue to load tiles in order of their distance to center
    queue.sort((a, b) =>
        (a.distanceTo(tileCenter) - b.distanceTo(tileCenter)).toInt());

    for (final coords in queue) {
      final newTile = Tile(
        coords: coords,
        tilePos: _getTilePos(coords),
        current: true,
        imageProvider:
            options.tileProvider.getImage(coords.wrap(_wrapX, _wrapY), options),
        tileReady: _tileReady,
      );

      _tileManager.add(coords, newTile);
      // If we do this before adding the Tile to the TileManager the _tileReady
      // callback may be fired very fast and we won't find the Tile in the
      // TileManager since it's not added yet.
      newTile.loadTileImage();
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

    tile = _tileManager.tileAt(tile.coords);
    if (tile == null) return;

    if (options.fastReplace && mounted) {
      setState(() {
        tile!.active = true;

        if (_tileManager.allLoaded) {
          // We're not waiting for anything, prune the tiles immediately.
          _tileManager.prune(_tileZoom, options.evictErrorTileStrategy);
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

    if (_tileManager.allLoaded) {
      // Wait a bit more than tileFadeInDuration (the duration of the tile
      // fade-in) to trigger a pruning.
      _pruneLater?.cancel();
      _pruneLater = Timer(
        options.tileFadeInDuration != null
            ? options.tileFadeInDuration! + const Duration(milliseconds: 50)
            : const Duration(milliseconds: 50),
        () {
          if (mounted) {
            setState(() {
              _tileManager.prune(_tileZoom, options.evictErrorTileStrategy);
            });
          }
        },
      );
    }
  }

  CustomPoint _getTilePos(Coords coords) {
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

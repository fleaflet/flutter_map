import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/core/bounds.dart';
import 'package:flutter_map/src/core/point.dart';
import 'package:flutter_map/src/core/util.dart' as util;
import 'package:flutter_map/src/layer/tile_layer.dart';
import 'package:flutter_map/src/map/map.dart';
import 'package:latlong/latlong.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:tuple/tuple.dart';

class TileLayerWidget extends StatefulWidget {
  final TileLayerOptions options;

  TileLayerWidget({
    Key key,
    @required this.options,
  }) : super(key: key);

  @override
  _TileLayerWidgetState createState() => _TileLayerWidgetState();
}

class _TileLayerWidgetState extends State<TileLayerWidget> {
  TileLayerOptions get options => widget.options;
  Bounds _globalTileRange;
  Tuple2<double, double> _wrapX;
  Tuple2<double, double> _wrapY;
  double _tileZoom;
  Level _level;

  final Map<String, Tile> _tiles = {};
  final Map<double, Level> _levels = {};

  @override
  void dispose() {
    super.dispose();
    options.tileProvider.dispose();
  }

  void _setView(LatLng center, double zoom, MapState mapState) {
    var tileZoom = _clampZoom(zoom.round().toDouble());

    if (_tileZoom != tileZoom) {
      _tileZoom = tileZoom;
      _updateLevels(mapState);
      _resetGrid(mapState);
    }
    _setZoomTransforms(center, zoom, mapState);
  }
  
  bool _hasLevelChildren(double lvl) {
    for (var tile in _tiles.values) {
      if (tile.coords.z == lvl) {
        return true;
      }
    }

    return false;
  }

  Level _updateLevels(MapState map) {
    var zoom = _tileZoom;
    var maxZoom = options.maxZoom;

    if (zoom == null) return null;

    var toRemove = <double>[];
    for (var entry in _levels.entries) {
      var z = entry.key;
      var lvl = entry.value;

      if (z == zoom || _hasLevelChildren(z)) {
        lvl.zIndex = maxZoom - (zoom - z).abs();
      } else {
        toRemove.add(z);
      }
    }

    for (var z in toRemove) {
      _removeTilesAtZoom(z);
      _levels.remove(z);
    }

    var level = _levels[zoom];

    if (level == null) {
      level = _levels[zoom] = Level();
      level.zIndex = maxZoom;
      level.origin = map.project(map.unproject(map.getPixelOrigin()), zoom) ??
          CustomPoint(0.0, 0.0);
      level.zoom = zoom;

      _setZoomTransform(level, map.center, map.zoom, map);
    }

    return _level = level;
  }

  void _setZoomTransform(Level level, LatLng center, double zoom, MapState map) {
    var scale = map.getZoomScale(zoom, level.zoom);
    var pixelOrigin = map.getNewPixelOrigin(center, zoom).round();
    if (level.origin == null) {
      return;
    }
    var translate = level.origin.multiplyBy(scale) - pixelOrigin;
    level.translatePoint = translate;
    level.scale = scale;
  }

  void _setZoomTransforms(LatLng center, double zoom, MapState map) {
    for (var i in _levels.keys) {
      _setZoomTransform(_levels[i], center, zoom, map);
    }
  }

  void _removeTilesAtZoom(double zoom) {
    var toRemove = <String>[];
    for (var key in _tiles.keys) {
      if (_tiles[key].coords.z != zoom) {
        continue;
      }
      toRemove.add(key);
    }
    for (var key in toRemove) {
      _removeTile(key);
    }
  }

  void _removeTile(String key) {
    var tile = _tiles[key];
    if (tile == null) {
      return;
    }
    _tiles[key].current = false;
  }

  void _resetGrid(MapState map) {
    var crs = map.options.crs;
    var tileSize = getTileSize();
    var tileZoom = _tileZoom;

    var bounds = map.getPixelWorldBounds(_tileZoom);
    if (bounds != null) {
      _globalTileRange = _pxBoundsToTileRange(bounds);
    }

    // wrapping
    _wrapX = crs.wrapLng;
    if (_wrapX != null) {
      var first =
          (map.project(LatLng(0.0, crs.wrapLng.item1), tileZoom).x / tileSize.x)
              .floor()
              .toDouble();

      var second =
          (map.project(LatLng(0.0, crs.wrapLng.item2), tileZoom).x / tileSize.y)
              .ceil()
              .toDouble();

      _wrapX = Tuple2(first, second);
    }

    _wrapY = crs.wrapLat;
    if (_wrapY != null) {
      var first =
          (map.project(LatLng(crs.wrapLat.item1, 0.0), tileZoom).y / tileSize.x)
              .floor()
              .toDouble();

      var second =
          (map.project(LatLng(crs.wrapLat.item2, 0.0), tileZoom).y / tileSize.y)
              .ceil()
              .toDouble();

      _wrapY = Tuple2(first, second);
    }
  }

  double _clampZoom(double zoom) {
    // todo
    return zoom;
  }

  CustomPoint getTileSize() {
    return CustomPoint(options.tileSize, options.tileSize);
  }

  @override
  Widget build(BuildContext context) {
    final mapState = MapStateInheritedWidget.of(context).mapState;
    _setView(mapState.center, mapState.zoom, mapState);

    var pixelBounds = _getTiledPixelBounds(mapState.center, mapState);
    var tileRange = _pxBoundsToTileRange(pixelBounds);
    var tileCenter = tileRange.getCenter();
    var queue = <Coords>[];

    for (var key in _tiles.keys) {
      var c = _tiles[key].coords;
      if (c.z != _tileZoom) {
        _tiles[key].current = false;
      }
    }

    for (var j = tileRange.min.y; j <= tileRange.max.y; j++) {
      for (var i = tileRange.min.x; i <= tileRange.max.x; i++) {
        var coords = Coords(i.toDouble(), j.toDouble());
        coords.z = _tileZoom;

        if (!_isValidTile(coords, mapState.options.crs)) {
          continue;
        }

        queue.add(coords);
      }
    }

    if (queue.isNotEmpty) {
      for (var i = 0; i < queue.length; i++) {
        _tiles[_tileCoordsToKey(queue[i])] =
            Tile(coords: _wrapCoords(queue[i]));
      }
    }

    var tilesToRender = <Tile>[
      for (var tile in _tiles.values)
        if ((tile.coords.z - _level.zoom).abs() <= 1) tile
    ];

    tilesToRender.sort((aTile, bTile) {
      final a = aTile.coords;
      final b = bTile.coords;
      if (a.z != b.z) {
        return (b.z - a.z).toInt();
      }
      return (a.distanceTo(tileCenter) - b.distanceTo(tileCenter)).toInt();
    });

    var tileWidgets = <Widget>[
      for (var tile in tilesToRender) _createTileWidget(tile.coords)
    ];

    return Opacity(
      opacity: options.opacity,
      child: Container(
        color: options.backgroundColor,
        child: Stack(
          children: tileWidgets,
        ),
      ),
    );
  }

  Bounds _getTiledPixelBounds(LatLng center, MapState mapState) {
    return mapState.getPixelBounds(_tileZoom);
  }

  Bounds _pxBoundsToTileRange(Bounds bounds) {
    var tileSize = getTileSize();
    return Bounds(
      bounds.min.unscaleBy(tileSize).floor(),
      bounds.max.unscaleBy(tileSize).ceil() - CustomPoint(1, 1),
    );
  }

  bool _isValidTile(Coords coords, Crs crs) {
    if (!crs.infinite) {
      var bounds = _globalTileRange;
      if ((crs.wrapLng == null &&
              (coords.x < bounds.min.x || coords.x > bounds.max.x)) ||
          (crs.wrapLat == null &&
              (coords.y < bounds.min.y || coords.y > bounds.max.y))) {
        return false;
      }
    }
    return true;
  }

  String _tileCoordsToKey(Coords coords) {
    return '${coords.x}:${coords.y}:${coords.z}';
  }

  Widget _createTileWidget(Coords coords) {
    var tilePos = _getTilePos(coords);
    var level = _levels[coords.z];
    var tileSize = getTileSize();
    var pos = (tilePos).multiplyBy(level.scale) + level.translatePoint;
    var width = tileSize.x * level.scale;
    var height = tileSize.y * level.scale;

    final Widget content = Container(
      child: FadeInImage(
        fadeInDuration: const Duration(milliseconds: 100),
        key: Key(_tileCoordsToKey(coords)),
        placeholder: options.placeholderImage != null
            ? options.placeholderImage
            : MemoryImage(kTransparentImage),
        image: options.tileProvider.getImage(coords, options),
        fit: BoxFit.fill,
      ),
    );

    return Positioned(
        left: pos.x.toDouble(),
        top: pos.y.toDouble(),
        width: width.toDouble(),
        height: height.toDouble(),
        child: content);
  }

  Coords _wrapCoords(Coords coords) {
    var newCoords = Coords(
      _wrapX != null
          ? util.wrapNum(coords.x.toDouble(), _wrapX)
          : coords.x.toDouble(),
      _wrapY != null
          ? util.wrapNum(coords.y.toDouble(), _wrapY)
          : coords.y.toDouble(),
    );

    newCoords.z = coords.z.toDouble();
    return newCoords;
  }

  CustomPoint _getTilePos(Coords coords) {
    var level = _levels[coords.z];
    return coords.scaleBy(getTileSize()) - level.origin;
  }
}

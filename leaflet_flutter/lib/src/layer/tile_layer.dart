import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:latlong/latlong.dart';
import 'package:leaflet_flutter/src/core/bounds.dart';
import 'package:leaflet_flutter/src/core/point.dart';
import 'package:leaflet_flutter/src/map/map.dart';
import 'package:leaflet_flutter/src/core/util.dart' as util;
import 'package:tuple/tuple.dart';
import 'layer.dart';

class TileLayerOptions extends LayerOptions {
  final String urlTemplate;
  final double tileSize;
  final double maxZoom;
  final bool zoomReverse;
  final double zoomOffset;
  Map<String, String> additionalOptions;
  TileLayerOptions({
    this.urlTemplate,
    this.tileSize = 256.0,
    this.maxZoom = 18.0,
    this.zoomReverse = false,
    this.zoomOffset = 0.0,
    this.additionalOptions = const <String, String>{},
  });
}

class TileLayer extends StatefulWidget {
  final TileLayerOptions options;
  final MapState mapState;

  TileLayer({
    this.options,
    this.mapState,
  });

  State<StatefulWidget> createState() {
    return new _TileLayerState();
  }
}

class _TileLayerState extends State<TileLayer> {
  MapState get map => widget.mapState;
  TileLayerOptions get options => widget.options;
  Point _tileSize;
  Bounds _globalTileRange;
  Tuple2<double, double> _wrapX;
  Tuple2<double, double> _wrapY;
  double _tileZoom;
  List<Widget> tiles = [];
  Level _level;

  Map<String, Tile> _tiles = {};
  Map<double, Level> _levels = {};

  void initState() {
    super.initState();
    _resetView();
  }

  Widget createTile(Coords coords) {
    return new Image.network(
      getTileUrl(coords),
      key: new Key(_tileCoordsToKey(coords)),
    );
  }

  String getTileUrl(Coords coords) {
    var data = <String, String>{
      'x': coords.x.round().toString(),
      'y': coords.y.round().toString(),
      'z': _getZoomForUrl().round().toString(),
    };
    var allOpts = new Map.from(data)..addAll(this.options.additionalOptions);
    return util.template(this.options.urlTemplate, allOpts);
  }

  double _getZoomForUrl() {
    var zoom = _tileZoom;
    var maxZoom = options.maxZoom;
    var zoomReverse = options.zoomReverse;
    var zoomOffset = options.zoomOffset;
    if (zoomReverse == true) {
      zoom = maxZoom - zoom;
    }
    return zoom + zoomOffset;
  }

  void _resetView() {
    this._setView(map.center, map.zoom);
  }

  void _setView(LatLng center, double zoom) {
    var tileZoom = this._clampZoom(zoom.round().toDouble());
    if (_tileZoom != tileZoom) {
      _tileZoom = tileZoom;
      _updateLevels();
      _resetGrid();
    }
    _setZoomTransforms(center, zoom);
  }

  Level _updateLevels() {
    var zoom = this._tileZoom;
    var maxZoom = this.options.maxZoom;

    if (zoom == null) return null;

    for (var z in this._levels.keys) {
      if (_levels[z].children.length > 0 || z == zoom) {
        _levels[z].zIndex = maxZoom = (zoom - z).abs();
      } else {
        _removeTilesAtZoom(z);
        _levels.remove(z);
      }
    }

    var level = _levels[zoom];
    var map = this.map;

    if (level == null) {
      level = _levels[zoom] = new Level();
      level.zIndex = maxZoom;
      level.origin = map.project(map.unproject(map.getPixelOrigin()), zoom);
      level.zoom = zoom;

      _setZoomTransform(level, map.center, map.zoom);
    }
    this._level = level;
    return level;
  }

  void _setZoomTransform(Level level, LatLng center, double zoom) {
    var scale = map.getZoomScale(zoom, level.zoom);
    var pixelOrigin = map.getNewPixelOrigin(center, zoom).round();
    var translate = level.origin.multiplyBy(scale) - pixelOrigin;
    level.translatePoint = translate;
    level.scale = scale;
  }

  void _setZoomTransforms(LatLng center, double zoom) {
    for (var i in this._levels.keys) {
      this._setZoomTransform(_levels[i], center, zoom);
    }
  }

  void _removeTilesAtZoom(double zoom) {
    for (var key in _tiles.keys) {
      if (_tiles[key].coords.z != zoom) {
        continue;
      }
      _removeTile(key);
    }
  }

  void _removeTile(String key) {
    var tile = _tiles[key];
    if (tile == null) {
      return;
    }
    _tiles.remove(key);
  }

  _resetGrid() {
    var map = this.map;
    var crs = map.options.crs;
    var tileSize = this.getTileSize();
    this._tileSize = tileSize;
    var tileZoom = _tileZoom;

    var bounds = map.getPixelWorldBounds(_tileZoom);
    if (bounds != null) {
      _globalTileRange = _pxBoundsToTileRange(bounds);
    }

    // wrapping
    this._wrapX = crs.wrapLng;
    if (_wrapX != null) {
      var first = (map.project(new LatLng(0.0, crs.wrapLng.item1), tileZoom).x /
              tileSize.x)
          .floor()
          .toDouble();
      var second =
          (map.project(new LatLng(0.0, crs.wrapLng.item2), tileZoom).x /
                  tileSize.y)
              .ceil()
              .toDouble();
      _wrapX = new Tuple2(first, second);
    }

    this._wrapY = crs.wrapLat;
    if (_wrapY != null) {
      var first = (map.project(new LatLng(crs.wrapLat.item1, 0.0), tileZoom).y /
              tileSize.x)
          .floor()
          .toDouble();
      var second =
          (map.project(new LatLng(crs.wrapLat.item2, 0.0), tileZoom).y /
                  tileSize.y)
              .ceil()
              .toDouble();
      _wrapY = new Tuple2(first, second);
    }
  }

  double _clampZoom(double zoom) {
    // todo
    return zoom;
  }

  Point getTileSize() {
    return new Point(options.tileSize, options.tileSize);
  }

  // Gridlayer._update()
  Widget build(BuildContext context) {
    var pixelBounds = _getTiledPixelBounds(map.center);
    var tileRange = _pxBoundsToTileRange(pixelBounds);
    var tileCenter = tileRange.getCenter();
    var queue = <Coords>[];

    // mark tiles as out of view...
    for (var key in this._tiles.keys) {
      var c = this._tiles[key].coords;
      if (c.z != this._tileZoom) {
        _tiles[key].current = false;
      }
    }

    for (var j = tileRange.min.y; j <= tileRange.max.y; j++) {
      for (var i = tileRange.min.x; i <= tileRange.max.x; i++) {
        var coords = new Coords(i.toDouble(), j.toDouble());
        coords.z = this._tileZoom;

        if (!this._isValidTile(coords)) {
          continue;
        }

        // Add all valid tiles to the queue on Flutter
        queue.add(coords);

//        var tile = _tiles[_tileCoordsToKey(coords)];
//        if (tile != null) {
//          tile.current = true;
//        } else {
//          queue.add(coords);
//        }
      }
    }

    queue.sort((a, b) {
      return (a.distanceTo(tileCenter) - b.distanceTo(tileCenter)).toInt();
    });

    tiles.clear();
    if (queue.length > 0) {
      for (var i = 0; i < queue.length; i++) {
        _addTile(queue[i]);
      }
    }
//    var level = _level;
//    var levelWidget = new Positioned(
//      key: new Key(map.zoom.toString()),
//      left: level?.origin?.x?.roundToDouble() ?? 0.0,
//      top: level?.origin?.y?.roundToDouble() ?? 0.0,
//      right: 0.0,
//      bottom: 0.0,
//      child: new Stack(children: tiles),
//    );

    var level = new Positioned(
      left: _level.translatePoint.x,
      top: _level.translatePoint.y,
//      width: _level.scale
      child: new Stack(children: tiles),
    );

    return new GestureDetector(
      onScaleStart: _handleScaleStart,
      onScaleUpdate: _handleScaleUpdate,
      onScaleEnd: _handleScaleEnd,
      child: new Container(
        child: new Stack(
          children: tiles,
        ),
      ),
    );
  }

  Offset _scaleStartOffset;
  void _handleScaleStart(ScaleStartDetails details) {
    _scaleStartOffset = details.focalPoint;
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    if (_scaleStartOffset == null) {
      return;
    }
    var latestPoint = details.focalPoint;
    var scale = details.scale;
    var dx = latestPoint.dx - _scaleStartOffset.dx;
    var dy = latestPoint.dy - _scaleStartOffset.dy;
    var offset = new Point(dx, dy);
    var newCenterPoint = map.project(map.center) - new Point(dx, dy);
    var newCenter = map.unproject(newCenterPoint);
    var newZoom = map.zoom;
    setState(() {
      map.move(newCenter, newZoom);
      map.panBy(offset);
    });
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    _scaleStartOffset = null;
  }

  Bounds _getTiledPixelBounds(LatLng center) {
    var mapZoom = map.zoom;
    var scale = map.getZoomScale(mapZoom, this._tileZoom);
    var pixelCenter = map.project(center, this._tileZoom).floor();
    var halfSize = map.size / (scale * 2);
    return new Bounds(pixelCenter - halfSize, pixelCenter + halfSize);
  }

  Bounds _pxBoundsToTileRange(Bounds bounds) {
    var tileSize = this.getTileSize();
    return new Bounds(
      bounds.min.unscaleBy(tileSize).floor(),
      bounds.max.unscaleBy(tileSize).ceil() - new Point(1, 1),
    );
  }

  bool _isValidTile(Coords coords) {
    // TODO: determine why _globalTileRange / _pxBoundsToTileRange produces a
    // range of this format:
    //
    // min: (0, 8192)
    // max: (8191, 0)

//    var crs = map.options.crs;
//    if (!crs.infinite) {
//      var bounds = this._globalTileRange;
//      if ((crs.wrapLng == null &&
//              (coords.x < bounds.min.x || coords.x > bounds.max.x)) ||
//          (crs.wrapLat == null &&
//              (coords.y < bounds.min.y || coords.y > bounds.max.y))) {
//        return false;
//      }
//    }

    return true;
  }

  String _tileCoordsToKey(Coords coords) {
    return "${coords.x}:${coords.y}:${coords.z}";
  }

  Widget _initTile(Widget tile, Coords coords, Point point) {
    var tileSize = getTileSize();
//    var key = new Key(_tileCoordsToKey(coords) + "$point:$tileSize");
//    var pixelOrigin = this.map.getPixelOrigin();
    return new Positioned(
//      key: key,
      left: point.x.roundToDouble() + map.panOffset.x,
      top: point.y.roundToDouble() + map.panOffset.y,
      width: tileSize.x.roundToDouble(),
      height: tileSize.y.roundToDouble(),
      child: new Container(
        child: tile,
      ),
    );
  }

  void _addTile(Coords coords) {
    var tilePos = _getTilePos(coords);
//    var key = _tileCoordsToKey(coords);
    var tile = createTile(_wrapCoords(coords));
    tile = _initTile(tile, coords, tilePos);
    var key = _tileCoordsToKey(coords);
    _tiles[key] = new Tile(null, coords, true);
    setState(() {
      this.tiles.add(tile);
    });
  }

  _wrapCoords(Coords coords) {
    var newCoords = new Coords(
      _wrapX != null
          ? util.wrapNum(coords.x.toDouble(), _wrapX)
          : coords.x.toDouble(),
      _wrapY != null
          ? util.wrapNum(coords.y.toDouble(), _wrapY)
          : coords.y.toDouble(),
    );
    newCoords.z = coords.z;
    return newCoords;
  }

  Point _getTilePos(Coords coords) {
    return coords.scaleBy(this.getTileSize()) - this._level.origin;
  }
}

class Tile {
  final el;
  final coords;
  bool current;
  Tile(this.el, this.coords, this.current);
}

class Level {
  List children;
  double zIndex;
  Point origin;
  double zoom;
  Point translatePoint;
  double scale;
}

class Coords<T extends num> extends Point<T> {
  T z;
  Coords(T x, T y) : super(x, y);
  String toString() => 'Coords($x, $y, $z)';
}

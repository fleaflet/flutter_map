import 'dart:typed_data';

import 'dart:math' as math;
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

class _TileLayerState extends State<TileLayer>
    with SingleTickerProviderStateMixin {
  MapState get map => widget.mapState;
  TileLayerOptions get options => widget.options;
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
    _controller = new AnimationController(vsync: this)
      ..addListener(_handleFlingAnimation);
  }

  Widget createTile(Coords coords) {
    var blankImageBytes = new Uint8List(0);
    return new FadeInImage(
      fadeInDuration: const Duration(milliseconds: 100),
      key: new Key(_tileCoordsToKey(coords)),
      // here `bytes` is a Uint8List containing the bytes for the in-memory image
      placeholder: new MemoryImage(blankImageBytes),
      image: new NetworkImage(getTileUrl(coords)),
      fit: BoxFit.fill,
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

    List<double> toRemove = [];
    for (var z in this._levels.keys) {
      if (_levels[z].children.length > 0 || z == zoom) {
        _levels[z].zIndex = maxZoom = (zoom - z).abs();
      } else {
        toRemove.add(z);
      }
    }
    for (var z in toRemove) {
      _removeTilesAtZoom(z);
      _levels.remove(z);
    }

    var level = _levels[zoom];
    var map = this.map;

    if (level == null) {
      level = _levels[zoom] = new Level();
      level.zIndex = maxZoom;
      var newOrigin = map.project(map.unproject(map.getPixelOrigin()), zoom);
      if (newOrigin != null) {
        level.origin = newOrigin;
      } else {
        level.origin = new Point(0.0, 0.0);
      }
      level.zoom = zoom;

      _setZoomTransform(level, map.center, map.zoom);
    }
    this._level = level;
    return level;
  }

  void _setZoomTransform(Level level, LatLng center, double zoom) {
    var scale = map.getZoomScale(zoom, level.zoom);
    var pixelOrigin = map.getNewPixelOrigin(center, zoom).round();
    if (level.origin == null) {
      return;
    }
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
    List<String> toRemove = [];
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
    _tiles.remove(key);
  }

  _resetGrid() {
    var map = this.map;
    var crs = map.options.crs;
    var tileSize = this.getTileSize();
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

    // if the zoom level differs, call _setView to reset levels and prune old tiles...
    _setView(map.center, map.zoom);

    for (var j = tileRange.min.y; j <= tileRange.max.y; j++) {
      for (var i = tileRange.min.x; i <= tileRange.max.x; i++) {
        var coords = new Coords(i.toDouble(), j.toDouble());
        coords.z = this._tileZoom;

        if (!this._isValidTile(coords)) {
          continue;
        }

        // Add all valid tiles to the queue on Flutter
        queue.add(coords);
      }
    }

    queue.sort((a, b) {
      return (a.distanceTo(tileCenter) - b.distanceTo(tileCenter)).toInt();
    });

    const maxLength = 12;
    var numExtraTiles = tiles.length - maxLength;
    if (numExtraTiles < 0) numExtraTiles = 0;
    tiles = tiles.sublist(numExtraTiles);
    if (queue.length > 0) {
      for (var i = 0; i < queue.length; i++) {
        _addTile(queue[i]);
      }
    }

    return new GestureDetector(
      onScaleStart: _handleScaleStart,
      onScaleUpdate: _handleScaleUpdate,
      onScaleEnd: _handleScaleEnd,
      child: new Container(
        child: new Stack(
          children: tiles,
        ),
        color: Colors.grey[300],
      ),
    );
  }

  Point _mapStartPoint;
  Offset _panStart = new Offset(0.0, 0.0);
  double _mapZoomStart;
  void _handleScaleStart(ScaleStartDetails details) {
    setState(() {
      _mapStartPoint = map.project(map.center);
      _mapZoomStart = map.zoom;
      _panStart = details.focalPoint;
      _controller.stop();
    });
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      var dScale = details.scale;
      for (var i =0; i < 2; i++) {
        dScale = math.sqrt(dScale);
      }
      var dx = _panStart.dx - details.focalPoint.dx;
      var dy = _panStart.dy - details.focalPoint.dy;
      _offset = new Offset(dx, dy);
      var newZoom = _mapZoomStart * dScale;
      var newCenterPoint = _mapStartPoint + new Point(dx, dy);
      var newCenter = map.unproject(newCenterPoint);
      if (newZoom != _mapZoomStart) {
        map.move(map.center, newZoom);
      } else {
        if (newCenter == null) {
          return;
        }
        map.move(newCenter, map.zoom);
      }
    });
  }

  Offset _offset = new Offset(0.0, 0.0);
  AnimationController _controller;
  Animation<Offset> _flingAnimation;
  static const double _kMinFlingVelocity = 800.0;

  void _handleScaleEnd(ScaleEndDetails details) {
    final double magnitude = details.velocity.pixelsPerSecond.distance;
    if (magnitude < _kMinFlingVelocity) return;
    final Offset direction = details.velocity.pixelsPerSecond / magnitude;
    final double distance = (Offset.zero & context.size).shortestSide;
    _flingAnimation =
        new Tween<Offset>(begin: _offset, end: _offset - direction * distance)
            .animate(_controller);
    _controller
      ..value = 0.0
      ..fling(velocity: magnitude / 1000.0);
  }

  void _handleFlingAnimation() {
    setState(() {
      _offset = _flingAnimation.value;
      var newCenterPoint = _mapStartPoint + new Point(_offset.dx, _offset.dy);
      var newCenter = map.unproject(newCenterPoint);
      map.move(newCenter, map.zoom);
    });
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
    var crs = map.options.crs;
    if (!crs.infinite) {
      var bounds = _globalTileRange;
      if ((crs.wrapLng == null &&
              (coords.x < bounds.min.x || coords.x > bounds.max.x)) ||
          (crs.wrapLat == null &&
              (coords.y < bounds.min.y || coords.y > bounds.max.y))) {
        return false;
      }
    }

    // don't load tile if it doesn't intersect the bounds in options
//    var tileBounds = this._tileCoordsToBounds(coords);
//    return latLngBounds(this.options.bounds).overlaps(tileBounds);
    return true;
  }

  String _tileCoordsToKey(Coords coords) {
    return "${coords.x}:${coords.y}:${coords.z}";
  }

  Widget _initTile(Widget tile, Coords coords, Point point) {
    var tileSize = getTileSize();
    var pos = (point + _level.translatePoint).multiplyBy(_level.scale);
    var width = tileSize.x.roundToDouble() * _level.scale;
    var height = tileSize.y.roundToDouble() * _level.scale;
    return new Positioned(
      left: pos.x,
      top: pos.y,
      width: width,
      height: height,
      child: new Container(
        child: tile,
      ),
    );
  }

  void _addTile(Coords coords) {
    var tilePos = _getTilePos(coords);
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
  List children = [];
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

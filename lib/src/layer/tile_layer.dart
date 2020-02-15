import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/src/core/bounds.dart';
import 'package:flutter_map/src/core/point.dart';
import 'package:flutter_map/src/core/util.dart' as util;
import 'package:flutter_map/src/geo/crs/crs.dart';
import 'package:flutter_map/src/layer/tile_provider/tile_provider.dart';
import 'package:flutter_map/src/map/map.dart';
import 'package:latlong/latlong.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:tuple/tuple.dart';

import 'layer.dart';

/// Describes the needed properties to create a tile-based layer.
/// A tile is an image binded to a specific geographical position.
class TileLayerOptions extends LayerOptions {
  /// Defines the structure to create the URLs for the tiles.
  ///
  /// Example:
  ///
  /// https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png
  ///
  /// Is translated to this:
  ///
  /// https://a.tile.openstreetmap.org/12/2177/1259.png
  final String urlTemplate;

  /// If `true`, inverses Y axis numbering for tiles (turn this on for
  /// [TMS](https://en.wikipedia.org/wiki/Tile_Map_Service) services).
  final bool tms;

  /// If not `null`, then tiles will pull's WMS protocol requests
  final WMSTileLayerOptions wmsOptions;

  /// Size for the tile.
  /// Default is 256
  final double tileSize;

  /// The max zoom applicable. In most tile providers goes from 0 to 19.
  final double maxZoom;

  final bool zoomReverse;
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

  ///Color shown behind the tiles.
  final Color backgroundColor;

  ///Opacity of the rendered tile
  final double opacity;

  /// Provider to load the tiles. The default is CachedNetworkTileProvider,
  /// which loads tile images from network and caches them offline.
  ///
  /// If you don't want to cache the tiles, use NetworkTileProvider instead.
  ///
  /// In order to use images from the asset folder set this option to
  /// AssetTileProvider() Note that it requires the urlTemplate to target
  /// assets, for example:
  ///
  /// ```dart
  /// urlTemplate: "assets/map/anholt_osmbright/{z}/{x}/{y}.png",
  /// ```
  ///
  /// In order to use images from the filesystem set this option to
  /// FileTileProvider() Note that it requires the urlTemplate to target the
  /// file system, for example:
  ///
  /// ```dart
  /// urlTemplate: "/storage/emulated/0/tiles/some_place/{z}/{x}/{y}.png",
  /// ```
  ///
  /// Furthermore you create your custom implementation by subclassing
  /// TileProvider
  ///
  final TileProvider tileProvider;

  /// When panning the map, keep this many rows and columns of tiles before
  /// unloading them.
  final int keepBuffer;

  /// Placeholder to show until tile images are fetched by the provider.
  ImageProvider placeholderImage;

  /// Static informations that should replace placeholders in the [urlTemplate].
  /// Applying API keys is a good example on how to use this parameter.
  ///
  /// Example:
  ///
  /// ```dart
  ///
  /// TileLayerOptions(
  ///     urlTemplate: "https://api.tiles.mapbox.com/v4/"
  ///                  "{id}/{z}/{x}/{y}@2x.png?access_token={accessToken}",
  ///     additionalOptions: {
  ///         'accessToken': '<PUT_ACCESS_TOKEN_HERE>',
  ///          'id': 'mapbox.streets',
  ///     },
  /// ),
  /// ```
  ///
  Map<String, String> additionalOptions;

  /// Try and grab tiles in advance for pan direction. 1 probably a good balance.
  /// Don't set this much higher than one, or there may be too many tile requests.
  /// 0 May be better if network limited for example.
  int greedyTileCount;

  /// Keep an old tile, until the new one has downloaded
  bool useFallbackTiles;

  /// pruning tiles every move can lead to clunky flashing where prunes happen
  /// before loads, so try and back skip some prunes. Example 40ms. For some
  /// apps it may be better at 0, or even increased for very old devices.
  /// Maybe we could be intelligent and calculate if we need to back off pruning..
  /// ...tbd
  int tilePruneSmoothing;

  TileLayerOptions(
      {this.urlTemplate,
      this.tileSize = 256.0,
      this.maxZoom = 18.0,
      this.zoomReverse = false,
      this.zoomOffset = 0.0,
      this.additionalOptions = const <String, String>{},
      this.subdomains = const <String>[],
      this.keepBuffer = 2,
      this.backgroundColor = const Color(0xFFE0E0E0),
      this.placeholderImage,
      this.tileProvider = const CachedNetworkTileProvider(),
      this.tms = false,
      // ignore: avoid_init_to_null
      this.wmsOptions = null,
      this.opacity = 1.0,
      this.greedyTileCount = 1,
      this.useFallbackTiles = true,
      this.tilePruneSmoothing = 40,
      rebuild})
      : super(rebuild: rebuild);
}

class WMSTileLayerOptions {
  final service = 'WMS';
  final request = 'GetMap';

  /// url of WMS service.
  /// Ex.: 'http://ows.mundialis.de/services/service?'
  final String baseUrl;

  /// list of WMS layers to show
  final List<String> layers;

  /// list of WMS styles
  final List<String> styles;

  /// WMS image format (use 'image/png' for layers with transparency)
  final String format;

  /// Version of the WMS service to use
  final String version;

  /// tile transperency flag
  final bool transparent;

  // TODO find a way to implicit pass of current map [Crs]
  final Crs crs;

  /// other request parameters
  final Map<String, String> otherParameters;

  String _encodedBaseUrl;

  double _versionNumber;

  WMSTileLayerOptions({
    @required this.baseUrl,
    this.layers = const [],
    this.styles = const [],
    this.format = 'image/png',
    this.version = '1.1.1',
    this.transparent = true,
    this.crs = const Epsg3857(),
    this.otherParameters = const {},
  }) {
    _versionNumber = double.tryParse(version.split('.').take(2).join('.')) ?? 0;
    _encodedBaseUrl = _buildEncodedBaseUrl();
  }

  String _buildEncodedBaseUrl() {
    final projectionKey = _versionNumber >= 1.3 ? 'crs' : 'srs';
    final buffer = StringBuffer(baseUrl)
      ..write('&service=$service')
      ..write('&request=$request')
      ..write('&layers=${layers.map(Uri.encodeComponent).join(',')}')
      ..write('&styles=${styles.map(Uri.encodeComponent).join(',')}')
      ..write('&format=${Uri.encodeComponent(format)}')
      ..write('&$projectionKey=${Uri.encodeComponent(crs.code)}')
      ..write('&version=${Uri.encodeComponent(version)}')
      ..write('&transparent=$transparent');
    otherParameters
        .forEach((k, v) => buffer.write('&$k=${Uri.encodeComponent(v)}'));
    return buffer.toString();
  }

  String getUrl(Coords coords, int tileSize) {
    final tileSizePoint = CustomPoint(tileSize, tileSize);
    final nvPoint = coords.scaleBy(tileSizePoint);
    final sePoint = nvPoint + tileSizePoint;
    final nvCoords = crs.pointToLatLng(nvPoint, coords.z);
    final seCoords = crs.pointToLatLng(sePoint, coords.z);
    final nv = crs.projection.project(nvCoords);
    final se = crs.projection.project(seCoords);
    final bounds = Bounds(nv, se);
    final bbox = (_versionNumber >= 1.3 && crs is Epsg4326)
        ? [bounds.min.y, bounds.min.x, bounds.max.y, bounds.max.x]
        : [bounds.min.x, bounds.min.y, bounds.max.x, bounds.max.y];

    final buffer = StringBuffer(_encodedBaseUrl);
    buffer.write('&width=$tileSize');
    buffer.write('&height=$tileSize');
    buffer.write('&bbox=${bbox.join(',')}');
    return buffer.toString();
  }
}

class TileLayer extends StatefulWidget {
  final TileLayerOptions options;
  final MapState mapState;
  final Stream<Null> stream;

  TileLayer({
    this.options,
    this.mapState,
    this.stream,
  });

  @override
  State<StatefulWidget> createState() {
    return _TileLayerState();
  }
}

class _TileLayerState extends State<TileLayer> {
  MapState get map => widget.mapState;

  TileLayerOptions get options => widget.options;
  Bounds _globalTileRange;
  Tuple2<double, double> _wrapX;
  Tuple2<double, double> _wrapY;
  double _tileZoom;
  Level _level;
  StreamSubscription _moveSub;

  final Map<String, Tile> _tiles = {};
  final Map<double, Level> _levels = {};

  Map _outstandingTileLoads = {};

  LatLng _prevCenter;
  LatLng _currentCenter;

  DateTime lastPruneTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _resetView();
    _moveSub = widget.stream.listen((_) => _handleMove());
  }

  @override
  void dispose() {
    super.dispose();
    _moveSub?.cancel();
    options.tileProvider.dispose();
  }

  void _handleMove() {
    setState(() {
      /// See comments on this.tilePruneSmoothing above
      var timeSinceLastPrune = DateTime.now().difference(lastPruneTime).inMilliseconds;

      /// Try and keep outstanding tile list tidy if not used for an hour for example.
      if(timeSinceLastPrune > 3600000) _outstandingTileLoads = {};

      /// Frequent pruning before tileloads can cause a jarring flashing experience,
      /// so back off pruning every time unless opted out.
      if(timeSinceLastPrune > options.tilePruneSmoothing) {
        lastPruneTime = DateTime.now();
        _pruneTiles();
      }
      _resetView();
    });
  }

  void _resetView() {
    _setView(map.center, map.zoom);
  }

  void _setView(LatLng center, double zoom) {

    var tileZoom = _clampZoom(zoom.round().toDouble());
    if (_tileZoom != tileZoom) {
      _tileZoom = tileZoom;
      _updateLevels();
      _resetGrid();
    }
    _setZoomTransforms(center, zoom);
  }

  Level _updateLevels() {
    var zoom = _tileZoom;
    var maxZoom = options.maxZoom;

    if (zoom == null) return null;

    var toRemove = <double>[];
    for (var z in _levels.keys) {
      if (_levels[z].children.isNotEmpty || z == zoom) {
        _levels[z].zIndex = maxZoom = (zoom - z).abs();
      } else {
        toRemove.add(z);
      }
    }

    for (var z in toRemove) {
      _removeTilesAtZoom(z);
    }

    var level = _levels[zoom];
    var map = this.map;

    if (level == null) {
      level = _levels[zoom] = Level();
      level.zIndex = maxZoom;
      var newOrigin = map.project(map.unproject(map.getPixelOrigin()), zoom);
      if (newOrigin != null) {
        level.origin = newOrigin;
      } else {
        level.origin = CustomPoint(0.0, 0.0);
      }
      level.zoom = zoom;

      _setZoomTransform(level, map.center, map.zoom);
    }
    _level = level;
    return level;
  }

  void _pruneTiles() {
    var center = map.center;
    var pixelBounds = _getTiledPixelBounds(center);
    var tileRange = _pxBoundsToTileRange(pixelBounds);
    var margin = options.keepBuffer ?? 2;
    var noPruneRange = Bounds(
        tileRange.bottomLeft - CustomPoint(margin, -margin),
        tileRange.topRight + CustomPoint(margin, -margin));
    for (var tileKey in _tiles.keys) {
      var tile = _tiles[tileKey];
      var c = tile.coords;
      if (c.z != _tileZoom || !noPruneRange.contains(CustomPoint(c.x, c.y))) {
        tile.current = false;
      }

      /// _outstandingTileLoads is a list of tiles not completed (see callback later)
      /// So if they aren't completed, we will check to see if there is another
      /// tile that covers it, if so, don't mark it for pruning yet.
      for( var outStandingTilekey in _outstandingTileLoads.keys) {
        if(options.useFallbackTiles && _tileOverlaps(_outstandingTileLoads[outStandingTilekey], c)  && (!_outstandingTileLoads.containsKey(_tileCoordsToKey(c)))) {
          tile.current = true;
        }
      }
    }

    _tiles.removeWhere((s, tile) => (tile.current == false));
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
    for (var i in _levels.keys) {
      _setZoomTransform(_levels[i], center, zoom);
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

  void _resetGrid() {
    var map = this.map;
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
    var pixelBounds = _getTiledPixelBounds(map.center);
    var tileRange = _pxBoundsToTileRange(pixelBounds);
    var tileCenter = tileRange.getCenter();
    var queue = <Coords>[];

    // mark tiles as out of view...
    for (var key in _tiles.keys) {
      var c = _tiles[key].coords;
      if (c.z != _tileZoom) {
        _tiles[key].current = false;
      }
    }

    _setView(map.center, map.zoom);

    int miny = tileRange.min.y;
    int maxy = tileRange.max.y;
    int minx = tileRange.min.x;
    int maxx = tileRange.max.x;

    /// We try and preload some tiles if option set, so with panning there isn't such
    /// a delay in loading the next tile.
    if(_prevCenter == null) _prevCenter = map.center;

    if( map.center.latitude < _prevCenter.latitude)   maxy += options.greedyTileCount; //Up
    if( map.center.latitude > _prevCenter.latitude)   miny -= options.greedyTileCount; //Down
    if( map.center.longitude > _prevCenter.longitude) maxx += options.greedyTileCount; //Left
    if( map.center.longitude < _prevCenter.longitude) minx -= options.greedyTileCount; //Right

    _prevCenter = map.center;

    for (var j = miny; j <= maxy; j++) {
      for (var i = minx; i <= maxx; i++) {
        var coords = Coords(i.toDouble(), j.toDouble());
        coords.z = _tileZoom;

        if (!_isValidTile(coords)) {
          continue;
        }

        // Add all valid tiles to the queue on Flutter
        queue.add(coords);
      }
    }

    if (queue.isNotEmpty) {
      for (var i = 0; i < queue.length; i++) {
        _tiles[_tileCoordsToKey(queue[i])] = Tile(_wrapCoords(queue[i]), true);
      }
    }

    /// Display a tile if its in the correct level, OR it's a tile that overlaps
    /// a tile that hasn't finished loading yet.
    var tilesToRender = <Tile>[
      for (var tile in _tiles.values)
        if (((tile.coords.z - _level.zoom).abs() <= 1) || (options.useFallbackTiles && _tileOverlapsOutstandingTiles(tile.coords))) tile
    ];

    tilesToRender.sort((aTile, bTile) {
      final a = aTile.coords; // TODO there was an implicit casting here.
      final b = bTile.coords;
      // a = 13, b = 12, b is less than a, the result should be positive.
      if (a.z != b.z) {
        return (a.z - b.z).toInt(); // swapped this around...but double check
      }
      return (a.distanceTo(tileCenter) - b.distanceTo(tileCenter)).toInt();
    });

    var tileWidgets = <Widget>[
      for (var tile in tilesToRender) _createTileWidget(tile.coords)
    ];

    return Container(
        color: options.backgroundColor,
        child: Stack(
          children: tileWidgets,
        ),
    );

    /*return Opacity(
      opacity: options.opacity,
      child: Container(
        color: options.backgroundColor,
        child: Stack(
          children: tileWidgets,
        ),
      ),
    );
    */

  }

  Bounds _getTiledPixelBounds(LatLng center) {
    return map.getPixelBounds(_tileZoom);
  }

  Bounds _pxBoundsToTileRange(Bounds bounds) {
    var tileSize = getTileSize();
    return Bounds(
      bounds.min.unscaleBy(tileSize).floor(),
      bounds.max.unscaleBy(tileSize).ceil() - CustomPoint(1, 1),
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
        image: _imageProviderFinishedCheck(coords, options),
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

  /// Check a tile against a list of outstanding tiles, and return true
  /// if it overlaps/covers (on a different zoom level) one
  /// (we probably don't want to prune it yet)
  _tileOverlapsOutstandingTiles( tile ) {
    bool hasOverlap = false;
    _outstandingTileLoads.forEach((s, outStandingTile) {
      if( _tileOverlaps(tile, outStandingTile)) {
        hasOverlap = true;
      };
    });
    return hasOverlap;
  }

  /// Check if one tile 'overlaps/covers' in terms of zoom another tile.
  /// As tiles increase by a factor of 2 each zoom, we can calculate
  /// if one tile is 'higher' than another, but covers it.
  bool _tileOverlaps(Coords a, Coords b) {
    Coords bigger  = b;
    Coords smaller = a;

    if( a.z == b.z ) return false;
    if( a.z > b.z ) {
      bigger  = a;
      smaller = b;
    }

    int zoomDiff     = (bigger.z - smaller.z).toInt();
    int adjustRatio  = pow(2, zoomDiff).toInt();

    if( adjustRatio == 0 ) adjustRatio = 1;
    int coverSquareX = ( bigger.x.toInt() / adjustRatio ).toInt();
    int coverSquareY = ( bigger.y.toInt() / adjustRatio ).toInt();

    if( (coverSquareX == smaller.x) && (coverSquareY == smaller.y ) ) {
      return true;
    }
    return false;
  }

  /// An image callback, so that we can do something when a tile has finished
  /// loading. Used to try and help keep older tiles until it's finished loading.
  ImageProvider _imageProviderFinishedCheck(coords, options) {
    ImageProvider newImageProvider = options.tileProvider.getImage(coords, options);
    _outstandingTileLoads[_tileCoordsToKey(coords)] = coords;
    newImageProvider.resolve(ImageConfiguration()).addListener(
      ImageStreamListener(
            (info,call) {
          _outstandingTileLoads.remove(_tileCoordsToKey(coords));
        },
        onError: ((e, trace) {
          print( "Image not loaded, error: $e");
        })
      ),
    );
    return newImageProvider;
  }
}

class Tile {
  final Coords coords;
  bool current;

  Tile(this.coords, this.current);
}

class Level {
  List children = [];
  double zIndex;
  CustomPoint origin;
  double zoom;
  CustomPoint translatePoint;
  double scale;
}

class Coords<T extends num> extends CustomPoint<T> {
  T z;

  Coords(T x, T y) : super(x, y);

  @override
  String toString() => 'Coords($x, $y, $z)';

  @override
  bool operator ==(dynamic other) {
    if (other is Coords) {
      return x == other.x && y == other.y && z == other.z;
    }
    return false;
  }

  @override
  int get hashCode => hashValues(x.hashCode, y.hashCode, z.hashCode);
}



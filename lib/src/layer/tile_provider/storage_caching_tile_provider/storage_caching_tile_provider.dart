import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/layer/tile_layer.dart';
import 'package:flutter_map/src/layer/tile_provider/storage_caching_tile_provider/storage_caching_db.dart';
import 'package:flutter_map/src/layer/tile_provider/tile_provider.dart';
import 'package:http/http.dart' as http;
import 'package:tuple/tuple.dart';

///Provider that persist loaded raster tiles inside local sqlite db
/// [cachedValidDuration] - valid time period since [DateTime.now]
/// which determines the need for a request for remote tile server. Default value
/// is one day, that means - all cached tiles today and day before don't need rewriting.
class StorageCachingTileProvider extends TileProvider {
  static final kMaxPreloadTileAreaCount = 3000;
  final Duration cachedValidDuration;
  final TileStorageCachingManager _tileStorageCachingManager =
      TileStorageCachingManager();

  StorageCachingTileProvider(
      {this.cachedValidDuration = const Duration(days: 1)});

  @override
  ImageProvider getImage(Coords<num> coords, TileLayerOptions options) {
    final tileUrl = getTileUrl(coords, options);
    return CachedTileImageProvider(tileUrl,
        Coords<int>(coords.x.toInt(), coords.y.toInt())..z = coords.z.toInt());
  }

  /// [maxTileCount] - maximum number of persisted tiles, default value is 3000,
  /// and average tile size ~ 0.017 mb -> so default cache size ~ 51 mb.
  /// To avoid collisions this method should be called before widget build.
  static Future<void> changeMaxTileCount(int maxTileCount) async =>
      TileStorageCachingManager.changeMaxTileCount(maxTileCount);

  /// Caching tile area by provided [bounds], zoom edges and [options].
  /// The maximum number of tiles to load is [kMaxPreloadTileAreaCount].
  /// To check tiles number before calling this method, use
  /// [approximateTileRange].
  /// Return [Tuple3] with uploaded tile index as [Tuple3.item1],
  /// errors count as [Tuple3.item2], and total tiles count need to be downloaded
  /// as [Tuple3.item3]
  Stream<Tuple3<int, int, int>> loadTiles(
      LatLngBounds bounds, int minZoom, int maxZoom, TileLayerOptions options,
      {Function(dynamic) errorHandler}) async* {
    final tilesRange = approximateTileRange(
        bounds: bounds,
        minZoom: minZoom,
        maxZoom: maxZoom,
        tileSize: CustomPoint(options.tileSize, options.tileSize));
    assert(tilesRange.length <= kMaxPreloadTileAreaCount,
        '${tilesRange.length} to many tiles for caching');
    var errorsCount = 0;
    for (var i = 0; i < tilesRange.length; i++) {
      try {
        final cord = tilesRange[i];
        final url = getTileUrl(cord, options);
        // get network tile
        final bytes = (await http.get(url)).bodyBytes;
        // save tile to cache
        await _tileStorageCachingManager.saveTile(bytes, cord);
      } catch (e) {
        errorsCount++;
        if (errorHandler != null) errorHandler(e);
      }
      yield Tuple3(i + 1, errorsCount, tilesRange.length);
    }
  }

  ///Get tileRange from bounds and zoom edges.
  ///[crs] and [tileSize] is optional.
  static List<Coords> approximateTileRange(
      {@required LatLngBounds bounds,
      @required int minZoom,
      @required int maxZoom,
      Crs crs = const Epsg3857(),
      tileSize = const CustomPoint(256, 256)}) {
    assert(minZoom <= maxZoom, 'minZoom > maxZoom');
    final cords = <Coords>[];
    for (var zoomLevel in List<int>.generate(
        maxZoom - minZoom + 1, (index) => index + minZoom)) {
      final nwPoint = crs
          .latLngToPoint(bounds.northWest, zoomLevel.toDouble())
          .unscaleBy(tileSize)
          .floor();
      final sePoint = crs
              .latLngToPoint(bounds.southEast, zoomLevel.toDouble())
              .unscaleBy(tileSize)
              .ceil() -
          CustomPoint(1, 1);
      for (var x = nwPoint.x; x <= sePoint.x; x++) {
        for (var y = nwPoint.y; y <= sePoint.y; y++) {
          cords.add(Coords(x, y)..z = zoomLevel);
        }
      }
    }
    return cords;
  }
}

class CachedTileImageProvider extends ImageProvider<Coords<int>> {
  final Function(dynamic) netWorkErrorHandler;
  final String url;
  final Coords<int> coords;
  final Duration cacheValidDuration;
  final TileStorageCachingManager _tileStorageCachingManager =
      TileStorageCachingManager();

  CachedTileImageProvider(this.url, this.coords,
      {this.cacheValidDuration = const Duration(days: 1),
      this.netWorkErrorHandler});

  @override
  ImageStreamCompleter load(Coords<int> key, decode) =>
      MultiFrameImageStreamCompleter(
          codec: _loadAsync(),
          scale: 1,
          informationCollector: () sync* {
            yield DiagnosticsProperty<ImageProvider>('Image provider', this);
            yield DiagnosticsProperty<Coords>('Image key', key);
          });

  @override
  Future<Coords<int>> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(coords);

  Future<Codec> _loadAsync() async {
    final localBytes = await _tileStorageCachingManager.getTile(coords);
    var bytes = localBytes?.item1;
    if ((DateTime.now().millisecondsSinceEpoch -
            (localBytes?.item2?.millisecondsSinceEpoch ?? 0)) >
        cacheValidDuration.inMilliseconds) {
      try {
        // get network tile
        bytes = (await http.get(url)).bodyBytes;
        // save tile to cache
        await _tileStorageCachingManager.saveTile(bytes, coords);
      } catch (e) {
        if (netWorkErrorHandler != null) netWorkErrorHandler(e);
      }
    }
    if (bytes == null) {
      return Future<Codec>.error('Failed to load tile for coords: $coords');
    }
    return await PaintingBinding.instance.instantiateImageCodec(bytes);
  }
}

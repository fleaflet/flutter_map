import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_provider/network_image_with_retry.dart';

abstract class TileProvider {
  Map<String, String> headers;

  TileProvider({
    this.headers = const {'User-Agent': 'flutter_map (unknown)'},
  });

  ImageProvider getImage(Coords coords, TileLayerOptions options);

  void dispose() {}

  String getTileUrl(Coords coords, TileLayerOptions options) {
    final urlTemplate = (options.wmsOptions != null)
        ? options.wmsOptions!
            .getUrl(coords, options.tileSize.toInt(), options.retinaMode)
        : options.urlTemplate;

    final z = _getZoomForUrl(coords, options);

    final data = <String, String>{
      'x': coords.x.round().toString(),
      'y': coords.y.round().toString(),
      'z': z.round().toString(),
      's': getSubdomain(coords, options),
      'r': '@2x',
    };
    if (options.tms) {
      data['y'] = invertY(coords.y.round(), z.round()).toString();
    }
    final allOpts = Map<String, String>.from(data)
      ..addAll(options.additionalOptions);
    return options.templateFunction(urlTemplate!, allOpts);
  }

  double _getZoomForUrl(Coords coords, TileLayerOptions options) {
    var zoom = coords.z;

    if (options.zoomReverse) {
      zoom = options.maxZoom - zoom;
    }

    return zoom += options.zoomOffset;
  }

  int invertY(int y, int z) {
    return ((1 << z) - 1) - y;
  }

  String getSubdomain(Coords coords, TileLayerOptions options) {
    if (options.subdomains.isEmpty) {
      return '';
    }
    final index = (coords.x + coords.y).round() % options.subdomains.length;
    return options.subdomains[index];
  }
}

/// [TileProvider] that uses [NetworkImageWithRetry] internally
///
/// Note that this is not recommended, as there is no way to set headers with this method: see https://github.com/flutter/flutter/issues/19532.
class NetworkTileProvider extends TileProvider {
  NetworkTileProvider({
    Map<String, String> headers = const {'User-Agent': 'flutter_map (unknown)'},
  }) {
    this.headers = headers;
  }

  @override
  ImageProvider getImage(Coords<num> coords, TileLayerOptions options) {
    return NetworkImageWithRetry(getTileUrl(coords, options));
  }
}

/// [TileProvider] that uses [NetworkImage] internally
class NetworkNoRetryTileProvider extends TileProvider {
  NetworkNoRetryTileProvider({
    Map<String, String> headers = const {'User-Agent': 'flutter_map (unknown)'},
  }) {
    this.headers = headers;
  }

  @override
  ImageProvider getImage(Coords<num> coords, TileLayerOptions options) {
    return NetworkImage(
      getTileUrl(coords, options),
      headers: headers,
    );
  }
}

/// Deprecated due to internal refactoring. The name is misleading, as the internal [ImageProvider] always caches, and this is recommended by most tile servers anyway. For the same functionality, migrate to [NetworkNoRetryTileProvider]. This will continue to work for now.
@Deprecated(
    '`NonCachingTileProvider` has been deprecated due to internal refactoring. The name is misleading, as the internal `ImageProvider` always caches, and this is recommended by most tile servers anyway. For the same functionality, migrate to `NetworkNoRetryTileProvider`.')
class NonCachingNetworkTileProvider extends TileProvider {
  NonCachingNetworkTileProvider({
    Map<String, String> headers = const {'User-Agent': 'flutter_map (unknown)'},
  }) {
    this.headers = headers;
  }

  @override
  ImageProvider getImage(Coords<num> coords, TileLayerOptions options) {
    return NetworkImage(
      getTileUrl(coords, options),
      headers: headers,
    );
  }
}

class AssetTileProvider extends TileProvider {
  AssetTileProvider();

  @override
  ImageProvider getImage(Coords<num> coords, TileLayerOptions options) {
    return AssetImage(getTileUrl(coords, options));
  }
}

class CustomTileProvider extends TileProvider {
  final String Function(Coords coors, TileLayerOptions options) customTileUrl;

  CustomTileProvider({required this.customTileUrl});

  @override
  String getTileUrl(Coords coords, TileLayerOptions options) {
    return customTileUrl(coords, options);
  }

  @override
  ImageProvider getImage(Coords<num> coords, TileLayerOptions options) {
    return AssetImage(getTileUrl(coords, options));
  }
}

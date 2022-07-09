import 'package:flutter/widgets.dart';
import 'package:http/retry.dart';

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_provider/network_image_provider.dart';

abstract class TileProvider {
  Map<String, String> headers;

  TileProvider({
    this.headers = const {},
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

/// [TileProvider] that uses [FMNetworkImageProvider] internally
///
/// This image provider automatically retries some failed requests up to 3 times.
///
/// Note that this provider may be slower than [NetworkNoRetryTileProvider] when fetching tiles due to internal reasons.
///
/// Note that the 'User-Agent' header cannot be changed on the web.
class NetworkTileProvider extends TileProvider {
  NetworkTileProvider({
    Map<String, String>? headers,
  }) {
    this.headers = headers ?? {};
  }

  late final RetryClient retryClient;

  @override
  ImageProvider getImage(Coords<num> coords, TileLayerOptions options) =>
      FMNetworkImageProvider(
        getTileUrl(coords, options),
        headers: headers..remove('User-Agent'),
      );
}

/// [TileProvider] that uses [NetworkImage] internally
///
/// This image provider does not automatically retry any failed requests. This provider is the default and the recommended provider, unless your tile server is especially unreliable.
///
/// Note that the 'User-Agent' header cannot be changed on the web.
class NetworkNoRetryTileProvider extends TileProvider {
  NetworkNoRetryTileProvider({
    Map<String, String>? headers,
  }) {
    this.headers = headers ?? {};
  }

  @override
  ImageProvider getImage(Coords<num> coords, TileLayerOptions options) =>
      NetworkImage(
        getTileUrl(coords, options),
        headers: headers..remove('User-Agent'),
      );
}

/// Deprecated due to internal refactoring. The name is misleading, as the internal [ImageProvider] always caches, and this is recommended by most tile servers anyway. For the same functionality, migrate to [NetworkNoRetryTileProvider] before the next minor update.
@Deprecated(
    '`NonCachingNetworkTileProvider` has been deprecated due to internal refactoring. The name is misleading, as the internal `ImageProvider` always caches, and this is recommended by most tile servers anyway. For the same functionality, migrate to `NetworkNoRetryTileProvider` before the next minor update.')
class NonCachingNetworkTileProvider extends TileProvider {
  NonCachingNetworkTileProvider({
    Map<String, String>? headers,
  }) {
    this.headers = headers ?? {};
  }

  @override
  ImageProvider getImage(Coords<num> coords, TileLayerOptions options) =>
      NetworkNoRetryTileProvider(
        headers: headers,
      ).getImage(coords, options);
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

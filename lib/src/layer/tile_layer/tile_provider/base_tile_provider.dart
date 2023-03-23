import 'package:flutter/widgets.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_coordinate.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_layer.dart';

/// The base tile provider implementation, extended by other classes such as [NetworkTileProvider]
///
/// Visit the online documentation at https://docs.fleaflet.dev/usage/layers/tile-layer/tile-providers for more information.
abstract class TileProvider {
  /// Custom headers that may be sent with each tile request, if the specific implementation supports it
  Map<String, String> headers;

  /// The base tile provider implementation, extended by other classes such as [NetworkTileProvider]
  ///
  /// Visit the online documentation at https://docs.fleaflet.dev/usage/layers/tile-layer/tile-providers for more information.
  TileProvider({
    this.headers = const {},
  });

  /// Retrieve a tile as an image, based on it's coordinates and the current [TileLayerOptions]
  ImageProvider getImage(TileCoordinate coords, TileLayer options);

  /// Called when the [TileLayerWidget] is disposed
  void dispose() {}

  String _getTileUrl(
      String urlTemplate, TileCoordinate coords, TileLayer options) {
    final z = _getZoomForUrl(coords, options);

    final data = <String, String>{
      'x': coords.x.toString(),
      'y': coords.y.toString(),
      'z': z.toString(),
      's': getSubdomain(coords, options),
      'r': '@2x',
    };
    if (options.tms) {
      data['y'] = invertY(coords.y, z).toString();
    }
    final allOpts = Map<String, String>.from(data)
      ..addAll(options.additionalOptions);
    return options.templateFunction(urlTemplate, allOpts);
  }

  /// Generate a valid URL for a tile, based on it's coordinates and the current
  /// [TileLayerOptions]
  String getTileUrl(TileCoordinate coords, TileLayer options) {
    final urlTemplate = (options.wmsOptions != null)
        ? options.wmsOptions!
            .getUrl(coords, options.tileSize.toInt(), options.retinaMode)
        : options.urlTemplate;

    return _getTileUrl(urlTemplate!, coords, options);
  }

  /// Generates a valid URL for the [fallbackUrl].
  String? getTileFallbackUrl(TileCoordinate coords, TileLayer options) {
    final urlTemplate = options.fallbackUrl;
    if (urlTemplate == null) return null;
    return _getTileUrl(urlTemplate, coords, options);
  }

  int _getZoomForUrl(TileCoordinate coords, TileLayer options) {
    var zoom = coords.z.toDouble();

    if (options.zoomReverse) {
      zoom = options.maxZoom - zoom;
    }

    return (zoom += options.zoomOffset).round();
  }

  int invertY(int y, int z) {
    return ((1 << z) - 1) - y;
  }

  /// Get a subdomain value for a tile, based on it's coordinates and the current [TileLayerOptions]
  String getSubdomain(TileCoordinate coords, TileLayer options) {
    if (options.subdomains.isEmpty) {
      return '';
    }
    final index = (coords.x + coords.y) % options.subdomains.length;
    return options.subdomains[index];
  }
}

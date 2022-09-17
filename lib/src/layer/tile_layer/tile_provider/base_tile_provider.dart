import 'package:flutter/widgets.dart';

import 'package:flutter_map/flutter_map.dart';

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
  ImageProvider getImage(Coords coords, TileLayer options);

  /// Called when the [TileLayerWidget] is disposed
  void dispose() {}

  String _getTileUrl(String urlTemplate, Coords coords, TileLayer options) {
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
    return options.templateFunction(urlTemplate, allOpts);
  }

  /// Generate a valid URL for a tile, based on it's coordinates and the current
  /// [TileLayerOptions]
  String getTileUrl(Coords coords, TileLayer options) {
    final urlTemplate = (options.wmsOptions != null)
        ? options.wmsOptions!
            .getUrl(coords, options.tileSize.toInt(), options.retinaMode)
        : options.urlTemplate;

    return _getTileUrl(urlTemplate!, coords, options);
  }

  /// Generates a valid URL for the [fallbackUrl].
  String? getTileFallbackUrl(Coords coords, TileLayer options) {
    final urlTemplate = options.fallbackUrl;
    if (urlTemplate == null) return null;
    return _getTileUrl(urlTemplate, coords, options);
  }

  double _getZoomForUrl(Coords coords, TileLayer options) {
    var zoom = coords.z;

    if (options.zoomReverse) {
      zoom = options.maxZoom - zoom;
    }

    return zoom += options.zoomOffset;
  }

  int invertY(int y, int z) {
    return ((1 << z) - 1) - y;
  }

  /// Get a subdomain value for a tile, based on it's coordinates and the current [TileLayerOptions]
  String getSubdomain(Coords coords, TileLayer options) {
    if (options.subdomains.isEmpty) {
      return '';
    }
    final index = (coords.x + coords.y).round() % options.subdomains.length;
    return options.subdomains[index];
  }
}

import 'package:flutter/widgets.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_coordinates.dart';
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
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options);

  /// Called when the [TileLayerWidget] is disposed
  void dispose() {}

  String _getTileUrl(
      String urlTemplate, TileCoordinates coordinates, TileLayer options) {
    final z = _getZoomForUrl(coordinates, options);

    final data = <String, String>{
      'x': coordinates.x.toString(),
      'y': coordinates.y.toString(),
      'z': z.toString(),
      's': getSubdomain(coordinates, options),
      'r': '@2x',
    };
    if (options.tms) {
      data['y'] = invertY(coordinates.y, z).toString();
    }
    final allOpts = Map<String, String>.from(data)
      ..addAll(options.additionalOptions);
    return options.templateFunction(urlTemplate, allOpts);
  }

  /// Generate a valid URL for a tile, based on it's coordinates and the current
  /// [TileLayerOptions]
  String getTileUrl(TileCoordinates coordinates, TileLayer options) {
    final urlTemplate = (options.wmsOptions != null)
        ? options.wmsOptions!
            .getUrl(coordinates, options.tileSize.toInt(), options.retinaMode)
        : options.urlTemplate;

    return _getTileUrl(urlTemplate!, coordinates, options);
  }

  /// Generates a valid URL for the [fallbackUrl].
  String? getTileFallbackUrl(TileCoordinates coordinates, TileLayer options) {
    final urlTemplate = options.fallbackUrl;
    if (urlTemplate == null) return null;
    return _getTileUrl(urlTemplate, coordinates, options);
  }

  int _getZoomForUrl(TileCoordinates coordinates, TileLayer options) {
    var zoom = coordinates.z.toDouble();

    if (options.zoomReverse) {
      zoom = options.maxZoom - zoom;
    }

    return (zoom += options.zoomOffset).round();
  }

  int invertY(int y, int z) {
    return ((1 << z) - 1) - y;
  }

  /// Get a subdomain value for a tile, based on it's coordinates and the current [TileLayerOptions]
  String getSubdomain(TileCoordinates coordinates, TileLayer options) {
    if (options.subdomains.isEmpty) {
      return '';
    }
    final index = (coordinates.x + coordinates.y) % options.subdomains.length;
    return options.subdomains[index];
  }
}

import 'package:flutter/services.dart';
import 'package:flutter_map/src/geo/crs.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/options.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/tile_loader/source_generator_fetcher.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/tile_loader/tile_source.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_coordinates.dart';
import 'package:flutter_map/src/misc/extensions.dart';
import 'package:meta/meta.dart';

/// A tile source generator which generates tiles for the
/// [WMS](https://en.wikipedia.org/wiki/Web_Map_Service) referencing system
@immutable
class WMSGenerator implements TileSourceGenerator<TileSource> {
  /// WMS service's URL, for example 'http://ows.mundialis.de/services/service?'
  final String baseUrl;

  /// List of WMS layers to show
  final List<String> layers;

  /// List of WMS styles
  final List<String> styles;

  /// WMS image format (use 'image/png' for layers with transparency)
  final String format;

  /// Version of the WMS service to use
  final String version;

  /// Whether to make tiles transparent
  final bool transparent;

  /// Encode boolean values as uppercase in request
  final bool uppercaseBoolValue;

  /// Sets map projection standard
  final Crs crs;

  /// The scalar to multiply the calculated width & height for each request by
  ///
  /// This may be used to simulate retina mode, for example, by setting to 2.
  ///
  /// Defaults to 1.
  // TODO: This is simulating retina mode - see README for questions
  final int dimensionsMultiplier;

  /// Other request parameters
  final Map<String, String> otherParameters;

  late final String _encodedBaseUrl;

  late final double _versionNumber;

  /// Create a new [WMSGenerator] instance
  WMSGenerator({
    required this.baseUrl,
    this.layers = const [],
    this.styles = const [],
    this.format = 'image/png',
    this.version = '1.1.1',
    this.transparent = true,
    this.uppercaseBoolValue = false,
    this.crs = const Epsg3857(),
    this.dimensionsMultiplier = 1,
    this.otherParameters = const {},
  }) {
    _versionNumber = double.tryParse(version.split('.').take(2).join('.')) ?? 0;
    _encodedBaseUrl = _buildEncodedBaseUrl();
  }

  String _buildEncodedBaseUrl() {
    final projectionKey = _versionNumber >= 1.3 ? 'crs' : 'srs';
    final buffer = StringBuffer(baseUrl)
      ..write('&service=WMS')
      ..write('&request=GetMap')
      ..write('&layers=${layers.map(Uri.encodeComponent).join(',')}')
      ..write('&styles=${styles.map(Uri.encodeComponent).join(',')}')
      ..write('&format=${Uri.encodeComponent(format)}')
      ..write('&$projectionKey=${Uri.encodeComponent(crs.code)}')
      ..write('&version=${Uri.encodeComponent(version)}')
      ..write(
          '&transparent=${uppercaseBoolValue ? transparent.toString().toUpperCase() : transparent}');
    otherParameters
        .forEach((k, v) => buffer.write('&$k=${Uri.encodeComponent(v)}'));
    return buffer.toString();
  }

  @override
  TileSource call(TileCoordinates coordinates, TileLayerOptions options) {
    final nwPoint = Offset(
      (coordinates.x * options.tileDimension).toDouble(),
      (coordinates.y * options.tileDimension).toDouble(),
    );
    final sePoint =
        nwPoint + (const Offset(1, 1) * options.tileDimension.toDouble());

    final nwCoords = crs.offsetToLatLng(nwPoint, coordinates.z.toDouble());
    final seCoords = crs.offsetToLatLng(sePoint, coordinates.z.toDouble());

    final nw = crs.projection.project(nwCoords);
    final se = crs.projection.project(seCoords);

    final bounds = Rect.fromPoints(nw, se);
    final bbox = (_versionNumber >= 1.3 && crs is Epsg4326)
        ? [bounds.min.dy, bounds.min.dx, bounds.max.dy, bounds.max.dx]
        : [bounds.min.dx, bounds.min.dy, bounds.max.dx, bounds.max.dy];

    return TileSource(
      uri: (StringBuffer(_encodedBaseUrl)
            ..write('&width=${options.tileDimension * dimensionsMultiplier}')
            ..write('&height=${options.tileDimension * dimensionsMultiplier}')
            ..write('&bbox=${bbox.join(',')}'))
          .toString(),
    );
  }
}

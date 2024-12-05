part of 'tile_layer.dart';

/// Options for the []
@immutable
class WMSTileLayerOptions {
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

  /// Other request parameters
  final Map<String, String> otherParameters;

  late final String _encodedBaseUrl;

  late final double _versionNumber;

  /// Create a new [WMSTileLayerOptions] instance.
  WMSTileLayerOptions({
    required this.baseUrl,
    this.layers = const [],
    this.styles = const [],
    this.format = 'image/png',
    this.version = '1.1.1',
    this.transparent = true,
    this.uppercaseBoolValue = false,
    this.crs = const Epsg3857(),
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

  /// Build the URL for a tile
  String getUrl(TileCoordinates coords, int tileDimension, bool retinaMode) {
    final nwPoint = coords * tileDimension;
    final sePoint = nwPoint + Point<int>(tileDimension, tileDimension);
    final nwCoords =
        crs.offsetToLatLng(nwPoint.toOffset(), coords.z.toDouble());
    final seCoords =
        crs.offsetToLatLng(sePoint.toOffset(), coords.z.toDouble());
    final nw = crs.projection.project(nwCoords);
    final se = crs.projection.project(seCoords);
    final bounds = Rect.fromPoints(nw, se);
    final bbox = (_versionNumber >= 1.3 && crs is Epsg4326)
        ? [bounds.min.dy, bounds.min.dx, bounds.max.dy, bounds.max.dx]
        : [bounds.min.dx, bounds.min.dy, bounds.max.dx, bounds.max.dy];

    final buffer = StringBuffer(_encodedBaseUrl);
    buffer.write('&width=${retinaMode ? tileDimension * 2 : tileDimension}');
    buffer.write('&height=${retinaMode ? tileDimension * 2 : tileDimension}');
    buffer.write('&bbox=${bbox.join(',')}');
    return buffer.toString();
  }
}

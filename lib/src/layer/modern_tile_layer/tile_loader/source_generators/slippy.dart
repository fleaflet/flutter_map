import 'package:flutter_map/src/layer/modern_tile_layer/options.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/tile_loader/source.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/tile_loader/source_generator_fetcher.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_coordinates.dart';
import 'package:meta/meta.dart';

@immutable
class SlippyMapGenerator implements TileSourceGenerator<TileSource> {
  final String urlTemplate;
  final String? fallbackUrlTemplate;
  final List<String> subdomains;
  final Map<String, String> additionalPlaceholders;

  final bool tms;

  const SlippyMapGenerator({
    required this.urlTemplate,
    this.fallbackUrlTemplate,
    this.subdomains = const [],
    this.additionalPlaceholders = const {},
    this.tms = false,
  });

  @override
  TileSource call(TileCoordinates coordinates, TileLayerOptions options) {
    final replacementMap = generateReplacementMap(coordinates, options);

    String replacer(Match match) {
      final value = replacementMap[match.group(1)!];
      if (value != null) return value;
      throw ArgumentError('Missing value for placeholder: {${match.group(1)}}');
    }

    final url = urlTemplate.replaceAllMapped(
      templatePlaceholderElement,
      replacer,
    );
    final fallbackUrl = fallbackUrlTemplate?.replaceAllMapped(
      templatePlaceholderElement,
      replacer,
    );

    return TileSource(uri: url, fallbackUri: fallbackUrl);
  }

  @visibleForOverriding
  Map<String, String> generateReplacementMap(
    TileCoordinates coordinates,
    TileLayerOptions options,
  ) {
    final zoom = (options.zoomOffset +
            (options.zoomReverse
                ? options.maxZoom - coordinates.z.toDouble()
                : coordinates.z.toDouble()))
        .round();

    return {
      'x': coordinates.x.toString(),
      'y': (tms ? ((1 << zoom) - 1) - coordinates.y : coordinates.y).toString(),
      'z': zoom.toString(),
      's': subdomains.isEmpty
          ? ''
          : subdomains[(coordinates.x + coordinates.y) % subdomains.length],
      // TODO: Retina mode
      // We can easily implement server retina mode: simulated retina mode
      // requires cooperation with renderer!
      //'r': options.resolvedRetinaMode == RetinaMode.server ? '@2x' : '',
      'd': options.tileDimension.toString(),
      ...additionalPlaceholders,
    };
  }

  static final templatePlaceholderElement = RegExp('{([^{}]*)}');

  @override
  int get hashCode => Object.hash(
        urlTemplate,
        fallbackUrlTemplate,
        subdomains,
        additionalPlaceholders,
        tms,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SlippyMapGenerator &&
          other.urlTemplate == urlTemplate &&
          other.fallbackUrlTemplate == fallbackUrlTemplate &&
          other.subdomains == subdomains &&
          other.additionalPlaceholders == additionalPlaceholders &&
          other.tms == tms);
}

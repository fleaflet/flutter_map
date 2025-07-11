import 'package:flutter_map/src/layer/modern_tile_layer/options.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/tile_loader/source_generator_fetcher.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/tile_loader/tile_source.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_coordinates.dart';
import 'package:meta/meta.dart';

/// A tile source generator which generates tiles for slippy map tile servers
/// following the standard XYZ tile referencing system
///
/// [Slippy maps](https://wiki.openstreetmap.org/wiki/Slippy_map_tilenames) are
/// also known as [tiled web maps](https://en.wikipedia.org/wiki/Tiled_web_map)
/// more generally, or sometimes as 'CARTO'. This is the most common map tile
/// referencing system in use.
///
/// This generator can also support part of the alternative
/// [TMS](https://en.wikipedia.org/wiki/Tile_Map_Service) standard by flipping
/// the Y axis.
@immutable
class XYZGenerator implements TileSourceGenerator<TileSource> {
  /// Template string for tile resources (containing placeholders)
  ///
  /// The following placeholders are supported, in addition to any described in
  /// [additionalPlaceholders] :
  ///
  ///  * `{z}`, `{x}`, `{z}`: tile coordinates
  ///  * `{s}`: subdomain chosen from [subdomains]
  ///  * `{r}`: retina mode (filled with "@2x" when enabled)
  ///  * `{d}`: current [TileLayerOptions.tileDimension]
  final String uriTemplate;

  /// Template string for tile resources used by some [TileSourceFetcher]s if
  /// the request/response to/from the primary [uriTemplate] fails
  ///
  /// > [!WARNING]
  /// > Not all fetchers support falling-back. Note that failing the primary
  /// > template may take some time (such as a HTTP timeout elapsing).
  /// > Additionally, using fallbacks may have negative performance and tile
  /// > usage consequences. See online documentation for more information.
  final String? fallbackUriTemplate;

  /// List of subdomains for the [uriTemplate] (to replace the `{s}`
  /// placeholder)
  ///
  /// > [!NOTE]
  /// > This may no longer be necessary for many tile servers in many cases.
  /// > See online documentation for more information.
  final List<String> subdomains;

  /// Static information that should replace associated placeholders in the
  /// [uriTemplate]
  ///
  /// For example, this could be used to more easily apply API keys to
  /// templates.
  ///
  /// Override [generateReplacementMap] to dynamically generate placeholders.
  final Map<String, String> additionalPlaceholders;

  /// Whether to invert Y axis numbering for tiles
  final bool tms;

  /// A tile source generator which generates tiles for slippy map tile servers
  /// following the standard XYZ tile referencing system
  const XYZGenerator({
    required this.uriTemplate,
    this.fallbackUriTemplate,
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

    final uri = uriTemplate.replaceAllMapped(
      templatePlaceholderElement,
      replacer,
    );
    final fallbackUri = fallbackUriTemplate?.replaceAllMapped(
      templatePlaceholderElement,
      replacer,
    );

    return TileSource(uri: uri, fallbackUri: fallbackUri);
  }

  /// Generates the mapping of [uriTemplate] placeholders to replacements
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

  /// Regex that describes the format of placeholders in a `uriTemplate`
  ///
  /// The regex used prior to v6 originated from leaflet.js, specifically from
  /// commit [dc79b10683d2](https://github.com/Leaflet/Leaflet/commit/dc79b10683d232b9637cbe4d65567631f4fa5a0b).
  /// Prior to that, a more permissive regex was used, starting from commit
  /// [70339807ed6b](https://github.com/Leaflet/Leaflet/commit/70339807ed6bec630ee9c2e96a9cb8356fa6bd86).
  /// It is never mentioned why this regex was used or changed in Leaflet.
  /// This regex is more permissive of the characters it allows.
  static final templatePlaceholderElement = RegExp('{([^{}]*)}');

  @override
  int get hashCode => Object.hash(
        uriTemplate,
        fallbackUriTemplate,
        subdomains,
        additionalPlaceholders,
        tms,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is XYZGenerator &&
          other.uriTemplate == uriTemplate &&
          other.fallbackUriTemplate == fallbackUriTemplate &&
          other.subdomains == subdomains &&
          other.additionalPlaceholders == additionalPlaceholders &&
          other.tms == tms);
}

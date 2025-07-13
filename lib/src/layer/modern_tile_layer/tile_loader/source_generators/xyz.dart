import 'package:flutter_map/src/layer/modern_tile_layer/options.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/tile_loader/source_fetchers/bytes_fetchers/bytes_fetcher.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/tile_loader/source_fetchers/bytes_fetchers/file/file_stub.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/tile_loader/source_fetchers/bytes_fetchers/network/fetcher/network.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/tile_loader/source_generator_fetcher.dart';
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
class XYZGenerator implements TileSourceGenerator<Iterable<String>> {
  /// List of endpoints for tile resources, in XYZ template format
  ///
  /// Endpoints are used by the [TileSourceFetcher] in use, and so their meaning
  /// is context dependent. For example, a HTTP URL would likely be used with
  /// the [NetworkBytesFetcher], whilst a file URI would be used with the
  /// [FileBytesFetcher].
  ///
  /// In all 3 default [SourceBytesFetcher]s, the first endpoint is used for
  /// requests, unless it fails, in which case following endpoints are used as
  /// fallbacks.
  ///
  /// > [!WARNING]
  /// > Using fallbacks may incur a (potentially significant) performance
  /// > penalty, and may not be understood by all [TileSourceFetcher]s.
  /// > Note that failing each endpoint may take some time (such as a HTTP
  /// > timeout elapsing).
  ///
  /// The following placeholders are supported, in addition to any described in
  /// [additionalPlaceholders] :
  ///
  ///  * `{z}`, `{x}`, `{y}`: tile coordinates
  ///  * `{s}`: subdomain chosen from [subdomains]
  ///  * `{r}`: retina mode (filled with "@2x" when enabled)
  ///  * `{d}`: current [TileLayerOptions.tileDimension]
  final List<String> uriTemplates;

  /// List of subdomains for the [uriTemplates] (to replace the `{s}`
  /// placeholder)
  ///
  /// > [!NOTE]
  /// > This may no longer be necessary for many tile servers in many cases.
  /// > See online documentation for more information.
  final List<String> subdomains;

  /// Static information that should replace associated placeholders in the
  /// [uriTemplates]
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
    required this.uriTemplates,
    this.subdomains = const [],
    this.additionalPlaceholders = const {},
    this.tms = false,
  });

  @override
  Iterable<String> call(
    TileCoordinates coordinates,
    TileLayerOptions options,
  ) {
    final replacementMap = generateReplacementMap(coordinates, options);

    String replacer(Match match) {
      final value = replacementMap[match.group(1)!];
      if (value != null) return value;
      throw ArgumentError('Missing value for placeholder: {${match.group(1)}}');
    }

    // Lazily generate URIs as required
    return uriTemplates
        .map((t) => t.replaceAllMapped(templatePlaceholderElement, replacer));
  }

  /// Generates the mapping of [uriTemplates] placeholders to replacements
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
        uriTemplates,
        subdomains,
        additionalPlaceholders,
        tms,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is XYZGenerator &&
          other.uriTemplates == uriTemplates &&
          other.subdomains == subdomains &&
          other.additionalPlaceholders == additionalPlaceholders &&
          other.tms == tms);
}

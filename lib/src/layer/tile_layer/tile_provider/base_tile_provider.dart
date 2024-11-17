import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:meta/meta.dart';

/// The base tile provider, extended by other classes with more specialised
/// purposes and/or requirements
///
/// Prefer extending over implementing.
///
/// For more information, see
/// <https://docs.fleaflet.dev/explanation#tile-providers>, and
/// <https://docs.fleaflet.dev/layers/tile-layer/tile-providers>. For an example
/// extension (with custom [ImageProvider]), see [NetworkTileProvider].
abstract class TileProvider {
  /// Custom HTTP headers that may be sent with each tile request
  ///
  /// Non-networking implementations may ignore this property.
  ///
  /// [TileLayer] will usually automatically set the 'User-Agent' header, based
  /// on the `userAgentPackageName`, but this can be overridden. On the web, this
  /// header cannot be changed, as specified in [TileLayer.tileProvider]'s
  /// documentation, due to a Dart/browser limitation.
  final Map<String, String> headers;

  /// Indicates to flutter_map internals whether to call [getImage] (when
  /// `false`) or [getImageWithCancelLoadingSupport]
  ///
  /// The appropriate method must be overriden, else an [UnimplementedError]
  /// will be thrown.
  ///
  /// [getImageWithCancelLoadingSupport] is designed to allow for implementations
  /// that can cancel HTTP requests or other processing in-flight, when the
  /// underlying tile is disposed before it is loaded. This may increase
  /// performance, and may decrease unnecessary tile requests. Note that this
  /// only applies to the web platform. For more information, and detailed
  /// implementation expectations, see documentation on
  /// [getImageWithCancelLoadingSupport].
  ///
  /// [getImage] does not support cancellation.
  ///
  /// Defaults to `false`. Only needs to be overridden where
  /// [getImageWithCancelLoadingSupport] is in use.
  bool get supportsCancelLoading => false;

  /// Construct the base tile provider and initialise the [headers] property
  ///
  /// This is not a constant constructor, and does not use an initialising
  /// formal, intentionally. To enable [TileLayer] to efficiently (without
  /// [headers] being non-final or unstable `late`) inject the appropriate
  /// 'User-Agent' (based on what is specified by the user), the [headers] [Map]
  /// must not be constant.
  ///
  /// Extenders should add `super.headers` to their constructors if they support
  /// custom HTTP headers. However, they should not provide a constant default
  /// value.
  TileProvider({Map<String, String>? headers}) : headers = headers ?? {};

  /// Retrieve a tile as an image, based on its coordinates and the [TileLayer]
  ///
  /// Usually redirects to a custom [ImageProvider], with one input depending on
  /// [getTileUrl].
  ///
  /// For many implementations, this is the only method that will need
  /// implementing.
  ///
  /// ---
  ///
  /// Does not support cancelling loading tiles, unlike
  /// [getImageWithCancelLoadingSupport]. For this method to be called instead of
  /// that, [supportsCancelLoading] must be `false` (default).
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    throw UnimplementedError(
      'A `TileProvider` that does not override `supportsCancelLoading` to `true` '
      'must override `getImage`',
    );
  }

  /// Retrieve a tile as an image, based on its coordinates and the [TileLayer]
  ///
  /// For this method to be called instead of [getImage], [supportsCancelLoading]
  /// must be overriden to `true`.
  ///
  /// Usually redirects to a custom [ImageProvider], with one parameter using
  /// [getTileUrl], and one using [cancelLoading].
  ///
  /// For many implementations, this is the only method that will need
  /// implementing.
  ///
  /// ---
  ///
  /// Supports cancelling loading tiles, which is designed to allow for
  /// implementations that can cancel HTTP requests or other processing
  /// in-flight, when the underlying tile is disposed before it is loaded. This
  /// may increase performance, and may decrease unnecessary tile requests. Note
  /// that this only applies to the web platform.
  ///
  /// The [cancelLoading] future will complete when the underlying tile is
  /// disposed/pruned. The implementation should therefore listen for its
  /// completion, then cancel the loading. If an image [Codec] is required,
  /// decode [transparentImage] - it will never be visible anyway. Note that
  /// [cancelLoading] will always be completed on disposal, even if the tile has
  /// been fully loaded, but this side effect is not usually an issue.
  ///
  /// See this example with 'package:dio's `CancelToken`:
  ///
  /// ```dart
  /// final cancelToken = CancelToken();
  /// cancelLoading.then((_) => cancelToken.cancel());
  /// ```
  ImageProvider getImageWithCancelLoadingSupport(
    TileCoordinates coordinates,
    TileLayer options,
    Future<void> cancelLoading,
  ) {
    throw UnimplementedError(
      'A `TileProvider` that overrides `supportsCancelLoading` to `true` must '
      'override `getImageWithCancelLoadingSupport`',
    );
  }

  /// Called when the [TileLayer] is disposed
  ///
  /// When disposing resources, ensure that they are not currently being used
  /// by tiles in progress.
  void dispose() {}

  /// Regex that describes the format of placeholders in a `urlTemplate`
  ///
  /// Used internally by [populateTemplatePlaceholders], but may also be used
  /// externally.
  ///
  /// ---
  ///
  /// The regex used prior to v6 originated from leaflet.js, specifically from
  /// commit [dc79b10683d2](https://github.com/Leaflet/Leaflet/commit/dc79b10683d232b9637cbe4d65567631f4fa5a0b).
  /// Prior to that, a more permissive regex was used, starting from commit
  /// [70339807ed6b](https://github.com/Leaflet/Leaflet/commit/70339807ed6bec630ee9c2e96a9cb8356fa6bd86).
  /// It is never mentioned why this regex was used or changed in Leaflet.
  /// This regex is more permissive of the characters it allows.
  static final templatePlaceholderElement = RegExp('{([^{}]*)}');

  /// Replaces placeholders in the form [templatePlaceholderElement] with their
  /// corresponding values
  ///
  /// Avoid using this externally, instead use [getTileUrl] (which uses this) to
  /// automatically handle WMS usage.
  ///
  /// {@macro tile_provider-override_url_gen}
  @visibleForOverriding
  String populateTemplatePlaceholders(
    String urlTemplate,
    TileCoordinates coordinates,
    TileLayer options,
  ) {
    final replacementMap =
        generateReplacementMap(urlTemplate, coordinates, options);

    return urlTemplate.replaceAllMapped(
      templatePlaceholderElement,
      (match) {
        final value = replacementMap[match.group(1)!];
        if (value != null) return value;
        throw ArgumentError(
          'Missing value for placeholder: {${match.group(1)}}',
        );
      },
    );
  }

  /// Generate the [Map] of placeholders to replacements, to be used in
  /// [populateTemplatePlaceholders]
  ///
  /// Instead of overriding this directly, consider using
  /// [TileLayer.additionalOptions] to inject additional placeholders.
  ///
  /// {@macro tile_provider-override_url_gen}
  @visibleForOverriding
  Map<String, String> generateReplacementMap(
    String urlTemplate,
    TileCoordinates coordinates,
    TileLayer options,
  ) {
    final zoom = (options.zoomOffset +
            (options.zoomReverse
                ? options.maxZoom - coordinates.z.toDouble()
                : coordinates.z.toDouble()))
        .round();

    return {
      'x': coordinates.x.toString(),
      'y': (options.tms ? ((1 << zoom) - 1) - coordinates.y : coordinates.y)
          .toString(),
      'z': zoom.toString(),
      's': options.subdomains.isEmpty
          ? ''
          : options.subdomains[
              (coordinates.x + coordinates.y) % options.subdomains.length],
      'r': options.resolvedRetinaMode == RetinaMode.server ? '@2x' : '',
      'd': options.tileSize.toString(),
      ...options.additionalOptions,
    };
  }

  /// Generate a primary URL for a tile, based on its coordinates and the
  /// [TileLayer]
  ///
  /// {@template tile_provider-override_url_gen}
  /// ---
  ///
  /// When creating a specialized [TileProvider], prefer overriding URL
  /// generation related methods in the following order:
  ///
  /// 1. [populateTemplatePlaceholders]
  /// 2. [generateReplacementMap]
  /// 3. [getTileUrl] and/or [getTileFallbackUrl]
  ///
  /// Note to implementors: it is not safe to assume that at least one of
  /// `wmsOptions` or `urlTemplate` will be non-null.
  /// {@endtemplate}
  String getTileUrl(TileCoordinates coordinates, TileLayer options) =>
      populateTemplatePlaceholders(
        options.wmsOptions?.getUrl(
              coordinates,
              options.tileSize.toInt(),
              options.resolvedRetinaMode == RetinaMode.simulation,
            ) ??
            options.urlTemplate ??
            (throw ArgumentError(
                '`wmsOptions` or `urlTemplate` must be provided to generate a tile URL')),
        coordinates,
        options,
      );

  /// Generate a fallback URL for a tile, based on its coordinates and the
  /// [TileLayer]
  ///
  /// {@macro tile_provider-override_url_gen}
  String? getTileFallbackUrl(TileCoordinates coordinates, TileLayer options) {
    final urlTemplate = options.fallbackUrl;
    if (urlTemplate == null) return null;
    return populateTemplatePlaceholders(urlTemplate, coordinates, options);
  }

  /// [Uint8List] that forms a fully transparent image
  ///
  /// Intended to be used with [getImageWithCancelLoadingSupport], so that a
  /// cancelled tile load returns this. It will not be displayed. An error cannot
  /// be thrown from a custom [ImageProvider].
  static final transparentImage = Uint8List.fromList([
    0x89,
    0x50,
    0x4E,
    0x47,
    0x0D,
    0x0A,
    0x1A,
    0x0A,
    0x00,
    0x00,
    0x00,
    0x0D,
    0x49,
    0x48,
    0x44,
    0x52,
    0x00,
    0x00,
    0x00,
    0x01,
    0x00,
    0x00,
    0x00,
    0x01,
    0x08,
    0x06,
    0x00,
    0x00,
    0x00,
    0x1F,
    0x15,
    0xC4,
    0x89,
    0x00,
    0x00,
    0x00,
    0x0A,
    0x49,
    0x44,
    0x41,
    0x54,
    0x78,
    0x9C,
    0x63,
    0x00,
    0x01,
    0x00,
    0x00,
    0x05,
    0x00,
    0x01,
    0x0D,
    0x0A,
    0x2D,
    0xB4,
    0x00,
    0x00,
    0x00,
    0x00,
    0x49,
    0x45,
    0x4E,
    0x44,
    0xAE,
    0x42,
    0x60,
    0x82,
  ]);
}

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/tile_loader/source_fetchers/raster/raster_tile_fetcher.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/tile_loader/source_generator_fetcher.dart';
import 'package:meta/meta.dart';

/// Fetches a tile's bytes based on its source ([S]), transforming it into a
/// desired resource using a supplied [BytesToResourceTransformer]
///
/// Implementers should implement longer-term caching where necessary, or
/// delegate to a cacher. Note that [TileSourceFetcher]s may also perform
/// caching of the resulting resource, often in the short-term - such as the
/// [RasterTileFetcher] using the Flutter [ImageCache].
///
/// Implementations which work with the [RasterTileFetcher] should consider
/// mixing-in [ImageChunkEventsSupport].
abstract interface class SourceBytesFetcher<S extends Object?> {
  /// {@template fm.tilelayer.tilebytesfetcher.call}
  /// Fetches a tile's bytes based on its source ([S]), transforming it into a
  /// desired resource ([R]) using a supplied transformer
  ///
  /// The [abortSignal] completes when the tile is no longer required. If
  /// possible, any ongoing work (such as an HTTP request) should be aborted.
  /// If aborting and a result is unavailable, [TileAbortedException] should be
  /// thrown.
  ///
  /// See [BytesToResourceTransformer] for more information about handling the
  /// [transformer].
  /// {@endtemplate}
  FutureOr<R> call<R>({
    required S source,
    required Future<void> abortSignal,
    required BytesToResourceTransformer<R> transformer,
  });
}

/// Allows a [SourceBytesFetcher] to integrate more closely with the raster tile
/// stack by reporting progress events to the underlying [ImageProvider]
abstract mixin class ImageChunkEventsSupport<S extends Object?>
    implements SourceBytesFetcher<S> {
  /// Redirects to [withImageChunkEventsSink]
  @override
  @nonVirtual
  FutureOr<R> call<R>({
    required S source,
    required Future<void> abortSignal,
    required BytesToResourceTransformer<R> transformer,
  }) =>
      withImageChunkEventsSink<R>(
        source: source,
        abortSignal: abortSignal,
        transformer: transformer,
      );

  /// {@macro fm.tilelayer.tilebytesfetcher.call}
  ///
  /// [chunkEvents] should be used when consolidating a stream of bytes to
  /// report progress notifications to the underlying [ImageProvider].
  FutureOr<R> withImageChunkEventsSink<R>({
    required S source,
    required Future<void> abortSignal,
    required BytesToResourceTransformer<R> transformer,
    StreamSink<ImageChunkEvent>? chunkEvents,
  });
}

/// Exception thrown when a tile was loading but aborted early as it was no
/// longer required
class TileAbortedException<S extends Object?> implements Exception {
  /// Optional description of the tile
  final Object? source;

  /// Exception thrown when a tile was loading but aborted early as it was no
  /// longer required
  const TileAbortedException({this.source});

  @override
  String toString() => 'TileAbortedException: $source';
}

/// Callback provided to a [SourceBytesFetcher] by a root [TileSourceFetcher],
/// which converts fetched bytes into the desired [Resource]
///
/// This may throw if the bytes could not be correctly transformed, for example
/// because they were corrupted or otherwise undecodable. In this case, it is
/// the bytes fetcher's responsibility to catch the error and act accordingly,
/// potentially by returning another (for example, a fallback) resource and/or
/// disabling the long-term caching of this tile. Therefore, it is recommended
/// to always await the result of the callback.
///
/// The [SourceBytesFetcher] should also indicate whether it is acceptable for
/// other parts of the stack (such as the [TileSourceFetcher]) to reuse the
/// resource for tile in the short-term, avoiding having to re-fetch bytes.
/// Other parts of the stack may perform short-term caching (whilst it is the
/// bytes fetcher's responsibility to provide long-term caching) to improve
/// efficiency, for example when the same tile is re-requested for display in
/// the same session. For example, a raster image resource may be cached in
/// memory using the [ImageCache]. However, if this should not occur, because
/// the bytes create a resource different to what is desired (for example, a
/// fallback resource), then `allowReuse` should be set `false`.
typedef BytesToResourceTransformer<Resource extends Object?>
    = FutureOr<Resource> Function(
  Uint8List bytes, {
  bool allowReuse,
});

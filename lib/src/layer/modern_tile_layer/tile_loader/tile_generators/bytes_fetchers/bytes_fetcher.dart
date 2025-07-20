import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/tile_loader/source_tile_generators.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/tile_loader/tile_generators/raster/generator.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/tile_loader/tile_source.dart';
import 'package:logger/logger.dart';

/// Fetches a tile's bytes based on its source ([S]), transforming it into a
/// desired resource using a supplied [BytesToResourceTransformer].
///
/// Implementers should implement longer-term caching where necessary, or
/// delegate to a cacher. Note that [TileGenerator]s may also perform caching of
/// the resulting resource, often in the short-term - such as the
/// [RasterTileGenerator] using the Flutter [ImageCache].
///
/// Implementations which work with the [RasterTileGenerator] should consider
/// mixing-in [ImageChunkEventsSupport].
abstract interface class SourceBytesFetcher<S extends Object?> {
  /// {@template fm.tilelayer.tilebytesfetcher.call}
  /// Fetches a tile's bytes based on its source ([S]), transforming it into a
  /// desired resource ([R]) using a supplied transformer.
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
/// stack by reporting progress events to the underlying [ImageProvider].
abstract mixin class ImageChunkEventsSupport<S extends Object?>
    implements SourceBytesFetcher<S> {
  /// Redirects to [withImageChunkEventsSink].
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
/// longer required.
class TileAbortedException<S extends Object?> implements Exception {
  /// Optional description of the tile.
  final Object? source;

  /// Exception thrown when a tile was loading but aborted early as it was no
  /// longer required.
  const TileAbortedException({this.source});

  @override
  String toString() => 'TileAbortedException: $source';
}

/// Callback provided to a [SourceBytesFetcher] by a root [TileGenerator],
/// which converts fetched bytes into the desired [Resource].
///
/// This may throw if the bytes could not be correctly transformed, for example
/// because they were corrupted or otherwise undecodable. In this case, it is
/// the bytes fetcher's responsibility to catch the error and act accordingly,
/// potentially by returning another (for example, a fallback) resource and/or
/// disabling the long-term caching of this tile.
///
/// ---
///
/// Whilst it is the [SourceBytesFetcher]s or [TileGenerator]s responsibility to
/// implement long-term caching where necessary, other parts of the stack (such
/// as the [TileGenerator]) may also perform short-term caching, which requires
/// a key.
///
/// If the resulting resource differs to what is expected and used as the key
/// - for example, in the case of a fallback being used whilst the only stable
/// key is the primary endpoint - then this must indicate that the resource may
/// not be reused under the key (i.e. not cached). This is done by setting
/// [allowReuse] `false`.
///
/// Implementers should make the default of [allowReuse] `true`.
typedef BytesToResourceTransformer<Resource extends Object?>
    = FutureOr<Resource> Function(Uint8List bytes, {bool allowReuse});

/// Provides utilities to [SourceBytesFetcher]s which consume [Iterable]
/// sources.
extension IterableSourceConsumer<T> on SourceBytesFetcher<Iterable<T>> {
  /// Consecutively execute a callback ([fetcher]) on each element of the
  /// non-empty [source] in iteration order, until the result (as returned by
  /// the [transformer]) is not an error.
  ///
  /// ---
  ///
  /// 'Fallbacks' are all elements of the source except the first (mandatory)
  /// element.
  ///
  /// If any result is a [TileAbortedException], (further) fallbacks are not
  /// attempted. If the first result was [TileAbortedException], it is rethrown.
  ///
  /// If all fallbacks fail or a fallback is aborted, then the error thrown by
  /// the first element is thrown.
  ///
  /// For all fallbacks, the [transformer] is automatically modified to disable
  /// re-use of the bytes. See [BytesToResourceTransformer] for more info. This
  /// meets [TileSource]'s requirements.
  ///
  /// Emits a log for each fallback attempted.
  @protected
  Future<R> fetchFromSourceIterable<R>(
    Future<R> Function(
      T element,
      BytesToResourceTransformer<R> transformer,
      bool isFirst,
    ) fetcher, {
    required Iterable<T> source,
    required BytesToResourceTransformer<R> transformer,
  }) async {
    final firstElement = source.firstOrNull ??
        (throw ArgumentError('must have at least one element', 'source'));

    try {
      return await fetcher(firstElement, transformer, true);
    } on TileAbortedException {
      rethrow; // Don't try fallbacks when aborted
    } on Exception {
      // Lazily initialise logger
      late final logger = Logger(printer: SimplePrinter());

      // Iterate through fallbacks
      for (final fallbackUri in source.skip(1)) {
        if (kDebugMode) {
          logger.w(
            '[flutter_map] Attempting fallback URI ($fallbackUri) instead of '
            '$firstElement',
          );
        }

        try {
          return await fetcher(
            fallbackUri,
            (bytes, {allowReuse = true}) =>
                transformer(bytes, allowReuse: false),
            false,
          );
        } on TileAbortedException {
          // Don't try any further fallbacks when aborted, but still throw
          // the primary URI's exception instead of `TileAbortedException`
          break;
        } on Exception {
          // Attempt further fallbacks
          continue;
        }
      }

      // This means we always throw the exception from the primary URI, when
      // either there are no fallbacks or they have all been exhausted
      rethrow;
    }
  }
}

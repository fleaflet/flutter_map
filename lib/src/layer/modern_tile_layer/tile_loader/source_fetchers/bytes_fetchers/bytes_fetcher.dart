import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/tile_loader/source_fetchers/raster/raster_tile_fetcher.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/tile_loader/source_generator_fetcher.dart';
import 'package:meta/meta.dart';

/// Fetches a tile's bytes based on its 'source' ([S])
///
/// Implementations make no assumption as to what the bytes may represent. For
/// example, it is the [RasterTileFetcher]s responsibility to assume and decode
/// the bytes to a raster image. Therefore, [TileSourceFetcher]s should delegate
/// byte fetching to an implementation if the resource can be represented in
/// bytes, to promote reusability and compatibility.
///
/// Implementers should implement longer-term caching where necessary, or
/// delegate to a cacher. Note that some [TileSourceFetcher]s may also perform
/// caching of the resulting resource, often in the short-term - such as the
/// [RasterTileFetcher] using the Flutter [ImageCache].
///
/// Implementations which work with the [RasterTileFetcher] should consider
/// mixing-in [ImageChunkEventsSupport].
abstract interface class TileBytesFetcher<S extends Object?> {
  /// Fetches a tile's bytes based on its 'source' ([S])
  ///
  /// The [abortSignal] completes when the tile is no longer required. If
  /// possible, any ongoing work (such as an HTTP request) should be aborted.
  /// If aborting and a result is unavailable, [TileAbortedException] should be
  /// thrown.
  FutureOr<Uint8List> call(S source, Future<void> abortSignal);
}

/// Allows a [TileBytesFetcher] to integrate more closely with the raster tile
/// stack by reporting progress events to the underlying [ImageProvider]
abstract mixin class ImageChunkEventsSupport<S extends Object?>
    implements TileBytesFetcher<S> {
  /// Redirects to [withImageChunkEventsSink]
  @override
  @nonVirtual
  FutureOr<Uint8List> call(S source, Future<void> abortSignal) =>
      withImageChunkEventsSink(source, abortSignal);

  /// Fetches a tile's bytes based on its 'source' ([S])
  ///
  /// The [abortSignal] completes when the tile is no longer required. If
  /// possible, any ongoing work (such as an HTTP request) should be aborted.
  /// If aborting and a result is unavailable, [TileAbortedException] should be
  /// thrown.
  ///
  /// [chunkEvents] should be used when consolidating a stream of bytes to
  /// report progress notifications to the underlying [ImageProvider].
  FutureOr<Uint8List> withImageChunkEventsSink(
    S source,
    Future<void> abortSignal, {
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

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/tile_loader/source_fetchers/bytes_fetchers/bytes_fetcher.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/tile_loader/source_fetchers/raster/image_provider.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/tile_loader/source_fetchers/raster/tile_data.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/tile_loader/source_generator_fetcher.dart';

/// A tile source fetcher which delgates fetching of a raster image's bytes to
/// a [TileBytesFetcher], then creates an [ImageProvider] by decoding the bytes
///
/// This is used instead of directly sending the bytes to the renderer, as it
/// hooks into the Flutter image cache, meaning that tiles are cached in memory.
/// Additionally, it is easier for the renderer canvas to work with.
class RasterTileFetcher<S extends Object>
    implements TileSourceFetcher<S, RasterTileData> {
  /// The delegate which provides the bytes for the this tile
  ///
  /// This may not be called for every tile, if the tile was already present in
  /// the ambient [ImageCache].
  final TileBytesFetcher<S> bytesFetcher;

  /// A tile source fetcher which delgates fetching of a raster image's bytes
  /// to a [TileBytesFetcher], then creates an [ImageProvider] by decoding the
  /// bytes
  const RasterTileFetcher({required this.bytesFetcher});

  @override
  RasterTileData call(S source) {
    final abortTrigger = Completer<void>.sync();

    return RasterTileData(
      image: KeyedGeneratedBytesImage(
        // TODO: Include properties of bytes fetcher (hashcode of source + bytesFetcher)?
        key: source,
        bytesGetter: (chunkEvents) {
          if (bytesFetcher case final ImageChunkEventsSupport bytesFetcher) {
            return bytesFetcher.withImageChunkEventsSink(
              source,
              abortTrigger.future,
              chunkEvents: chunkEvents,
            );
          }
          return bytesFetcher(source, abortTrigger.future);
        },
      ),
      dispose: abortTrigger.complete,
    );
  }
}

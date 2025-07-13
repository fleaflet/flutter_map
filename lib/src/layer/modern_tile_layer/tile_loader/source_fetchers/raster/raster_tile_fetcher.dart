import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/tile_loader/tile_loader.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/tile_loader/source_fetchers/bytes_fetchers/bytes_fetcher.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/tile_loader/source_fetchers/raster/image_provider.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/tile_loader/source_fetchers/raster/tile_data.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/tile_loader/source_generator_fetcher.dart';

/// A tile source fetcher which delgates fetching of a raster image's bytes to
/// a [SourceBytesFetcher], then creates an [ImageProvider] by decoding the bytes
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
  final SourceBytesFetcher<S> bytesFetcher;

  /// A tile source fetcher which delgates fetching of a raster image's bytes
  /// to a [SourceBytesFetcher], then creates an [ImageProvider] by decoding the
  /// bytes
  const RasterTileFetcher({required this.bytesFetcher});

  @override
  RasterTileData call(S source) {
    final abortTrigger = Completer<void>.sync();

    // PaintingBinding.instance.imageCache.containsKey(key)

    return RasterTileData(
      image: KeyedDelegatedImage(
        key: (
          source, // TODO: This cannot be used. Maybe .first somehow if we only
          // want to cache primary target (or evict otherwise). Otherwise more
          // complex system required.
          bytesFetcher
        ),
        // TODO: Ideal if we can return a key from the delegate - but need to
        // ensure that key can be looked up in cache without async or waiting
        // for bytes. But then need to make a decision about traversing source
        // with `imageCache.containsKey` vs getting bytes. And, we check cache
        // for primary -> not present, try to fetch primary -> fail, might as
        // well check cache for secondary - but that requires looping outside
        // this constructor!
        delegate: (key, {required chunkEvents, required decode}) async {
          void evict() => scheduleMicrotask(
                () => PaintingBinding.instance.imageCache.evict(key),
              );

          Future<Codec> transformer(Uint8List bytes, {bool allowReuse = true}) {
            if (!allowReuse) evict();
            return ImmutableBuffer.fromUint8List(bytes).then(decode);
          }

          try {
            // await to handle errors
            if (bytesFetcher case final ImageChunkEventsSupport bytesFetcher) {
              return await bytesFetcher.withImageChunkEventsSink(
                source: source,
                abortSignal: abortTrigger.future,
                transformer: transformer,
                chunkEvents: chunkEvents,
              );
            }
            return await bytesFetcher(
              source: source,
              abortSignal: abortTrigger.future,
              transformer: transformer,
            );
          } on TileAbortedException {
            evict();
            return ImmutableBuffer.fromUint8List(TileLoader.transparentImage)
                .then(decode);
          } catch (e) {
            evict();
            rethrow;
          }
        },
      ),
      dispose: abortTrigger.complete,
    )..load();
  }
}

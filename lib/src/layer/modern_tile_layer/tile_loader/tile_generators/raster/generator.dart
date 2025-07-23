import 'dart:async';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/tile_loader/source_generators/xyz.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/tile_loader/source_tile_generators.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/tile_loader/tile_generators/bytes_fetchers/bytes_fetcher.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/tile_loader/tile_generators/bytes_fetchers/network/fetcher/network.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/tile_loader/tile_generators/raster/image_provider.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/tile_loader/tile_generators/raster/tile_data.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/tile_loader/tile_loader.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/tile_loader/tile_source.dart';

/// A tile generator which delgates fetching of a raster image's bytes to
/// a [SourceBytesFetcher], then creates an [ImageProvider] by decoding the
/// bytes.
///
/// The source ([S]) is used as the short-term caching key for the
/// [ImageProvider] (and Flutter's [ImageCache]) - therefore, it must meet the
/// necessary conditions as described by [ImageProvider.obtainKey]
/// (particularly, it must be an object with a useful equality defined).
///
/// This is used instead of directly sending the bytes to the renderer, as it
/// hooks into the Flutter image cache, meaning that tiles are cached in memory.
/// Additionally, it is easier for the renderer canvas to work with.
///
/// ---
///
/// The pre-provided [SourceBytesFetcher]s (such as [NetworkBytesFetcher])
/// consume [Iterable]s of [String]s as a source ([S]), and use the transformer
/// provided by this object to output a [RasterTileData]. This is so that they
/// may be used outside of the context of [TileSource] & [RasterTileGenerator]
/// (for example, in a different stack).
///
/// It is not suitable to use an [Iterable] directly, as it does not meet the
/// criteria for a key. Instead, the pre-provided [SourceGenerator]s (such
/// as [XYZSourceGenerator]) output a [TileSource], which meets all necessary
/// requirements.
///
/// However, this fetcher could be used with any source. For example, if a
/// different [SourceBytesFetcher] is used, it doesn't necessarily need to use
/// [TileSource] or any other contract described above.
class RasterTileGenerator<S extends Object>
    implements TileGenerator<S, RasterTileData> {
  /// The delegate which provides the bytes for the this tile.
  ///
  /// This may not be called for every tile, if the tile was already present in
  /// the ambient [ImageCache].
  final SourceBytesFetcher<S> bytesFetcher;

  /// A tile generator which delgates fetching of a raster image's bytes to a
  /// [SourceBytesFetcher], then creates an [ImageProvider] by decoding the
  /// bytes.
  const RasterTileGenerator({required this.bytesFetcher});

  @override
  RasterTileData call(S source) {
    final abortTrigger = Completer<void>();

    Future<Codec> imageDelegate(
      KeyedDelegatedImage key, {
      required StreamSink<ImageChunkEvent> chunkEvents,
      required ImageDecoderCallback decode,
    }) async {
      void evict() => scheduleMicrotask(
            () => PaintingBinding.instance.imageCache.evict(key),
          );

      Future<Codec> transformer(Uint8List bytes, {bool allowReuse = true}) {
        if (!allowReuse) evict();
        return ImmutableBuffer.fromUint8List(bytes).then(decode);
      }

      try {
        // Must await to handle errors
        if (bytesFetcher
            case ImageChunkEventsSupport(
              withImageChunkEventsSink: final bytesFetcher
            )) {
          return await bytesFetcher(
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
      } on Exception {
        evict();
        rethrow;
      }
    }

    return RasterTileData(
      image: KeyedDelegatedImage(
        key: source,
        delegate: imageDelegate,
      ),
      dispose: abortTrigger.complete,
    )..load();
  }
}

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_map/src/layer/modern_tile_layer/tile_data.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/tile_loader/source_fetchers/bytes_fetchers/bytes_fetcher.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/tile_loader/source_generator_fetcher.dart';

/// A tile source fetcher which delgates fetching of a raster image's bytes to
/// a [TileBytesFetcher], then passes it directly to the renderer (wrapping
/// it in a [WrapperTileData])
///
/// Users should consider whether it would be more efficient or better practise
/// to avoid this class and implement a more custom fetcher for their use-case.
class RawBytesTileFetcher<S extends Object?>
    implements TileSourceFetcher<S, WrapperTileData<Uint8List>> {
  /// The delegate which provides the bytes for the this tile
  final TileBytesFetcher<S> bytesFetcher;

  /// A tile source fetcher which delgates fetching of a raster image's bytes to
  /// a [TileBytesFetcher], then passes it directly to the renderer (wrapping
  /// it in a [WrapperTileData])
  const RawBytesTileFetcher({required this.bytesFetcher});

  @override
  WrapperTileData<Uint8List> call(S source) {
    final abortTrigger = Completer<void>.sync();

    return WrapperTileData(
      data: bytesFetcher(source, abortTrigger.future),
      dispose: abortTrigger.complete,
    );
  }
}

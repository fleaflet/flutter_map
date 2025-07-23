import 'package:flutter_map/src/layer/modern_tile_layer/tile_loader/source_generators/xyz.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/tile_loader/source_tile_generators.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/tile_loader/tile_generators/bytes_fetchers/bytes_fetcher.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/tile_loader/tile_generators/bytes_fetchers/network/fetcher/network.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/tile_loader/tile_generators/raster/generator.dart';
import 'package:meta/meta.dart';

/// Data class for communicating URIs between [SourceGenerator]s
/// (such as [XYZSourceGenerator]) and [TileGenerator]s (such as
/// [RasterTileGenerator]), with ability to be used directly as a short-term
/// cache key* and by [SourceBytesFetcher]s (such as [NetworkBytesFetcher]).
///
/// This carries a [primaryUri] and potentially multiple ordered [fallbackUris].
/// When iterated, this will first yield the [primaryUri], followed by any
/// [fallbackUris] in order.
///
/// > [!WARNING]
/// > The equality of these objects depends only on [primaryUri].
/// > Therefore, where used as a short-term cache key, resources at
/// > [fallbackUris] must not automatically be re-used/cached under the
/// > [primaryUri].
///
/// This is provided as it is used internally and may be used externally by
/// layer implementations for convienience, however it is not required.
@immutable
class TileSource extends Iterable<String> {
  /// Primary URI of the tile.
  final String primaryUri;

  /// Lazily generated URIs of the tile which may be used in the event that the
  /// [primaryUri] cannot be used to retrieve the tile.
  ///
  /// This is not included in the equality of this object. See the documentation
  /// on this class for more info.
  ///
  /// This may be empty or not provided.
  final Iterable<String>? fallbackUris;

  /// Construct a data class for communicating URIs between [SourceGenerator]s
  /// and [TileGenerator]s.
  const TileSource(this.primaryUri, {this.fallbackUris});

  @override
  Iterator<String> get iterator =>
      _TileSourceIterator(primaryUri, fallbackUris?.iterator);

  @override
  int get hashCode => primaryUri.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TileSource && primaryUri == other.primaryUri);
}

class _TileSourceIterator implements Iterator<String> {
  final String _primaryUri;
  final Iterator<String>? _fallbackUris;

  _TileSourceIterator(this._primaryUri, this._fallbackUris);

  String? _current;
  bool _finished = false;

  @override
  bool moveNext() {
    if (_finished) return false;

    if (_current == null) {
      _current = _primaryUri;
      return true;
    }

    if (_fallbackUris == null || !_fallbackUris.moveNext()) {
      _current = null;
      _finished = true;
      return false;
    }

    _current = _fallbackUris.current;
    return true;
  }

  @override
  String get current => _current!;
}

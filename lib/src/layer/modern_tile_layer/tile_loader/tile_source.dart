import 'package:flutter_map/src/layer/modern_tile_layer/tile_loader/bytes_fetcher/bytes_fetcher.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/tile_loader/source_generator/source_generator.dart';
import 'package:meta/meta.dart';

/// Data class for communicating URIs returned by some [SourceGenerator]
/// implementations (such as [XYZSourceGenerator]).
///
/// Carries a [primaryUri] and potentially multiple ordered [fallbackUris].
/// When iterated, this will first yield the [primaryUri], followed by any
/// [fallbackUris] in order.
///
/// This is suitable to be used directly as a short-term cache key*. This may be
/// consumed directly by some [SourceBytesFetcher] implementations (such as
/// [NetworkBytesFetcher]).
///
/// > [!WARNING]
/// > The equality of these objects depends only on [primaryUri].
/// > Therefore, where used as a short-term cache key, resources at
/// > [fallbackUris] **must not** automatically be re-used/cached under the
/// > [primaryUri].
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

  /// Construct a data class for communicating URIs returned by some
  /// [SourceGenerator] implementations.
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

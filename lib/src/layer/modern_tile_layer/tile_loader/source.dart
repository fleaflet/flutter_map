import 'package:flutter_map/src/layer/modern_tile_layer/tile_loader/loader.dart';
import 'package:meta/meta.dart';

/// Default tile 'source' implementation for the default [TileLoader]
/// implementation
@internal
@immutable
class TileSource {
  final String uri;
  final String? fallbackUri;

  const TileSource({required this.uri, this.fallbackUri});

  @override
  int get hashCode => Object.hash(uri, fallbackUri);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TileSource &&
          other.uri == uri &&
          other.fallbackUri == fallbackUri);
}

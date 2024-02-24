part of 'tile_layer.dart';

/// Strategies on how to handle tile errors
enum EvictErrorTileStrategy {
  /// Never evict images for tiles which failed to load.
  none,

  /// Evict images for tiles which failed to load when they are pruned.
  dispose,

  /// Evict images for tiles which failed to load and:
  ///   - do not belong to the current zoom level AND/OR
  ///   - are not visible, respecting the pruning buffer (the maximum of the
  ///     keepBuffer and panBuffer.
  notVisibleRespectMargin,

  /// Evict images for tiles which failed to load and:
  ///   - do not belong to the current zoom level AND/OR
  ///   - are not visible
  notVisible,
}

/// Callback definition for the [TileLayer.errorTileCallback] option.
typedef ErrorTileCallBack = void Function(
  TileImage tile,
  Object error,
  StackTrace? stackTrace,
);

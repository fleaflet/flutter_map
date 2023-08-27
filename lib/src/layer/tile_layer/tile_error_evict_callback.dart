part of 'tile_layer.dart';

@Deprecated(
  'Prefer creating a custom `TileProvider` instead. '
  'This option has been deprecated as it is out of scope for the `TileLayer`. '
  'This option is deprecated since v6.',
)
typedef TemplateFunction = String Function(
  String str,
  Map<String, String> data,
);

enum EvictErrorTileStrategy {
  /// Never evict images for tiles which failed to load.
  none,

  /// Evict images for tiles which failed to load when they are pruned.
  dispose,

  /// Evict images for tiles which failed to load and:
  ///   - do not belong to the current zoom level AND/OR
  ///   - are not visible, respecting the pruning buffer (the maximum of the
  ///     [keepBuffer] and [panBuffer].
  notVisibleRespectMargin,

  /// Evict images for tiles which failed to load and:
  ///   - do not belong to the current zoom level AND/OR
  ///   - are not visible
  notVisible,
}

typedef ErrorTileCallBack = void Function(
  TileImage tile,
  Object error,
  StackTrace? stackTrace,
);

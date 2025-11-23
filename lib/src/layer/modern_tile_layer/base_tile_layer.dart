import 'dart:async';
import 'dart:collection';

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/base_tile_data.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/options.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/tile_loader/tile_loader.dart';
import 'package:latlong2/latlong.dart';
import 'package:meta/meta.dart';

/// A map layer formed from adjacent square tiles loaded individually on demand
///
/// This widget provides the tile management logic, giving responsibility for
/// tile loading and tile rendering to the [tileLoader] & [renderer] delegates
/// respectively.
///
/// This layer is often used to draw the map itself, for example as raster image
/// tiles. However, it may be used for any reasonable purpose where the contract
/// is met.
class BaseTileLayer<D extends BaseTileData> extends StatefulWidget {
  final TileLayerOptions options;
  final TileLoader<D> tileLoader;
  final Widget Function(
    BuildContext context,
    Object layerKey,
    TileLayerOptions options,
    Map<({TileCoordinates coordinates, Object layerKey}), D> visibleTiles,
  ) renderer;

  const BaseTileLayer({
    super.key,
    this.options = const TileLayerOptions(),
    required this.tileLoader,
    required this.renderer,
  });

  @override
  State<BaseTileLayer<D>> createState() => _BaseTileLayerState<D>();
}

class _BaseTileLayerState<D extends BaseTileData>
    extends State<BaseTileLayer<D>> {
  late Object layerKey = UniqueKey();

  final tiles = _TilesTracker<D>();

  @override
  void didUpdateWidget(covariant BaseTileLayer<D> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.options != widget.options ||
        oldWidget.tileLoader != widget.tileLoader ||
        oldWidget.renderer != widget.renderer) {
      layerKey = UniqueKey();
    }
  }

  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.of(context);
    final zoom = camera.zoom.round();
    final visibleTileCoordinates = _getVisibleTiles(camera);

    // Load new tiles
    for (final coordinates in visibleTileCoordinates) {
      final key = (coordinates: coordinates, layerKey: layerKey);
      tiles.putIfAbsent(
        key,
        () => _TileDataWithPrunableIndicator(
          widget.tileLoader(coordinates, widget.options),
        )..triggerPrune.then((_) => _pruneOnLoadedTile(key)),
        // TODO: Consider how to handle errors
      );
    }

    // Prune tiles that are at the same zoom level, but not visible to the camera
    // These tiles are NEVER visible to the camera regardless of their loading
    // status
    tiles.removeWhere(
      (key, _) =>
          key.coordinates.z == zoom &&
          !visibleTileCoordinates.contains(key.coordinates),
    );

    // If all visible tiles are loaded correctly, prune ALL other tiles
    // This is mostly a catch-all, as there is likely some weird edge case
    // that keeps old tiles loaded when they shouldn't be
    final allLoaded = tiles.entries
        .where(
          (tile) =>
              visibleTileCoordinates.contains(tile.key.coordinates) &&
              tile.key.layerKey == layerKey,
        )
        .every((tile) => tile.value.isPrunable);
    if (allLoaded) {
      tiles.removeWhere(
        (key, _) => !visibleTileCoordinates.contains(key.coordinates),
      );
    }

    return widget.renderer(
      context,
      layerKey,
      widget.options,
      Map.unmodifiable(tiles.map((k, v) => MapEntry(k, v._data))),
    );
  }

  /// Eventually pruning could be restricted to tiles if there is an animation
  /// phase that needs to be waited for, quite easily!
  void _pruneOnLoadedTile(_TileKey key) {
    /// PRUNE PHASE
    // Remove all identical tiles of other (old) keys. aka replace my ancestor
    tiles.removeWhere(
      (otherKey, otherData) =>
          otherData.isPrunable &&
          otherKey.coordinates == key.coordinates &&
          otherKey.layerKey != key.layerKey,
    );

    for (final childCoordinates in key.coordinates.children()) {
      // Prune all children
      // TODO decide if children of different keys should be pruned
      // or not
      tiles.removeWhere(
        (otherKey, otherData) =>
            otherData.isPrunable && otherKey.coordinates == childCoordinates,
      );
    }

    // TODO there is still some minor flickering when zooming quickly
    // This appears to be caused by pruning tiles that are loaded but
    // then getting replaced with tiles that get loaded but then pruned.
    // It seems to only happen when zooming more than 1 level at a time

    if (key.coordinates.z != 0) {
      // Ensure that this is not called on the z = 0 tile
      final siblingCoordinates = key.coordinates.parent().children();
      siblingCoordinates.remove(key.coordinates);

      // True when all tiles are loaded with the latest key
      final allLoaded = tiles.entries
          .where(
            (other) =>
                siblingCoordinates.contains(other.key.coordinates) &&
                other.key.layerKey == key.layerKey,
          )
          .every((other) => other.value.isPrunable);

      if (allLoaded) {
        // Prune parent if me and my siblings are all loaded
        // Key does not matter as the tile is getting replaced by
        // tiles with the correct key
        tiles.removeWhere(
          (otherKey, _) => otherKey.coordinates == key.coordinates.parent(),
        );
      }
    }

    /// PRUNE COMPLETE
    if (mounted) {
      setState(() {});
    }
  }

  Offset _floor(Offset point) =>
      Offset(point.dx.floorToDouble(), point.dy.floorToDouble());

  Offset _ceil(Offset point) =>
      Offset(point.dx.ceilToDouble(), point.dy.ceilToDouble());

  Rect _calculatePixelBounds(
    MapCamera camera,
    LatLng center,
    double viewingZoom,
    int tileZoom,
  ) {
    final tileZoomDouble = tileZoom.toDouble();
    final scale = camera.getZoomScale(viewingZoom, tileZoomDouble);
    final pixelCenter = camera.projectAtZoom(center, tileZoomDouble);
    final halfSize = camera.size / (scale * 2);

    return Rect.fromPoints(
      pixelCenter - halfSize.bottomRight(Offset.zero),
      pixelCenter + halfSize.bottomRight(Offset.zero),
    );
  }

  List<TileCoordinates> _getVisibleTiles(MapCamera camera) {
    final pixelBounds = _calculatePixelBounds(
      camera,
      camera.center,
      camera.zoom,
      camera.zoom.round(), // TODO: `maxZoom`?
    );

    final tileBounds = Rect.fromPoints(
      _floor(pixelBounds.topLeft / widget.options.tileDimension.toDouble()),
      _ceil(pixelBounds.bottomRight / widget.options.tileDimension.toDouble()) -
          const Offset(1, 1),
    );

    return [
      for (int x = tileBounds.left.round(); x <= tileBounds.right; x++)
        for (int y = tileBounds.top.round(); y <= tileBounds.bottom; y++)
          TileCoordinates(x, y, camera.zoom.round()),
    ];
  }
}

extension _ParentChildTraversal on TileCoordinates {
  /// This tile coordinate zoomed out by one
  TileCoordinates parent() => z == 0
      ? throw RangeError.range(
          0,
          0,
          null,
          null,
          'Tiles at zoom level 0 are orphans',
        )
      : TileCoordinates(x ~/ 2, y ~/ 2, z - 1);

  /// This tile coordinate but zoomed in by 1
  Set<TileCoordinates> children() {
    final topLeftChild = TileCoordinates(x * 2, y * 2, z + 1);

    return {
      topLeftChild,
      TileCoordinates(topLeftChild.x + 1, topLeftChild.y, topLeftChild.z),
      TileCoordinates(topLeftChild.x, topLeftChild.y + 1, topLeftChild.z),
      TileCoordinates(topLeftChild.x + 1, topLeftChild.y + 1, topLeftChild.z),
    };
  }
}

typedef _TileKey = ({TileCoordinates coordinates, Object layerKey});

extension type _TilesTracker<D extends BaseTileData>._(
        Map<_TileKey, _TileDataWithPrunableIndicator<D>> _map)
    implements Map<_TileKey, _TileDataWithPrunableIndicator<D>> {
  _TilesTracker()
      : this._(
          Map<_TileKey, _TileDataWithPrunableIndicator<D>>(
              /*(a, b) =>
                a.coordinates.z.compareTo(b.coordinates.z) |
                a.coordinates.x.compareTo(b.coordinates.x) |
                a.coordinates.y.compareTo(b.coordinates.y),*/
              ),
        );

  @redeclare
  D? remove(Object? key) => (_map.remove(key)?..dispose())?._data;
}

class _TileDataWithPrunableIndicator<D extends BaseTileData> {
  _TileDataWithPrunableIndicator(D data) : _data = data {
    _data.triggerPrune.then((_) => isPrunable = true);
  }

  final D _data;
  Future<void> get triggerPrune => _data.triggerPrune;
  void dispose() => _data.dispose();

  /// `true` when [BaseTileData.triggerPrune] has completed.
  ///
  /// Triggering pruning implies being fully loaded and therefore ready for self
  /// pruning.
  bool isPrunable = false;
}

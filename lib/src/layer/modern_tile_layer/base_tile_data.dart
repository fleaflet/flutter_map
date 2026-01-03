import 'dart:async';

import 'package:flutter_map/src/layer/modern_tile_layer/base_tile_layer.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/tile_loader/tile_loader.dart';
import 'package:meta/meta.dart';

/// Data associated with a particular tile coordinate, which allows
/// bi-directional communication between the [TileLoader] and
/// [BaseTileLayer.renderer].
///
/// The tile layer's internal logic consumes this interface's fields, and can
/// also manipulate the renderer.
abstract interface class BaseTileData {
  /// Should be completed when the tile is fully optically visible: the tile
  /// layer will start a prune of eligible tiles, and this tile will become
  /// eligible for pruning.
  ///
  /// If the tile never becomes fully optically visible, this shouldn't usually
  /// be completed.
  Future<void> get triggerPrune;

  /// Called when a tile is removed from the map of visible tiles passed to the
  /// renderer.
  ///
  /// This should usually be used to abort loading of the underlying resource
  /// if it has not yet loaded, or release the resources held by it if already
  /// loaded.
  ///
  /// If called, then it is assumed that the tile layer's internal logic no
  /// longer cares about any other field in the object.
  @internal
  void dispose();
}

/// Wrapper for custom-shape data as a [BaseTileData].
///
/// The data carried is usually made available asynchronously, for example as
/// the result of an I/O operation or HTTP request. Alternatively, data may be
/// available synchronously if the data is loaded from prepared memory. This
/// container supports either form of data.
class WrapperTileData<D extends Object?> implements BaseTileData {
  D? _data;

  /// Data resource
  ///
  /// This may be `null` if [D] is nullable & the data is `null`. In this case,
  /// use [isLoaded] to determine whether this accurately reflects the `null`
  /// data. Otherwise, `null` means the data is not yet available.
  D? get data => _data;

  final _loadedTracker = Completer<D>.sync();

  /// Completes with loaded data when the data is loaded successfully
  ///
  /// This never completes if the data completes to an error.
  @override
  Future<D> get triggerPrune => _loadedTracker.future;

  /// Whether [data] represents the loaded data
  bool get isLoaded => _loadedTracker.isCompleted;

  @internal
  @override
  void dispose() => _dispose?.call();
  final void Function()? _dispose;

  /// Create a container with the specified data (or the data result of the
  /// specified future)
  WrapperTileData({
    required FutureOr<D> data,
    void Function()? dispose,
  }) : _dispose = dispose {
    if (data is Future<D>) {
      data.then((data) => _loadedTracker.complete(_data = data));
    } else {
      _loadedTracker.complete(_data = data);
    }
  }
}

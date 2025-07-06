import 'dart:async';

import 'package:meta/meta.dart';

/// Container for custom-shape data associated with a particular tile coordinate
///
/// The data carried is usually made available asynchronously, for example as
/// the result of an I/O operation or HTTP request. Alternatively, data may be
/// available synchronously if the data is loaded from prepared memory. This
/// container supports either form of data.
///
/// The container tracks the status/availability of the data
/// (for asynchronously available data), and optionally provides a handle to
/// enable the request which spawns the data to be aborted if it is no longer
/// required.
///
/// Association with a tile coordinate is made in the tile layer.
class TileData<D extends Object?> {
  D? _data;

  /// Data
  ///
  /// This may be `null` if [D] is nullable & the data is `null`. In this case,
  /// use [isLoaded] to determine whether this accurately reflects the `null`
  /// data. Otherwise, `null` means the data is not yet available.
  D? get data => _data;

  final _loadedTracker = Completer<D>.sync();

  /// Completes with loaded data when the data is loaded successfully
  ///
  /// This never completes if the data completes to an error.
  Future<D> get whenLoaded => _loadedTracker.future;

  /// Whether [data] represents the loaded data
  bool get isLoaded => _loadedTracker.isCompleted;

  /// Abort the ongoing request when the [data] is no longer required
  ///
  /// If called after the data is already available, this should have no effect.
  ///
  /// If called when the data is not yet available, [data] should never become
  /// available, [whenLoaded] should never complete, and [isLoaded] should
  /// remain `false`.
  ///
  /// This may have no effect.
  final void Function() abort;

  /// Create a container with the specified data (or the data result of the
  /// specified future)
  @internal
  TileData({
    required FutureOr<D> data,
    void Function()? abort,
  }) : abort = (abort ?? () {}) {
    if (data is Future<D>) {
      data.then((data) => _loadedTracker.complete(_data = data));
    } else {
      _loadedTracker.complete(_data = data);
    }
  }
}

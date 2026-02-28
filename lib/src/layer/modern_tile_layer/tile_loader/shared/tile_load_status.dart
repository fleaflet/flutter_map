import 'package:flutter_map/src/layer/modern_tile_layer/base_tile_data.dart';
import 'package:meta/meta.dart';

/// Describes what status in the loading process a tile's resource is in.
///
/// Note that this state does not imply whether the tile is visible, or how it's
/// visible. That is ultimately up to the renderer - although it may be
/// influcenced by another property available through the [BaseTileData]
/// implementation for that tile layer.
///
/// A tile can be loading ([LoadingTileStatus]) or loaded. If loaded, it might
/// have successfully loaded ([SuccessfulTileStatus]), or it might have failed
/// due to an error ([ErrorTileStatus]).
sealed class TileLoadStatus {
  /// Constructs a loading state.
  @internal
  const factory TileLoadStatus.loading({required DateTime loadingStarted}) =
      LoadingTileStatus._;

  const TileLoadStatus._({required this.loadingStarted});

  /// The local time at which this tile started loading.
  final DateTime loadingStarted;

  /// Constructs a successful state from a loading state.
  ///
  /// This is offered here for ease of use - although technically a successful
  /// state should not transition to an error state.
  @internal
  SuccessfulTileStatus toSuccess({required DateTime loadingFinished}) =>
      SuccessfulTileStatus._(
        loadingStarted: loadingStarted,
        loadingFinished: loadingFinished,
      );

  /// Constructs an error state from a loading state.
  ///
  /// This is offered here for ease of use - although technically an error state
  /// should not transition to a successful state.
  @internal
  ErrorTileStatus toError({
    required DateTime loadingFinished,
    required Object exception,
    required StackTrace? stackTrace,
  }) =>
      ErrorTileStatus._(
        loadingStarted: loadingStarted,
        loadingFinished: loadingFinished,
        error: exception,
        stackTrace: stackTrace,
      );
}

/// Describes a tile which is still loading its resource.
class LoadingTileStatus extends TileLoadStatus {
  const LoadingTileStatus._({required super.loadingStarted}) : super._();
}

/// Describes a tile which has finished attempting to load its resource.
///
/// It will either be a [SuccessfulTileStatus] or [ErrorTileStatus].
sealed class LoadedTileStatus extends TileLoadStatus {
  const LoadedTileStatus._({
    required super.loadingStarted,
    required this.loadingFinished,
  }) : super._();

  /// The local time at which this tile finished attempting to load.
  final DateTime loadingFinished;
}

/// Describes a tile which successfully loaded its resource.
class SuccessfulTileStatus extends LoadedTileStatus {
  const SuccessfulTileStatus._({
    required super.loadingStarted,
    required super.loadingFinished,
  }) : super._();
}

/// Describes a tile which failed to load its resource.
class ErrorTileStatus extends LoadedTileStatus {
  const ErrorTileStatus._({
    required super.loadingStarted,
    required super.loadingFinished,
    required this.error,
    required this.stackTrace,
  }) : super._();

  /// The error which triggered this state.
  final Object error;

  /// The [StackTrace] of the location where [error] was thrown.
  final StackTrace? stackTrace;
}

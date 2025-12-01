import 'package:meta/meta.dart';

sealed class RasterTileData {
  @internal
  const factory RasterTileData.loading({required DateTime loadingStarted}) =
      LoadingRasterTileData._;

  const RasterTileData._({required this.loadingStarted});

  final DateTime loadingStarted;

  @internal
  SuccessfulRasterTileData toSuccess({required DateTime loadingFinished}) =>
      SuccessfulRasterTileData._(
        loadingStarted: loadingStarted,
        loadingFinished: loadingFinished,
      );

  @internal
  ErrorRasterTileData toError({
    required DateTime loadingFinished,
    required Object exception,
    required StackTrace? stackTrace,
  }) =>
      ErrorRasterTileData._(
        loadingStarted: loadingStarted,
        loadingFinished: loadingFinished,
        exception: exception,
        stackTrace: stackTrace,
      );
}

class LoadingRasterTileData extends RasterTileData {
  const LoadingRasterTileData._({required super.loadingStarted}) : super._();
}

sealed class LoadedRasterTileData extends RasterTileData {
  const LoadedRasterTileData._({
    required super.loadingStarted,
    required this.loadingFinished,
  }) : super._();

  final DateTime loadingFinished;
}

class SuccessfulRasterTileData extends LoadedRasterTileData {
  const SuccessfulRasterTileData._({
    required super.loadingStarted,
    required super.loadingFinished,
  }) : super._();
}

class ErrorRasterTileData extends LoadedRasterTileData {
  const ErrorRasterTileData._({
    required super.loadingStarted,
    required super.loadingFinished,
    required this.exception,
    required this.stackTrace,
  }) : super._();

  final Object exception;
  final StackTrace? stackTrace;
}

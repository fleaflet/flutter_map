import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/base_tile_data.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/tile_loader/raster/tile_loader.dart';
import 'package:meta/meta.dart';

/// Raster tile data associated with a particular tile, used for communication
/// between the [RasterTileLoader] and the raster tile renderer.
///
/// It is not usually necessary to consume this externally.
class RasterTileData implements BaseTileData {
  /// Actual raster [ImageProvider]
  final ImageProvider image;

  final void Function() _dispose;

  /// Raster tile data associated with a particular tile.
  RasterTileData({required this.image, required void Function() dispose})
      : _dispose = dispose;

  bool _isDisposed = false;
  @internal
  @override
  void dispose() {
    _dispose();
    _isDisposed = true;
  }

  DateTime? loadStartedTime;

  final _loadedTracker = Completer<void>();
  @override
  Future<void> get whenLoaded => _loadedTracker.future;

  @override
  bool get isLoaded => loaded != null;
  ({
    DateTime time,
    ImageInfo? successfulImageInfo,
    ({Object exception, StackTrace? stackTrace})? failureInfo,
  })? loaded;

  ImageStream? _imageStream;
  late ImageStreamListener _imageStreamListener;

  void load() {
    // TODO: Consider whether `load` can be called multiple times
    if (_isDisposed) return;

    loadStartedTime = DateTime.now();

    try {
      final oldImageStream = _imageStream;
      _imageStream = image.resolve(ImageConfiguration.empty);

      if (_imageStream!.key != oldImageStream?.key) {
        oldImageStream?.removeListener(_imageStreamListener);

        _imageStreamListener = ImageStreamListener(
          _onImageLoadSuccess,
          onError: _onImageLoadError,
        );
        _imageStream!.addListener(_imageStreamListener);
      }
    } catch (e, s) {
      // Make sure all exceptions are handled - #444 / #536
      _onImageLoadError(e, s);
    }
  }

  void _onImageLoadSuccess(ImageInfo imageInfo, bool synchronousCall) {
    if (_isDisposed) return;

    final isPreviouslyLoaded = loaded != null;

    loaded = (
      time: DateTime.now(),
      successfulImageInfo: imageInfo,
      failureInfo: null
    );
    _loadedTracker.complete();

    _display(isPreviouslyLoaded);
  }

  void _onImageLoadError(Object exception, StackTrace? stackTrace) {
    if (_isDisposed) return;

    final isPreviouslyLoaded = loaded != null;

    loaded = (
      time: DateTime.now(),
      successfulImageInfo: null,
      failureInfo: (exception: exception, stackTrace: stackTrace),
    );
    _loadedTracker.completeError(exception, stackTrace);

    // TODO: Was `if (errorImage != null) _display();`?
    _display(isPreviouslyLoaded);
  }

  void _display(bool isPreviouslyLoaded) {
    /*if (loadError) {
      assert(
        errorImage != null,
        'A TileImage should not be displayed if loading errors and there is no '
        'errorImage to show.',
      );
      _readyToDisplay = true;
      if (!_disposed) notifyListeners();
      return;
    }*/

    /*_tileDisplay.when(
      instantaneous: (_) {
        _readyToDisplay = true;
        if (!_disposed) notifyListeners();
      },
      fadeIn: (fadeIn) {
        final fadeStartOpacity =
            previouslyLoaded ? fadeIn.reloadStartOpacity : fadeIn.startOpacity;

        if (fadeStartOpacity == 1.0) {
          _readyToDisplay = true;
          if (!_disposed) notifyListeners();
        } else {
          _animationController!.reset();
          _animationController!.forward(from: fadeStartOpacity).then((_) {
            _readyToDisplay = true;
            if (!_disposed) notifyListeners();
          });
        }
      },
    );*/
  }
}

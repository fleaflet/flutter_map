import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:meta/meta.dart';

/// Object used to communicate a tile and its raster [image] between the
/// [RasterTileLoader] and the raster tile renderer.
///
/// Only [RasterTileData] should be exposed to users via the tile layer widget.
// TODO: Consider whether to export this. It might be useful for more advanced
// usecases or where overriding the renderer.
@internal
class InternalRasterTileData implements BaseTileData {
  /// The [ImageProvider] of the raster image which is data is about.
  final ImageProvider image;

  /// Method which the tile loader defines to allow it to also respond to the
  /// tile being disposed with [dispose] if necessary.
  final void Function() _dispose;

  /// Create an object used to communicate a tile and its raster [image] between
  /// parts of the raster tile layer stack, and start it loading immediately.
  InternalRasterTileData.createAndLoad({
    required this.image,
    required void Function() dispose,
  }) : _dispose = dispose {
    _load();
  }

  /// The [RasterTileData] which represents this object but is suitable for
  /// public exposure.
  RasterTileData get currentPublicData => _currentPublicData;
  late RasterTileData _currentPublicData;

  /// Available if an image is available (success or error)
  ImageInfo? imageInfo;

  @override
  Future<void> get triggerPrune => _loadedTracker.future;
  final _loadedTracker = Completer<void>();

  bool _isDisposed = false;

  ImageStream? _imageStream;
  late ImageStreamListener _imageStreamListener;

  void _load() {
    // TODO: Consider whether `load` can be called multiple times
    if (_isDisposed) return;

    _currentPublicData = RasterTileData.loading(loadingStarted: DateTime.now());

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

    final isPreviouslyLoaded = _currentPublicData is LoadedRasterTileData;

    _currentPublicData =
        _currentPublicData.toSuccess(loadingFinished: DateTime.now());
    this.imageInfo = imageInfo;
    _loadedTracker.complete();

    _display(isPreviouslyLoaded);
  }

  void _onImageLoadError(Object exception, StackTrace? stackTrace) {
    if (_isDisposed) return;

    final isPreviouslyLoaded = _currentPublicData is LoadedRasterTileData;

    _currentPublicData = _currentPublicData.toError(
      loadingFinished: DateTime.now(),
      exception: exception,
      stackTrace: stackTrace,
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

  @override
  void dispose() {
    _dispose();
    _isDisposed = true;
  }
}

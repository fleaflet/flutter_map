import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';

/// The tile image class
class TileImage extends ChangeNotifier {
  bool _disposed = false;

  /// Controls fade-in opacity.
  AnimationController? _animationController;

  /// Whether the tile is displayable. See [readyToDisplay].
  bool _readyToDisplay = false;

  /// Used by animationController. Still required if animation is disabled in
  /// case the tile display is changed at a later point.
  final TickerProvider vsync;

  /// The z of the coordinate is the TileImage's zoom level whilst the x and y
  /// indicate the position of the tile at that zoom level.
  final TileCoordinates coordinates;

  /// Callback fired when loading finishes with or without an error. This
  /// callback is not triggered after this TileImage is disposed.
  final void Function(TileCoordinates coordinates) onLoadComplete;

  /// Callback fired when an error occurs whilst loading the tile image.
  /// [onLoadComplete] will be called immediately afterwards. This callback is
  /// not triggered after this TileImage is disposed.
  final void Function(TileImage tile, Object error, StackTrace? stackTrace)
      onLoadError;

  /// Options for how the tile image is displayed.
  TileDisplay _tileDisplay;

  /// An optional image to show when a loading error occurs.
  final ImageProvider? errorImage;

  /// Completer that is completed when this object is disposed
  ///
  /// Intended to allow [TileProvider]s to cancel unneccessary HTTP requests.
  final Completer<void> cancelLoading;

  /// [ImageProvider] that loads the image.
  ImageProvider imageProvider;

  /// True if an error occurred during loading.
  bool loadError = false;

  /// When loading started.
  DateTime? loadStarted;

  /// When loading finished.
  DateTime? loadFinishedAt;

  /// Some meta data of the image.
  ///
  /// Ownership: this handle is ALWAYS the tile's own. `RawImage` clones the
  /// image for its `RenderImage` (`createRenderObject`/`updateRenderObject`
  /// both pass `image?.clone()`), so handing it to the widget tree never
  /// transfers ownership — the render object frees its own clone, and this
  /// one stays with the tile until the tile frees it: on frame replacement
  /// and on [dispose].
  ///
  /// The previous model ("the render object takes over at build time") was
  /// wrong and leaked exactly one handle per painted frame: measured on an
  /// iPhone with 768x768 tiles as ~0.3-0.9 leaked handles per tile, invisible
  /// to `ImageCache`, with the process eventually killed by jetsam. GC
  /// finalizers reclaim such handles EVENTUALLY, which is why small default
  /// tiles get away with it — 2.25 MB tiles do not.
  ImageInfo? imageInfo;

  ImageStream? _imageStream;
  late ImageStreamListener _listener;

  /// Create a new object for a tile image.
  TileImage({
    required this.vsync,
    required this.coordinates,
    required this.imageProvider,
    required this.onLoadComplete,
    required this.onLoadError,
    required TileDisplay tileDisplay,
    required this.errorImage,
    required this.cancelLoading,
  })  : _tileDisplay = tileDisplay,
        _animationController = tileDisplay.when(
          instantaneous: (_) => null,
          fadeIn: (fadeIn) => AnimationController(
            vsync: vsync,
            duration: fadeIn.duration,
          ),
        );

  /// Get the current opacity value for the tile image.
  double get opacity => _tileDisplay.when(
        instantaneous: (instantaneous) =>
            _readyToDisplay ? instantaneous.opacity : 0.0,
        fadeIn: (fadeIn) => _animationController!.value,
      )!;

  /// Getter for the tile [AnimationController]
  AnimationController? get animation => _animationController;

  /// Whether the tile is displayable. This means that either:
  ///   * Loading errored but an error image is configured.
  ///   * Loading succeeded and the fade animation has finished.
  ///   * Loading succeeded and there is no fade animation.
  ///
  /// Note that [opacity] can be less than 1 when this is true if instantaneous
  /// tile display is used with a maximum opacity less than 1.
  bool get readyToDisplay => _readyToDisplay;

  /// Change the tile display options.
  set tileDisplay(TileDisplay newTileDisplay) {
    final oldTileDisplay = _tileDisplay;
    _tileDisplay = newTileDisplay;

    // Handle disabling/enabling of animation controller if necessary
    oldTileDisplay.when(
      instantaneous: (instantaneous) {
        newTileDisplay.when(
          fadeIn: (fadeIn) {
            // Became animated.
            _animationController = AnimationController(
              duration: fadeIn.duration,
              vsync: vsync,
              value: _readyToDisplay ? 1.0 : 0.0,
            );
          },
        );
      },
      fadeIn: (fadeIn) {
        newTileDisplay.when(instantaneous: (instantaneous) {
          // No longer animated.
          _animationController!.dispose();
          _animationController = null;
        }, fadeIn: (fadeIn) {
          // Still animated with different fade.
          _animationController!.duration = fadeIn.duration;
        });
      },
    );

    if (!_disposed) notifyListeners();
  }

  /// Initiate loading of the image.
  void load() {
    if (cancelLoading.isCompleted) return;

    loadStarted = DateTime.now();

    try {
      final oldImageStream = _imageStream;
      _imageStream = imageProvider.resolve(ImageConfiguration.empty);

      if (_imageStream!.key != oldImageStream?.key) {
        oldImageStream?.removeListener(_listener);

        _listener = ImageStreamListener(
          _onImageLoadSuccess,
          onError: _onImageLoadError,
        );
        _imageStream!.addListener(_listener);
      }
    } catch (e, s) {
      // Make sure all exceptions are handled - #444 / #536
      _onImageLoadError(e, s);
    }
  }

  void _onImageLoadSuccess(ImageInfo imageInfo, bool synchronousCall) {
    loadError = false;

    // After dispose() the owner that would free this handle is gone (dispose
    // ran and nulled the field — see the ownership note on [imageInfo]), so
    // the handler frees it on the spot.
    //
    // `dispose()` removes the listener, but `setImage` dispatches over a copy
    // of the listener list, so a listener removed from inside that loop is
    // still called. Tiles resolving equal keys share one completer, and
    // `onLoadComplete` is where pruning happens (see the note in
    // `TileImageManager.reloadImages`) — so a tile can be disposed
    // mid-dispatch and handed an image anyway. See `tile_image_test.dart`.
    if (_disposed) {
      imageInfo.dispose();
      return;
    }

    // The previous frame's handle is ours to free — see the ownership note
    // on [imageInfo].
    this.imageInfo?.dispose();
    this.imageInfo = imageInfo;
    _display();
    onLoadComplete(coordinates);
  }

  void _onImageLoadError(Object exception, StackTrace? stackTrace) {
    loadError = true;

    if (!_disposed) {
      _display();
      onLoadError(this, exception, stackTrace);
      onLoadComplete(coordinates);
    }
  }

  // Initiates fading in and marks this TileImage as readyToDisplay when fading
  // finishes. If fading is disabled or a loading error occurred this TileImage
  // becomes readyToDisplay immediately.
  void _display() {
    final previouslyLoaded = loadFinishedAt != null;
    loadFinishedAt = DateTime.now();

    if (loadError) {
      _readyToDisplay = true;
      if (!_disposed) notifyListeners();
      return;
    }

    _tileDisplay.when(
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
    );
  }

  @override
  void dispose({bool evictImageFromCache = false}) {
    assert(
      !_disposed,
      'The TileImage dispose() method was called multiple times',
    );
    _disposed = true;

    if (evictImageFromCache) {
      try {
        imageProvider.evict().catchError((Object e) {
          debugPrint(e.toString());
          return false;
        });
      } catch (e) {
        // This may be never called because catchError will handle errors, however
        // we want to avoid random crashes like in #444 / #536
        debugPrint(e.toString());
      }
    }

    cancelLoading.complete();

    _readyToDisplay = false;
    _animationController?.stop(canceled: false);
    _animationController?.value = 0.0;
    notifyListeners();

    _animationController?.dispose();
    _imageStream?.removeListener(_listener);
    // Same ownership rule as on frame replacement (see [imageInfo]). Nulling
    // the field keeps a straggler build — dispose can race the layer rebuild —
    // from cloning a disposed image; `RawImage` treats null as "paint nothing".
    imageInfo?.dispose();
    imageInfo = null;
    super.dispose();
  }

  @override
  int get hashCode => coordinates.hashCode;

  @override
  bool operator ==(Object other) {
    return other is TileImage && coordinates == other.coordinates;
  }

  @override
  String toString() {
    return 'TileImage($coordinates, readyToDisplay: $_readyToDisplay)';
  }
}

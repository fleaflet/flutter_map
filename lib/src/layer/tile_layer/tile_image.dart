import 'package:flutter/widgets.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_coordinates.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_layer.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_transition.dart';

class TileImage extends ChangeNotifier {
  bool _disposed = false;

  /// Used by animationController. Still required if animation is disabled in
  /// case the tile transition is changed at a later point.
  final TickerProvider vsync;

  /// The z of the coordinate is the TileImage's zoom level whilst the x and y
  /// indicate the position of the tile at that zoom level.
  final TileCoordinates coordinates;

  AnimationController? _animationController;

  /// Callback fired when loading finishes with or withut an error. This
  /// callback is not triggered after this TileImage is disposed.
  final void Function(TileCoordinates coordinates) onLoadComplete;

  /// Callback fired when an error occurs whilst loading the tile image.
  /// [onLoadComplete] will be called immediately afterwards. This callback is
  /// not triggered after this TileImage is disposed.
  final void Function(TileImage tile, Object error, StackTrace? stackTrace)
      onLoadError;

  /// The style of transition.
  TileTransition _transition;

  /// An optional image to show when a loading error occurs.
  final ImageProvider? errorImage;

  ImageProvider imageProvider;

  /// Current tiles are tiles which are in the current tile zoom AND:
  ///   * Are visible OR,
  ///   * Were previously visible and are still within the visible bounds
  ///     expanded by the [TileLayer.keepBuffer].
  bool current = true;

  /// Used during pruning to determine which tiles should be kept.
  bool retain = false;

  /// Whether the tile is displayable. This means that either:
  ///   * Loading errored but there is a tile error image.
  ///   * Loading succeeded and the fade animation has finished.
  ///   * Loading succeeded and there is no fade animation.
  bool _active = false;

  // True if an error occurred during loading.
  bool loadError = false;

  /// When loading started.
  DateTime? loadStarted;

  /// When loading finished.
  DateTime? loadFinishedAt;

  ImageInfo? imageInfo;
  ImageStream? _imageStream;
  late ImageStreamListener _listener;

  TileImage({
    required this.vsync,
    required this.coordinates,
    required this.imageProvider,
    required this.onLoadComplete,
    required this.onLoadError,
    required TileTransition transition,
    required this.errorImage,
  })  : _transition = transition,
        _animationController = transition.map(
          instantaneous: (_) => null,
          faded: (faded) => AnimationController(
            vsync: vsync,
            duration: faded.tileFadeIn.duration,
          ),
        );

  double get opacity => _transition.map(
      instantaneous: (instantaneous) => _active ? instantaneous.opacity : 0.0,
      faded: (faded) => _animationController!.value);

  AnimationController? get animation => _animationController;

  String get coordinatesKey => coordinates.key;

  bool get active => _active;

  // Used to sort TileImages by their distance from the current zoom.
  double zIndex(double maxZoom, int currentZoom) =>
      maxZoom - (currentZoom - coordinates.z).abs();

  // Change the tile transition.
  set transition(TileTransition newTransition) {
    final oldTransition = _transition;
    _transition = newTransition;

    // Handle disabling/enabling of animation controller if necessary
    oldTransition.when(
      instantaneous: (instantaneous) {
        newTransition.when(
          faded: (faded) {
            // Became animated.
            _animationController = AnimationController(
              duration: faded.tileFadeIn.duration,
              vsync: vsync,
              value: _active ? 1.0 : 0.0,
            );
          },
        );
      },
      faded: (faded) {
        newTransition.when(instantaneous: (instantaneous) {
          // No longer animated.
          _animationController!.dispose();
          _animationController = null;
        }, faded: (faded) {
          // Still animated with different fade.
          _animationController!.duration = faded.tileFadeIn.duration;
        });
      },
    );

    if (!_disposed) notifyListeners();
  }

  // Initiate loading of the image.
  void load() {
    loadStarted = DateTime.now();

    try {
      final oldImageStream = _imageStream;
      _imageStream = imageProvider.resolve(ImageConfiguration.empty);

      if (_imageStream!.key != oldImageStream?.key) {
        oldImageStream?.removeListener(_listener);

        _listener = ImageStreamListener(_onImageLoadSuccess,
            onError: _onImageLoadError);
        _imageStream!.addListener(_listener);
      }
    } catch (e, s) {
      // Make sure all exceptions are handled - #444 / #536
      _onImageLoadError(e, s);
    }
  }

  void _onImageLoadSuccess(ImageInfo imageInfo, bool synchronousCall) {
    loadError = false;
    this.imageInfo = imageInfo;

    if (!_disposed) {
      _activate();
      onLoadComplete(coordinates);
    }
  }

  void _onImageLoadError(Object exception, StackTrace? stackTrace) {
    loadError = true;

    if (!_disposed) {
      _activate();
      onLoadError(this, exception, stackTrace);
      onLoadComplete(coordinates);
    }
  }

  void _activate() {
    final previouslyLoaded = loadFinishedAt != null;
    loadFinishedAt = DateTime.now();

    _transition.when(
      instantaneous: (_) {
        _active = true;
        if (!_disposed) notifyListeners();
      },
      faded: (faded) {
        if (loadError && errorImage != null) {
          _active = true;
          if (!_disposed) notifyListeners();
          return;
        }

        final fadeStartOpacity = previouslyLoaded
            ? faded.tileFadeIn.reloadStartOpacity
            : faded.tileFadeIn.startOpacity;

        if (fadeStartOpacity == 1.0) {
          _active = true;
          if (!_disposed) notifyListeners();
          return;
        }

        _animationController!.reset();
        _animationController!.forward(from: fadeStartOpacity).then((_) {
          _active = true;
          if (!_disposed) notifyListeners();
        });
      },
    );
  }

  @override
  void dispose({bool evictImageFromCache = false}) {
    assert(!_disposed);
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

    // Mark the image as inactive.
    _active = false;
    _animationController?.stop(canceled: false);
    _animationController?.value = 0.0;
    notifyListeners();

    _animationController?.dispose();
    _imageStream?.removeListener(_listener);
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
    return 'TileImage($coordinates, active: $_active)';
  }
}

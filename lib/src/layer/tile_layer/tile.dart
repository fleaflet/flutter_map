import 'package:flutter/widgets.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_coordinate.dart';

typedef TileReady = void Function(
    TileCoordinate coords, dynamic error, Tile tile);

class Tile {
  /// The z of the coords is the tile's zoom level whilst the x and y indicate
  /// the coordinate position of the tile at that zoom level.
  final TileCoordinate coordinate;

  ImageProvider imageProvider;

  // If false the tile should be pruned
  bool current;
  bool retain;
  bool active;
  bool loadError;
  DateTime? loaded;
  late DateTime loadStarted;

  final AnimationController? animationController;

  double get opacity => animationController == null
      ? (active ? 1.0 : 0.0)
      : animationController!.value;

  // callback when tile is ready / error occurred
  // it maybe be null for instance when download aborted
  TileReady? tileReady;
  ImageInfo? imageInfo;
  ImageStream? _imageStream;
  late ImageStreamListener _listener;

  Tile({
    required this.coordinate,
    required this.imageProvider,
    required final TickerProvider vsync,
    this.tileReady,
    this.current = false,
    this.active = false,
    this.retain = false,
    this.loadError = false,
    final Duration? duration,
  }) : animationController = duration != null
            ? AnimationController(duration: duration, vsync: vsync)
            : null {
    animationController?.addStatusListener(_onAnimateEnd);
  }

  void loadTileImage() {
    loadStarted = DateTime.now();

    try {
      final oldImageStream = _imageStream;
      _imageStream = imageProvider.resolve(ImageConfiguration.empty);

      if (_imageStream!.key != oldImageStream?.key) {
        oldImageStream?.removeListener(_listener);

        _listener = ImageStreamListener(_tileOnLoad, onError: _tileOnError);
        _imageStream!.addListener(_listener);
      }
    } catch (e, s) {
      // make sure all exception is handled - #444 / #536
      _tileOnError(e, s);
    }
  }

  // call this before GC!
  void dispose([bool evict = false]) {
    if (evict) {
      try {
        imageProvider.evict().catchError((Object e) {
          debugPrint(e.toString());
          return false;
        });
      } catch (e) {
        // this may be never called because catchError will handle errors, however
        // we want to avoid random crashes like in #444 / #536
        debugPrint(e.toString());
      }
    }

    animationController?.removeStatusListener(_onAnimateEnd);
    animationController?.dispose();
    _imageStream?.removeListener(_listener);
  }

  void startFadeInAnimation({double? from}) {
    animationController?.reset();
    animationController?.forward(from: from);
  }

  void _onAnimateEnd(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      active = true;
    }
  }

  void _tileOnLoad(ImageInfo imageInfo, bool synchronousCall) {
    if (tileReady != null) {
      this.imageInfo = imageInfo;
      tileReady!(coordinate, null, this);
    }
  }

  void _tileOnError(dynamic exception, StackTrace? stackTrace) {
    if (tileReady != null) {
      tileReady!(coordinate,
          exception ?? 'Unknown exception during loadTileImage', this);
    }
  }

  String get coordsKey => coordinate.key;

  double zIndex(double maxZoom, int currentZoom) =>
      maxZoom - (currentZoom - coordinate.z).abs();

  @override
  int get hashCode => coordinate.hashCode;

  @override
  bool operator ==(Object other) {
    return other is Tile && coordinate == other.coordinate;
  }
}

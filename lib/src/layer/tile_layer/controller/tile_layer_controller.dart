import 'dart:async';

sealed class TileLayerController {
  factory TileLayerController() => TileLayerControllerImpl();

  /// Trigger reloading of tiles which failed to load.
  void reloadErrorTiles();

  /// Dispose of this controller, should be called when this TileLayerController
  /// is no longer used.
  void dispose();
}

class TileLayerControllerImpl implements TileLayerController {
  final StreamController<void> _streamController;

  TileLayerControllerImpl() : _streamController = StreamController.broadcast();

  Stream<void> get stream => _streamController.stream;

  @override
  void reloadErrorTiles() {
    _streamController.add(null);
  }

  @override
  void dispose() {
    _streamController.close();
  }
}

part of 'base_services.dart';

/// Service to handle the key-trigger and drag gesture to rotate the map. This
/// is by default a CTRL +
class KeyTriggerDragRotateGestureService extends BaseGestureService {
  bool isActive = false;
  final List<LogicalKeyboardKey> keys;

  KeyTriggerDragRotateGestureService({
    required super.controller,
    required this.keys,
  });

  /// Called when the gesture is started, stores important values.
  void start() {
    controller.stopAnimationRaw();
    controller.emitMapEvent(
      MapEventRotateStart(
        camera: _camera,
        source: MapEventSource.keyTriggerDragRotateStart,
      ),
    );
  }

  /// Called when the gesture receives an update, updates the [MapCamera].
  void update(ScaleUpdateDetails details) {
    controller.rotateRaw(
      _camera.rotation - (details.focalPointDelta.dy * 0.5),
      hasGesture: true,
      source: MapEventSource.keyTriggerDragRotate,
    );
  }

  /// Called when the gesture ends, cleans up the previously stored values.
  void end() {
    controller.emitMapEvent(
      MapEventRotateEnd(
        camera: _camera,
        source: MapEventSource.keyTriggerDragRotateEnd,
      ),
    );
  }

  /// Checks if one of the specified keys that enable this gesture is pressed.
  bool get keyPressed => RawKeyboard.instance.keysPressed
      .where((key) => keys.contains(key))
      .isNotEmpty;
}

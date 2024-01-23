part of 'base_services.dart';

/// Service to handle the key-trigger and click gesture to rotate the map.
/// By clicking at the top of the map the map gets set to 0°-ish, by clicking
/// on the left side of the map the rotation is set to 270°-ish.
///
/// The key is by default the CTRL key on the keyboard.
class KeyTriggerClickRotateGestureService extends _BaseGestureService {
  /// Getter for the keyboard keys that trigger the drag to rotate gesture.
  List<LogicalKeyboardKey> get keys =>
      _options.interactionOptions.keyTriggerDragRotateKeys;

  /// Create a new service that rotates the map if the map gets dragged while
  /// a specified key is pressed.
  KeyTriggerClickRotateGestureService({required super.controller});

  /// Called when the gesture receives an update, updates the [MapCamera].
  void update(ScaleUpdateDetails details) {
    controller.rotateRaw(
      _camera.rotation - (details.focalPointDelta.dy * 0.5),
      hasGesture: true,
      source: MapEventSource.keyTriggerDragRotate,
    );
  }

  /// Checks if one of the specified keys that enable this gesture is pressed.
  bool get keyPressed => RawKeyboard.instance.keysPressed
      .where((key) => keys.contains(key))
      .isNotEmpty;

  /// Get the Rotation in degrees in relation to the cursor position.
  ///
  /// By clicking at the top of the map the map gets set to 0°-ish, by clicking
  /// on the left side of the map the rotation is set to 270°-ish.
  ///
  /// Calculation thanks to https://stackoverflow.com/questions/48916517/javascript-click-and-drag-to-rotate
  double getCursorRotationDegrees(Size screenSize, Offset cursorOffset) {
    const correctionTerm = 180; // North = cursor

    return (-math.atan2(cursorOffset.dx - screenSize.width / 2,
                cursorOffset.dy - screenSize.height / 2) *
            radians2Degrees) +
        correctionTerm;
  }
}

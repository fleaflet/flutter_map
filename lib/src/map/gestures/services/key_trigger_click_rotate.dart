part of 'base_services.dart';

/// Service to handle the key-trigger and click gesture to rotate the map.
/// By clicking at the top of the map the map gets set to 0°-ish, by clicking
/// on the left side of the map the rotation is set to 270°-ish.
///
/// The key is by default the CTRL key on the keyboard.
class KeyTriggerClickRotateGestureService extends _BaseGestureService {
  TapDownDetails? details;

  /// Getter for the keyboard keys that trigger the drag to rotate gesture.
  List<LogicalKeyboardKey> get keys =>
      _options.interactionOptions.keyTriggerDragRotateKeys;

  /// Returns true if the service has consumed a [TapDownDetails] for the
  /// tap gesture.
  bool get isActive => details != null;

  /// Create a new service that rotates the map if the map gets dragged while
  /// a specified key is pressed.
  KeyTriggerClickRotateGestureService({required super.controller});

  void setDetails(TapDownDetails newDetails) => details = newDetails;

  void reset() => details = null;

  /// Called when the gesture receives an update, updates the [MapCamera].
  void submit(Size screenSize) {
    if (details == null) return;

    controller.rotateRaw(
      _getCursorRotationDegrees(
        screenSize,
        details!.localPosition,
      ),
      hasGesture: true,
      source: MapEventSource.keyTriggerDragRotate,
    );
  }

  /// Checks if one of the specified keys that enable this gesture is pressed.
  bool get keyPressed => RawKeyboard.instance.keysPressed
      .where((key) => keys.contains(key))
      .isNotEmpty;
}

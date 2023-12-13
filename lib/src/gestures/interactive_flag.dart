/// Use [InteractiveFlag] to disable / enable certain events Use
/// [InteractiveFlag.all] to enable all events, use [InteractiveFlag.none] to
/// disable all events
///
/// If you want mix interactions for example drag and rotate interactions then
/// you have two options:
///   a. Add your own flags: [InteractiveFlag.drag] | [InteractiveFlag.rotate]
///   b. Remove unnecessary flags from all:
///     [InteractiveFlag.all] &
///       ~[InteractiveFlag.flingAnimation] &
///       ~[InteractiveFlag.pinchMove] &
///       ~[InteractiveFlag.pinchZoom] &
///       ~[InteractiveFlag.doubleTapZoom]
abstract class InteractiveFlag {
  const InteractiveFlag._();

  static const int all = drag |
      flingAnimation |
      pinchMove |
      pinchZoom |
      doubleTapZoom |
      doubleTapDragZoom |
      scrollWheelZoom |
      rotate |
      ctrlDragRotate;

  static const int none = 0;

  /// Enable panning with a single finger or cursor
  static const int drag = 1 << 0;

  /// Enable fling animation after panning if velocity is great enough.
  static const int flingAnimation = 1 << 1;

  /// Enable panning with multiple fingers
  static const int pinchMove = 1 << 2;

  /// Enable zooming with a multi-finger pinch gesture
  static const int pinchZoom = 1 << 3;

  /// Enable zooming with a single-finger double tap gesture
  static const int doubleTapZoom = 1 << 4;

  /// Enable zooming with a single-finger double-tap-drag gesture
  ///
  /// The associated [MapEventSource] is [MapEventSource.doubleTapHold].
  static const int doubleTapDragZoom = 1 << 5;

  /// Enable zooming with a mouse scroll wheel
  static const int scrollWheelZoom = 1 << 6;

  /// Enable rotation with two-finger twist gesture
  ///
  /// For controlling cursor/keyboard rotation, see
  /// [InteractionOptions.cursorKeyboardRotationOptions].
  static const int rotate = 1 << 7;

  /// Enable rotation by pressing the CTRL Key and drag the map with the cursor.
  /// To change the key see [InteractionOptions.cursorKeyboardRotationOptions].
  static const int ctrlDragRotate = 1 << 8;

  /// Returns `true` if [leftFlags] has at least one member in [rightFlags]
  /// (intersection) for example [leftFlags]= [InteractiveFlag.drag] |
  /// [InteractiveFlag.rotate] and [rightFlags]= [InteractiveFlag.rotate] |
  /// [InteractiveFlag.flingAnimation] returns true because both have
  /// [InteractiveFlag.rotate] flag
  static bool hasFlag(int leftFlags, int rightFlags) {
    return leftFlags & rightFlags != 0;
  }
}

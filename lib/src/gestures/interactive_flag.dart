import 'package:flutter_map/flutter_map.dart';

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

  /// All available interactive flags, use as `flags: InteractiveFlag.all` to
  /// enable all gestures.
  static const int all = drag |
      flingAnimation |
      pinchMove |
      pinchZoom |
      doubleTapZoom |
      doubleTapDragZoom |
      scrollWheelZoom |
      rotate;

  /// Disable all gesture interactions
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

  /// Flags pertaining to gestures which require multiple fingers.
  static const _multiFingerFlags = pinchMove | pinchZoom | rotate;

  /// Returns `true` if [leftFlags] has at least one member in [rightFlags]
  /// (intersection) for example [leftFlags]= [InteractiveFlag.drag] |
  /// [InteractiveFlag.rotate] and [rightFlags]= [InteractiveFlag.rotate] |
  /// [InteractiveFlag.flingAnimation] returns true because both have
  /// [InteractiveFlag.rotate] flag
  static bool hasFlag(int leftFlags, int rightFlags) {
    return leftFlags & rightFlags != 0;
  }

  /// True if any multi-finger gesture flags are enabled.
  static bool hasMultiFinger(int flags) => hasFlag(flags, _multiFingerFlags);

  /// True if the [drag] interactive flag is enabled.
  static bool hasDrag(int flags) => hasFlag(flags, drag);

  /// True if the [flingAnimation] interactive flag is enabled.
  static bool hasFlingAnimation(int flags) => hasFlag(flags, flingAnimation);

  /// True if the [pinchMove] interactive flag is enabled.
  static bool hasPinchMove(int flags) => hasFlag(flags, pinchMove);

  /// True if the [pinchZoom] interactive flag is enabled.
  static bool hasPinchZoom(int flags) => hasFlag(flags, pinchZoom);

  /// True if the [doubleTapDragZoom] interactive flag is enabled.
  static bool hasDoubleTapDragZoom(int flags) =>
      hasFlag(flags, doubleTapDragZoom);

  /// True if the [doubleTapZoom] interactive flag is enabled.
  static bool hasDoubleTapZoom(int flags) => hasFlag(flags, doubleTapZoom);

  /// True if the [rotate] interactive flag is enabled.
  static bool hasRotate(int flags) => hasFlag(flags, rotate);

  /// True if the [scrollWheelZoom] interactive flag is enabled.
  static bool hasScrollWheelZoom(int flags) => hasFlag(flags, scrollWheelZoom);
}

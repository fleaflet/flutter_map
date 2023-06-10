/// Use [InteractiveFlag] to disable / enable certain events Use
/// [InteractiveFlag.all] to enable all events, use [InteractiveFlag.none] to
/// disable all events
///
/// If you want mix interactions for example drag and rotate interactions then
/// you have two options A.) add you own flags: [InteractiveFlag.drag] |
/// [InteractiveFlag.rotate] B.) remove unnecessary flags from all:
/// [InteractiveFlag.all] & ~[InteractiveFlag.flingAnimation] &
/// ~[InteractiveFlag.pinchMove] & ~[InteractiveFlag.pinchZoom] &
/// ~[InteractiveFlag.doubleTapZoom]
class InteractiveFlag {
  static const int all =
      drag | flingAnimation | pinchMove | pinchZoom | doubleTapZoom | rotate;
  static const int none = 0;

  // Enable move with one finger.
  static const int drag = 1 << 0;

  // Enable fling animation when drag or pinchMove have enough Fling Velocity.
  static const int flingAnimation = 1 << 1;

  // Enable move with two or more fingers.
  static const int pinchMove = 1 << 2;

  // Enable pinch zoom.
  static const int pinchZoom = 1 << 3;

  // Enable double tap zoom animation.
  static const int doubleTapZoom = 1 << 4;

  /// Enable map rotate.
  static const int rotate = 1 << 5;

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

  /// True if the [doubleTapZoom] interactive flag is enabled.
  static bool hasDoubleTapZoom(int flags) => hasFlag(flags, doubleTapZoom);

  /// True if the [rotate] interactive flag is enabled.
  static bool hasRotate(int flags) => hasFlag(flags, rotate);
}

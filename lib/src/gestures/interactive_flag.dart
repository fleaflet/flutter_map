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

  // enable move with one finger
  static const int drag = 1 << 0;

  // enable fling animation when drag or pinchMove have enough Fling Velocity
  static const int flingAnimation = 1 << 1;

  // enable move with two or more fingers
  static const int pinchMove = 1 << 2;

  // enable pinch zoom
  static const int pinchZoom = 1 << 3;

  // enable double tap zoom animation
  static const int doubleTapZoom = 1 << 4;

  // enable map rotate
  static const int rotate = 1 << 5;

  /// Returns `true` if [leftFlags] has at least one member in [rightFlags]
  /// (intersection) for example [leftFlags]= [InteractiveFlag.drag] |
  /// [InteractiveFlag.rotate] and [rightFlags]= [InteractiveFlag.rotate] |
  /// [InteractiveFlag.flingAnimation] returns true because both have
  /// [InteractiveFlag.rotate] flag
  static bool hasFlag(int leftFlags, int rightFlags) {
    return leftFlags & rightFlags != 0;
  }
}

/// Use InteractiveFlags to disable / enable certain events
/// Use InteractiveFlag.all to enable all events, use InteractiveFlag.none to disable all events
///
/// If you want for example use move and rotate interactions you have two options
/// A.) add you own flags: InteractiveFlag.move | InteractiveFlag.rotate
/// B.) remove unnecessary flags from all: InteractiveFlag.all & ~InteractiveFlag.fling & ~InteractiveFlag.pinchZoom & ~InteractiveFlag.doubleTapZoom
class InteractiveFlag {
  static const int all =
      move | fling | pinchZoom | doubleTapZoom | rotate /* | skew */;
  static const int none = 0;

  static const int move = 1 << 0;
  static const int fling = 1 << 1;
  static const int pinchZoom = 1 << 2;
  static const int doubleTapZoom = 1 << 3;
  static const int rotate = 1 << 4;
  // TODO: static const int skew = 1 << 5;

  /// Returns `true` if [leftFlags] has at least one member in [rightFlags]
  /// for example left: InteractiveFlag.move | InteractiveFlag.rotate and right InteractiveFlag.rotate | InteractiveFlag.fling will return true
  static bool hasFlag(int leftFlags, int rightFlags) {
    return leftFlags & rightFlags != 0;
  }
}

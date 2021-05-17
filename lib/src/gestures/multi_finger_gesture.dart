/// Use [MultiFingerGesture] to disable / enable certain gestures Use
/// [MultiFingerGesture.all] to enable all gestures, use
/// [MultiFingerGesture.none] to disable all gestures
///
/// If you want mix gestures for example rotate and pinchZoom gestures then you
/// have two options A.) add you own flags: [MultiFingerGesture.rotate] |
/// [MultiFingerGesture.pinchZoom] B.) remove unnecessary flags from all:
/// [MultiFingerGesture.all] & ~[MultiFingerGesture.pinchMove]
class MultiFingerGesture {
  static const int all = pinchMove | pinchZoom | rotate;
  static const int none = 0;

  // enable move with two or more fingers
  static const int pinchMove = 1 << 0;

  // enable pinch zoom
  static const int pinchZoom = 1 << 1;

  // enable map rotate
  static const int rotate = 1 << 2;

  /// Returns `true` if [leftFlags] has at least one member in [rightFlags]
  /// (intersection) for example [leftFlags]= [MultiFingerGesture.pinchMove] |
  /// [MultiFingerGesture.rotate] and [rightFlags]= [MultiFingerGesture.rotate]
  /// returns true because both have [MultiFingerGesture.rotate] flag
  static bool hasFlag(int leftFlags, int rightFlags) {
    return leftFlags & rightFlags != 0;
  }
}

class InteractiveFlags {
  static const int all =
      move | fling | pinchZoom | doubleTapZoom | rotate /* | skew */;
  static const int none = 0;

  static const int move = 1 << 0;
  static const int fling = 1 << 1;
  static const int pinchZoom = 1 << 2;
  static const int doubleTapZoom = 1 << 3;
  static const int rotate = 1 << 4;
  // TODO: static const int skew = 1 << 5;

  static bool hasFlag(int flags, int currentFlag) {
    return flags & currentFlag != 0;
  }
}

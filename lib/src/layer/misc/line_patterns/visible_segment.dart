part of 'pixel_hiker.dart';

/// Cohen-Sutherland algorithm to clip segments as visible into a canvas.
class VisibleSegment {
  /// Segment between [begin] and [end].
  const VisibleSegment(this.begin, this.end);

  /// Begin of the segment.
  final Offset begin;

  /// End of the segment.
  final Offset end;

  @override
  String toString() => 'VisibleSegment($begin, $end)';

  // OutCodes for the Cohen-Sutherland algorithm
  static const _inside = 0; // 0000
  static const _left = 1; // 0001
  static const _right = 2; // 0010
  static const _bottom = 4; // 0100
  static const _top = 8; // 1000

  static int _computeOutCode(
      double x, double y, double xMin, double yMin, double xMax, double yMax) {
    int code = _inside;

    if (x < xMin) {
      code |= _left;
    } else if (x > xMax) {
      code |= _right;
    }
    if (y < yMin) {
      code |= _bottom;
    } else if (y > yMax) {
      code |= _top;
    }

    return code;
  }

  /// Returns true if the [offset] is inside the [canvasSize] + [strokeWidth].
  static bool isVisible(Offset offset, Size canvasSize, double strokeWidth) =>
      _computeOutCode(
          offset.dx,
          offset.dy,
          -strokeWidth / 2,
          -strokeWidth / 2,
          canvasSize.width + strokeWidth / 2,
          canvasSize.height + strokeWidth / 2) ==
      _inside;

  /// Clips a line segment to a rectangular area (canvas).
  ///
  /// Returns null if the segment is invisible.
  static VisibleSegment? getVisibleSegment(
      Offset p0, Offset p1, Size canvasSize, double strokeWidth) {
    // Function to compute the outCode for a point relative to the canvas

    final double xMin = -strokeWidth / 2;
    final double yMin = -strokeWidth / 2;
    final double xMax = canvasSize.width + strokeWidth / 2;
    final double yMax = canvasSize.height + strokeWidth / 2;

    double x0 = p0.dx;
    double y0 = p0.dy;
    double x1 = p1.dx;
    double y1 = p1.dy;

    int outCode0 = _computeOutCode(x0, y0, xMin, yMin, xMax, yMax);
    int outCode1 = _computeOutCode(x1, y1, xMin, yMin, xMax, yMax);

    while (true) {
      if ((outCode0 | outCode1) == 0) {
        // Both points inside; trivially accept
        // Make sure we return the points within the canvas
        return VisibleSegment(Offset(x0, y0), Offset(x1, y1));
      }

      if ((outCode0 & outCode1) != 0) {
        // Both points share an outside zone; trivially reject
        return null;
      }

      // Could be partially inside; calculate intersection
      final double x;
      final double y;
      final int outCodeOut = outCode0 != 0 ? outCode0 : outCode1;

      if ((outCodeOut & _top) != 0) {
        x = x0 + (x1 - x0) * (yMax - y0) / (y1 - y0);
        y = yMax;
      } else if ((outCodeOut & _bottom) != 0) {
        x = x0 + (x1 - x0) * (yMin - y0) / (y1 - y0);
        y = yMin;
      } else if ((outCodeOut & _right) != 0) {
        y = y0 + (y1 - y0) * (xMax - x0) / (x1 - x0);
        x = xMax;
      } else if ((outCodeOut & _left) != 0) {
        y = y0 + (y1 - y0) * (xMin - x0) / (x1 - x0);
        x = xMin;
      } else {
        // This else block should never be reached.
        return null;
      }

      // Update the point and outCode
      if (outCodeOut == outCode0) {
        x0 = x;
        y0 = y;
        outCode0 = _computeOutCode(x0, y0, xMin, yMin, xMax, yMax);
      } else {
        x1 = x;
        y1 = y;
        outCode1 = _computeOutCode(x1, y1, xMin, yMin, xMax, yMax);
      }
    }
  }
}

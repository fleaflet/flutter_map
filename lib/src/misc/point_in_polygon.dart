import 'dart:math' as math;
import 'dart:ui';

/// Checks whether point [p] is within the specified closed [polygon]
///
/// Uses the even-odd algorithm and requires closed loop polygons, i.e.
/// `polygon.first == polygon.last`.
bool isPointInPolygon(math.Point p, List<Offset> polygon) {
  final len = polygon.length;
  assert(len >= 3, 'not a polygon');
  assert(polygon.first == polygon.last, 'polygon not closed');
  final double px = p.x.toDouble();
  final double py = p.y.toDouble();

  bool isInPolygon = false;
  for (int i = 0, j = len - 1; i < len; j = i++) {
    final double poIx = polygon[i].dx;
    final double poIy = polygon[i].dy;

    final double poJx = polygon[j].dx;
    final double poJy = polygon[j].dy;

    if ((((poIy <= py) && (py < poJy)) || ((poJy <= py) && (py < poIy))) &&
        (px < (poJx - poIx) * (py - poIy) / (poJy - poIy) + poIx)) {
      isInPolygon = !isInPolygon;
    }
  }
  return isInPolygon;
}

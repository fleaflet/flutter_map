import 'package:flutter/widgets.dart';
import 'package:flutter_map/src/map/camera/camera.dart';
import 'package:meta/meta.dart';

/// The part of a pitched map's layer canvas in front of the camera, to which
/// the polygon painter clips polygons before filling them. Flutter 3.27 fills
/// nothing of a path with a vertex behind the camera.
///
/// It is where the perspective divisor is at least half of its value at the
/// bottom edge of the map view. The divisor is linear in canvas coordinates,
/// so the boundary is a line; every visible ground point is in front of it,
/// and the boundary is below the map view, so edges that clipping adds aren't
/// visible.
@internal
class NearClip {
  final double _a;
  final double _b;
  final double _c;

  const NearClip._(this._a, this._b, this._c);

  /// The clip of [camera]'s layer canvas, or null if [camera] is unpitched.
  static NearClip? of(MapCamera camera) {
    if (camera.pitch == 0) return null;
    final size = camera.nonRotatedSize;
    final bottom =
        camera.groundOffsetFromCenter(Offset(size.width / 2, size.height));
    if (bottom == null) return null;
    final origin = camera.pixelOrigin;
    final m = (camera.pixelToScreenTransform
          ..multiply(Matrix4.translationValues(origin.dx, origin.dy, 0)))
        .storage;
    final a = m[3];
    final b = m[7];
    final c = m[15];
    final canvasBottom = camera.projectAtZoom(camera.center) + bottom - origin;
    final threshold = (a * canvasBottom.dx + b * canvasBottom.dy + c) / 2;
    if (!threshold.isFinite || threshold <= 0) return null;
    return NearClip._(a, b, c - threshold);
  }

  double _value(Offset p) => _a * p.dx + _b * p.dy + _c;

  bool _inFront(Offset p) => _value(p) >= 0;

  Offset _boundary(Offset p, Offset q) {
    final vp = _value(p);
    return p + (q - p) * (vp / (vp - _value(q)));
  }

  /// Whether all of [points] are in front of the boundary.
  bool contains(List<Offset> points) => points.every(_inFront);

  /// The part of the polygon [ring] in front of the boundary: [ring] itself if
  /// it is all in front, and empty if none of it is.
  List<Offset> ring(List<Offset> ring) {
    if (contains(ring)) return ring;
    final result = <Offset>[];
    for (var i = 0; i < ring.length; i++) {
      final current = ring[i];
      final previous = ring[(i + ring.length - 1) % ring.length];
      final currentInFront = _inFront(current);
      if (currentInFront != _inFront(previous)) {
        result.add(_boundary(previous, current));
      }
      if (currentInFront) result.add(current);
    }
    return result;
  }
}

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_cover.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_range.dart';
import 'package:flutter_map/src/misc/extensions.dart';
import 'package:latlong2/latlong.dart';
import 'package:meta/meta.dart';

/// Calculates the tiles that cover the ground visible in a [MapCamera], each at
/// the zoom that its size on screen gives.
@immutable
class TileCoverCalculator {
  /// The tile size in pixels.
  final int tileDimension;

  /// Create a new [TileCoverCalculator] instance.
  const TileCoverCalculator({required this.tileDimension});

  /// The tiles that cover the ground visible from [camera], when viewed from
  /// [center] at [viewingZoom] instead of the camera's center and zoom.
  ///
  /// Each tile's zoom is `round(viewingZoom + log2(scale))`, clamped to the
  /// range from [minNativeZoom] to [tileZoom], where scale is the largest size
  /// on screen of one projected pixel within the tile's part of the visible
  /// ground. [tileZoom] is the zoom of an unpitched map: [viewingZoom] rounded,
  /// within the native zoom limits. The visible ground is computed from the
  /// center projected and floored at [tileZoom], so that on an unpitched,
  /// unrotated map the cover is the range of tiles at [tileZoom] that contain
  /// the visible pixel bounds.
  ///
  /// [TileCover.expand] of the result adds only tiles that don't intersect the
  /// visible ground.
  TileCover calculate({
    required MapCamera camera,
    required int tileZoom,
    required int minNativeZoom,
    LatLng? center,
    double? viewingZoom,
  }) =>
      _Cover(
        camera: camera,
        tileDimension: tileDimension,
        tileZoom: tileZoom,
        minNativeZoom: minNativeZoom,
        center: center ?? camera.center,
        viewingZoom: viewingZoom ?? camera.zoom,
      ).tiles();
}

class _Cover {
  final MapCamera camera;
  final int tileDimension;
  final int minNativeZoom;
  final double viewingZoom;

  /// The ground under the corners of [MapCamera.groundViewport], from the
  /// center, in pixels at [viewingZoom].
  final List<Offset> _corners;
  final Offset _pixelCenter;
  final int _tileZoom;
  final _grounds = <int, _Ground>{};

  _Cover({
    required this.camera,
    required this.tileDimension,
    required int tileZoom,
    required this.minNativeZoom,
    required LatLng center,
    required this.viewingZoom,
  })  : _tileZoom = tileZoom,
        _pixelCenter =
            camera.projectAtZoom(center, tileZoom.toDouble()).floor(),
        _corners = camera.nonRotatedSize.isEmpty
            ? const [Offset.zero]
            : camera.visibleGroundFromCenter;

  int _zoomAtScale(double scale) => (viewingZoom + math.log(scale) / math.ln2)
      .round()
      .clamp(minNativeZoom, _tileZoom);

  /// The center in pixels at [zoom].
  Offset _centerAt(int zoom) => zoom == _tileZoom
      ? _pixelCenter
      : _pixelCenter *
          camera.getZoomScale(zoom.toDouble(), _tileZoom.toDouble());

  /// The visible ground in pixels at [zoom].
  _Ground _ground(int zoom) => _grounds.putIfAbsent(zoom, () {
        final center = _centerAt(zoom);
        final scale = camera.getZoomScale(viewingZoom, zoom.toDouble());
        return _Ground(
            [for (final corner in _corners) center + corner / scale]);
      });

  List<Offset> _polygon(int zoom) => _ground(zoom).points;

  TileCover tiles() {
    final startZoom =
        _zoomAtScale(_corners.map(camera.groundScale).reduce(math.min));
    final polygon = _polygon(startZoom);
    final bounds = Rect.fromLTRB(
      polygon.map((p) => p.dx).reduce(math.min),
      polygon.map((p) => p.dy).reduce(math.min),
      polygon.map((p) => p.dx).reduce(math.max),
      polygon.map((p) => p.dy).reduce(math.max),
    );
    final range = DiscreteTileRange.fromPixelBounds(
      zoom: startZoom,
      tileDimension: tileDimension,
      pixelBounds: bounds,
    );
    // An empty viewport touches no tile; like the range, it covers the tile at
    // its position.
    if (bounds.isEmpty) return range;

    final result = <TileCoordinates>[];
    for (final tile in range.coordinates) {
      if (_intersects(tile)) _add(tile, result);
    }
    return TileCover(result, isCovered: _intersects);
  }

  /// Adds [tile], or its descendants if the visible ground in it needs a finer
  /// zoom.
  void _add(TileCoordinates tile, List<TileCoordinates> result) {
    final clipped = _clip(_polygon(tile.z), _square(tile));
    if (clipped.isEmpty) {
      result.add(tile);
      return;
    }
    final toViewingZoom = camera.getZoomScale(viewingZoom, tile.z.toDouble());
    final center = _centerAt(tile.z);
    final scale = clipped
        .map((p) => camera.groundScale((p - center) * toViewingZoom))
        .reduce(math.max);
    if (_zoomAtScale(scale) <= tile.z) {
      result.add(tile);
      return;
    }
    for (final (i, j) in const [(0, 0), (1, 0), (0, 1), (1, 1)]) {
      final child = TileCoordinates(2 * tile.x + i, 2 * tile.y + j, tile.z + 1);
      if (_intersects(child)) _add(child, result);
    }
  }

  Rect _square(TileCoordinates tile) => Rect.fromLTWH(
        (tile.x * tileDimension).toDouble(),
        (tile.y * tileDimension).toDouble(),
        tileDimension.toDouble(),
        tileDimension.toDouble(),
      );

  /// Whether [tile] and the visible ground overlap in more than an edge, as
  /// in [DiscreteTileRange.fromPixelBounds].
  bool _intersects(TileCoordinates tile) => _ground(tile.z).overlaps(
        (tile.x * tileDimension).toDouble(),
        (tile.y * tileDimension).toDouble(),
        tileDimension.toDouble(),
      );

  /// The part of the convex [polygon] inside [rect].
  static List<Offset> _clip(List<Offset> polygon, Rect rect) {
    var points = polygon;
    for (final (inside, intersect)
        in <(bool Function(Offset), Offset Function(Offset, Offset))>[
      ((p) => p.dx >= rect.left, (a, b) => _atX(a, b, rect.left)),
      ((p) => p.dx <= rect.right, (a, b) => _atX(a, b, rect.right)),
      ((p) => p.dy >= rect.top, (a, b) => _atY(a, b, rect.top)),
      ((p) => p.dy <= rect.bottom, (a, b) => _atY(a, b, rect.bottom)),
    ]) {
      final input = points;
      points = [];
      for (var i = 0; i < input.length; i++) {
        final current = input[i];
        final previous = input[(i + input.length - 1) % input.length];
        if (inside(current)) {
          if (!inside(previous)) points.add(intersect(previous, current));
          points.add(current);
        } else if (inside(previous)) {
          points.add(intersect(previous, current));
        }
      }
      if (points.isEmpty) break;
    }
    return points;
  }

  static Offset _atX(Offset a, Offset b, double x) =>
      Offset(x, a.dy + (b.dy - a.dy) * (x - a.dx) / (b.dx - a.dx));

  static Offset _atY(Offset a, Offset b, double y) =>
      Offset(a.dx + (b.dx - a.dx) * (y - a.dy) / (b.dy - a.dy), y);
}

/// A convex polygon, prepared for a separating axis test against squares.
class _Ground {
  final List<Offset> points;

  /// The x and y axes, and the normals of the edges that aren't along them.
  final List<Offset> _axes;

  /// The smallest and largest projection of [points] onto each of [_axes].
  final List<double> _mins;
  final List<double> _maxs;

  factory _Ground(List<Offset> points) {
    final axes = [const Offset(1, 0), const Offset(0, 1)];
    for (var i = 0; i < points.length; i++) {
      final edge = points[(i + 1) % points.length] - points[i];
      if (edge.dx != 0 && edge.dy != 0) axes.add(Offset(-edge.dy, edge.dx));
    }
    final mins = <double>[];
    final maxs = <double>[];
    for (final axis in axes) {
      var min = double.infinity;
      var max = double.negativeInfinity;
      for (final p in points) {
        final d = p.dx * axis.dx + p.dy * axis.dy;
        if (d < min) min = d;
        if (d > max) max = d;
      }
      mins.add(min);
      maxs.add(max);
    }
    return _Ground._(points, axes, mins, maxs);
  }

  const _Ground._(this.points, this._axes, this._mins, this._maxs);

  /// Whether the square at [left], [top] with sides of [size] and this polygon
  /// overlap in more than an edge.
  bool overlaps(double left, double top, double size) {
    final right = left + size;
    final bottom = top + size;
    for (var i = 0; i < _axes.length; i++) {
      final axis = _axes[i];
      final x0 = axis.dx * left;
      final x1 = axis.dx * right;
      final y0 = axis.dy * top;
      final y1 = axis.dy * bottom;
      final min = math.min(x0, x1) + math.min(y0, y1);
      final max = math.max(x0, x1) + math.max(y0, y1);
      if (_maxs[i] <= min || max <= _mins[i]) return false;
    }
    return true;
  }
}

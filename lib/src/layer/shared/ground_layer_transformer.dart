import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/src/layer/shared/billboard_layer_transformer.dart';
import 'package:flutter_map/src/map/camera/camera.dart';
import 'package:flutter_map/src/map/options/options.dart';

/// Places a [child] widget tree on the ground, so that it moves, rotates and
/// pitches with the [MapCamera]
///
/// The child is laid out in [MapCamera.size], with its top-left corner at
/// [MapCamera.pixelOrigin], so draw a coordinate at
/// `projectAtZoom(coordinate) - pixelOrigin`. Use it for content that lies on
/// the ground, such as tiles and polygons. Content that should face the
/// viewer, such as markers and labels, belongs in a
/// [BillboardLayerTransformer].
///
/// Above a pitch of about 70.8 degrees, the visible ground ends at a far limit
/// in the map view. Above the far limit, the layer draws nothing and
/// [MapOptions.backgroundColor] shows.
///
/// Formerly named [MobileLayerTransformer].
class GroundLayerTransformer extends StatelessWidget {
  /// Places a [child] widget tree on the ground.
  const GroundLayerTransformer({super.key, required this.child});

  /// The layer content that should get transformed by
  /// the [GroundLayerTransformer].
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.of(context);

    // The child's top-left corner is at [MapCamera.pixelOrigin], which is not
    // centered on the map's center when pitched.
    final origin = camera.pixelOrigin;
    return OverflowBox(
      alignment: Alignment.topLeft,
      minWidth: camera.size.width,
      maxWidth: camera.size.width,
      minHeight: camera.size.height,
      maxHeight: camera.size.height,
      child: Transform(
        transform: camera.pixelToScreenTransform
          ..multiply(Matrix4.translationValues(origin.dx, origin.dy, 0)),
        child: camera.pitch == 0 ? child : _clipToGround(camera, origin),
      ),
    );
  }

  /// [child] clipped to the visible ground, because a point behind the camera
  /// would be drawn mirrored, and nothing is drawn beyond the far limit.
  Widget _clipToGround(MapCamera camera, Offset origin) {
    final fromOrigin = camera.projectAtZoom(camera.center) - origin;
    final ground = [
      for (final corner in camera.visibleGroundFromCenter) fromOrigin + corner,
    ];
    return ClipPath(clipper: _PolygonClipper(ground), child: child);
  }
}

class _PolygonClipper extends CustomClipper<Path> {
  final List<Offset> points;

  const _PolygonClipper(this.points);

  @override
  Path getClip(Size size) => Path()..addPolygon(points, true);

  @override
  bool shouldReclip(_PolygonClipper oldClipper) =>
      !listEquals(oldClipper.points, points);
}

/// Renamed to [GroundLayerTransformer].
@Deprecated('Renamed to GroundLayerTransformer')
typedef MobileLayerTransformer = GroundLayerTransformer;

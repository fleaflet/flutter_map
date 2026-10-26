import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/src/map/camera/camera.dart';

/// Transforms a [child] widget tree into a layer that can move and rotate based
/// on the [MapCamera]
class MobileLayerTransformer extends StatelessWidget {
  /// Transforms a [child] widget tree into a layer that can move and rotate based
  /// on the [MapCamera].
  const MobileLayerTransformer({super.key, required this.child});

  /// The layer content that should get transformed by
  /// the [MobileLayerTransformer].
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.of(context);

    if (camera.pitch == 0) {
      return OverflowBox(
        minWidth: camera.size.width,
        maxWidth: camera.size.width,
        minHeight: camera.size.height,
        maxHeight: camera.size.height,
        child: Transform.rotate(angle: camera.rotationRad, child: child),
      );
    }

    // The child's top-left corner is at [MapCamera.pixelOrigin], which is not
    // centered on the map's center when pitched.
    final origin = camera.pixelOrigin;
    // Clipped to the visible ground, because a point behind the camera would
    // be drawn mirrored, and nothing is drawn beyond the far limit.
    final fromOrigin = camera.projectAtZoom(camera.center) - origin;
    final ground = [
      for (final corner in camera.visibleGroundFromCenter) fromOrigin + corner,
    ];
    return OverflowBox(
      alignment: Alignment.topLeft,
      minWidth: camera.size.width,
      maxWidth: camera.size.width,
      minHeight: camera.size.height,
      maxHeight: camera.size.height,
      child: Transform(
        transform: camera.pixelToScreenTransform
          ..multiply(Matrix4.translationValues(origin.dx, origin.dy, 0)),
        child: ClipPath(
          clipper: _PolygonClipper(ground),
          child: child,
        ),
      ),
    );
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

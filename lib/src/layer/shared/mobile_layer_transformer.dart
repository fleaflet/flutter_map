import 'package:flutter/widgets.dart';
import 'package:flutter_map/src/layer/shared/billboard_layer_transformer.dart';
import 'package:flutter_map/src/map/camera/camera.dart';

/// Places a [child] widget tree on the ground, so that it moves, rotates and
/// pitches with the [MapCamera]
///
/// The child is laid out in [MapCamera.size], with its top-left corner at
/// [MapCamera.pixelOrigin], so draw a coordinate at
/// `projectAtZoom(coordinate) - pixelOrigin`. Use it for content that lies on
/// the ground, such as tiles and polygons. Content that should face the
/// viewer, such as markers and labels, belongs in a
/// [BillboardLayerTransformer].
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
        child: child,
      ),
    );
  }
}

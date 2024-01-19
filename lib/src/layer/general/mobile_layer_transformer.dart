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

    return OverflowBox(
      minWidth: camera.size.x,
      maxWidth: camera.size.x,
      minHeight: camera.size.y,
      maxHeight: camera.size.y,
      child: Transform.rotate(angle: camera.rotationRad, child: child),
    );
  }
}

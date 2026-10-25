import 'package:flutter/widgets.dart';
import 'package:flutter_map/src/layer/shared/mobile_layer_transformer.dart';
import 'package:flutter_map/src/map/camera/camera.dart';

/// Places a [child] widget tree in screen space, unaffected by the map's
/// rotation and pitch, so that it can draw upright widgets at the screen
/// positions of coordinates (see [MapCamera.latLngToScreenOffset])
///
/// Use it for content that should face the viewer, such as markers and
/// labels. Content that lies on the ground, such as tiles and polygons,
/// belongs in a [MobileLayerTransformer].
class BillboardLayerTransformer extends StatelessWidget {
  /// Places a [child] widget tree in screen space.
  const BillboardLayerTransformer({super.key, required this.child});

  /// The layer content, laid out in the map's view size.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.of(context);

    return OverflowBox(
      alignment: Alignment.topLeft,
      minWidth: camera.nonRotatedSize.width,
      maxWidth: camera.nonRotatedSize.width,
      minHeight: camera.nonRotatedSize.height,
      maxHeight: camera.nonRotatedSize.height,
      child: child,
    );
  }
}

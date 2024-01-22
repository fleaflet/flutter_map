import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

part 'overlay_image.dart';

/// [OverlayImageLayer] is used to display one or multiple images on the map.
///
/// Note that the [OverlayImageLayer] needs to be placed after every non
/// translucent layer in the [FlutterMap.children] list to be actually visible!
@immutable
class OverlayImageLayer extends StatelessWidget {
  /// The images that the map should get overlayed with.
  final List<BaseOverlayImage> overlayImages;

  /// Create a new [OverlayImageLayer].
  const OverlayImageLayer({super.key, required this.overlayImages});

  @override
  Widget build(BuildContext context) => MobileLayerTransformer(
        child: ClipRect(child: Stack(children: overlayImages)),
      );
}

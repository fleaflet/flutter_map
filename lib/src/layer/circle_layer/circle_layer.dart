import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;

part 'circle_marker.dart';
part 'painter.dart';

/// A layer that displays a list of [CircleMarker] on the map
@immutable
class CircleLayer extends StatelessWidget {
  /// The list of [CircleMarker]s.
  final List<CircleMarker> circles;

  /// Create a new [CircleLayer] as a child for flutter map
  const CircleLayer({super.key, required this.circles});

  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.of(context);
    return MobileLayerTransformer(
      child: CustomPaint(
        painter: CirclePainter(circles, camera),
        size: Size(camera.size.x, camera.size.y),
        isComplex: true,
      ),
    );
  }
}

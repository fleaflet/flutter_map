import 'dart:math';
import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;

part 'circle_marker.dart';
part 'painter.dart';

/// A layer that displays a list of [CircleMarker] on the map
@immutable
class CircleLayer<R extends Object> extends StatelessWidget {
  /// The list of [CircleMarker]s.
  final List<CircleMarker<R>> circles;

  /// A notifier to be notified when a hit test occurs on the layer
  ///
  /// Notified with a [LayerHitResult] if any polylines are hit, otherwise
  /// notified with `null`.
  ///
  /// Hit testing still occurs even if this is `null`.
  ///
  /// See online documentation for more detailed usage instructions. See the
  /// example project for an example implementation.
  final LayerHitNotifier<R>? hitNotifier;

  /// Create a new [CircleLayer] as a child for flutter map
  const CircleLayer({
    super.key,
    required this.circles,
    this.hitNotifier,
  });

  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.of(context);
    return MobileLayerTransformer(
      child: CustomPaint(
        painter: CirclePainter(
          circles: circles,
          camera: camera,
          hitNotifier: hitNotifier,
        ),
        size: Size(camera.size.x, camera.size.y),
        isComplex: true,
      ),
    );
  }
}

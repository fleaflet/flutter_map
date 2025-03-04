import 'dart:math';
import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/layer/shared/feature_layer_utils.dart';
import 'package:flutter_map/src/layer/shared/layer_interactivity/internal_hit_detectable.dart';
import 'package:latlong2/latlong.dart' hide Path;

part 'circle_marker.dart';
part 'painter.dart';

/// A layer that displays a list of [CircleMarker] on the map
@immutable
class CircleLayer<R extends Object> extends StatelessWidget {
  /// The list of [CircleMarker]s.
  final List<CircleMarker<R>> circles;

  /// {@macro fm.layerHitNotifier.usage}
  final LayerHitNotifier<R>? hitNotifier;

  /// {@macro fm.layerHitTestStrategy.usage}
  final LayerHitTestStrategy hitTestStrategy;

  /// Create a new [CircleLayer] as a child for [FlutterMap]
  const CircleLayer({
    super.key,
    required this.circles,
    this.hitNotifier,
    this.hitTestStrategy = LayerHitTestStrategy.allElements,
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
          hitTestStrategy: hitTestStrategy,
        ),
        size: camera.size,
        isComplex: true,
      ),
    );
  }
}

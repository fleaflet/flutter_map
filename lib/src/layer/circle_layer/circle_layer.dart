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

  /// {@macro fm.lhn.layerHitNotifier.usage}
  final LayerHitNotifier<R>? hitNotifier;

  /// Whether to use a single meters to pixels conversion ratio for all circles
  /// with [CircleMarker.useRadiusInMeter] enabled
  ///
  /// > [!IMPORTANT]
  /// > This reduces the accuracy of the radius of circles. Depending on the
  /// > location of the circles, this may or may not be significant.
  ///
  /// Where all circles within this layer are geographically (particularly
  /// latitudinally) close, the difference in the ratio between pixels and
  /// meters between circles is likely to be small. Calculating this
  /// conversion ratio is expensive, and is usually done for every circle to
  /// ensure accuracy, as the ratio depends on the latitude. Setting this `true`
  /// means the ratio is calculated based off the first circle only, then reused
  /// for all other circles within this layer.
  ///
  /// This should not be used where circles are geographically spread out - it
  /// is best suited, for example, for circles located within a single city.
  ///
  /// Defaults to `false`.
  final bool optimizeRadiusInMeters;

  /// Create a new [CircleLayer] as a child for [FlutterMap]
  const CircleLayer({
    super.key,
    required this.circles,
    this.hitNotifier,
    this.optimizeRadiusInMeters = false,
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
          optimizeRadiusInMeters: optimizeRadiusInMeters,
        ),
        size: camera.size,
        isComplex: true,
      ),
    );
  }
}

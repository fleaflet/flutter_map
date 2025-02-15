import 'package:flutter/painting.dart';
import 'package:flutter_map/src/layer/shared/feature_layer/interactivity/internal_hit_detectable.dart';
import 'package:meta/meta.dart';

@internal
@immutable
abstract base class ProjectedHittableElement<R extends Object>
    with HitDetectableElement<R> {
  const ProjectedHittableElement({required this.points});

  /// Projected coordinates of the element
  ///
  /// Some elements may have more than one set of projected points. However,
  /// these [points] are used to determine whether the element is visible in
  /// a world when hit testing.
  final List<Offset> points;
}

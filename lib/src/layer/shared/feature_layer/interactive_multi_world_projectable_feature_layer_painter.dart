import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/layer/shared/feature_layer/interactivity/internal_hit_detectable.dart';
import 'package:flutter_map/src/layer/shared/feature_layer/interactivity/projected_hittable_element.dart';
import 'package:flutter_map/src/layer/shared/feature_layer/utils.dart';
import 'package:flutter_map/src/misc/offsets.dart';
import 'package:meta/meta.dart';

/// Mixes [HitDetectablePainter] & [FeatureLayerUtils] into a [CustomPainter] to
/// provide a base framework for hit testing elements in a feature layer across
/// multiple worlds where the elements are projectable
/// ([ProjectedHittableElement])
@internal
abstract base class InteractiveMultiWorldProjectableFeatureLayerPainter<
        R extends Object, E extends ProjectedHittableElement<R>>
    extends CustomPainter with HitDetectablePainter<R, E>, FeatureLayerUtils {
  @override
  final MapCamera camera;

  @override
  final LayerHitNotifier<R>? hitNotifier;

  /// Inheritable constructor which sets up the map camera and hit notifier
  InteractiveMultiWorldProjectableFeatureLayerPainter({
    required this.camera,
    required this.hitNotifier,
  });

  /// Invoked on each element in every visible world by [elementHitTest]
  ///
  /// [coords] have been pre-[shift]ed for each world. [getOffsetsXY] may be
  /// used with the original element and the [shift] to project and shift more
  /// coordinates if necessary.
  ///
  /// See documentation on [elementHitTest] for good practises and more
  /// information.
  ///
  /// Should return whether the element has been hit.
  bool elementHitTestInWorld(
    E element, {
    required List<Offset> coords,
    required Offset offset,
    required double shift,
  });

  // TODO: Introduce bbox culling to skip testing coords in easy cases. Note
  // that this needs to support map rotation, multi-worlds, and `minimumHitbox`
  // for polylines.
  @override
  bool elementHitTest(
    E element, {
    required Offset offset,
  }) =>
      workAcrossWorlds(
        (shift) {
          final projectedCoords = getOffsetsXY(
            camera: camera,
            origin: origin,
            points: element.points,
            shift: shift,
          );

          if (!areOffsetsVisible(projectedCoords)) {
            return WorldWorkControl.invisible;
          }

          return elementHitTestInWorld(
            element,
            coords: projectedCoords,
            offset: offset,
            shift: shift,
          )
              ? WorldWorkControl.hit
              : WorldWorkControl.visible;
        },
      );
}

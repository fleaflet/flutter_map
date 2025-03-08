import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/layer/shared/feature_layer_utils.dart';
import 'package:latlong2/latlong.dart';
import 'package:meta/meta.dart';

@internal
mixin HitDetectableElement<R extends Object> {
  /// Value to notify layer's `hitNotifier` with (such as
  /// [PolygonLayer.hitNotifier])
  ///
  /// Elements without a defined [hitValue] are still hit tested, but are not
  /// notified about.
  ///
  /// When a [hitValue] is defined on a layer, that layer will always capture a
  /// hit, and the value will always appear in the list of hits in
  /// [LayerHitResult.hitValues] (if a notifier is defined).
  ///
  /// The object should have a valid & useful equality, as it may be used
  /// by FM internals.
  R? get hitValue;
}

@internal
mixin HitDetectablePainter<R extends Object, E extends HitDetectableElement<R>>
    on CustomPainter {
  abstract final MapCamera camera;
  abstract final LayerHitNotifier<R>? hitNotifier;
  abstract final LayerHitTestStrategy hitTestStrategy;

  /// Elements that should be possibly be hit tested by [elementHitTest]
  /// ([hitTest])
  ///
  /// See [elementHitTest] for more information.
  List<E> get elements;

  /// Method invoked by [hitTest] for every element (each of [elements] in
  /// reverse order) that requires testing
  ///
  /// Not all elements will require testing. For example, testing is skipped if
  /// a hit has already been found on another element, and the
  /// [HitDetectableElement.hitValue] is `null` on this element.
  ///
  /// [Offset] and [coordinate]
  /// ([MapCamera.screenOffsetToLatLng]) are provided for simplicity.
  ///
  /// Avoid performing calculations that are not dependent on [element]. Instead,
  /// override [hitTest], store the necessary calculation results in
  /// (`late` non-`null`able) members, and call `super.hitTest(position)` at the
  /// end. To calculate the camera origin in this way, instead mix in and use
  /// [FeatureLayerUtils.origin].
  ///
  /// Should return whether an element has been hit.
  bool elementHitTest(
    E element, {
    required Offset point,
    required LatLng coordinate,
  });

  final _hits = <R>[]; // Avoids repetitive memory reallocation

  @override
  @mustCallSuper
  bool? hitTest(Offset position) {
    final coordinate = camera.screenOffsetToLatLng(position);
    bool? hitResult;

    _hits.clear();

    for (int i = elements.length - 1; i >= 0; i--) {
      final element = elements[i];

      // If we're not going to change anything even if we hit, don't bother
      // testing for a hit
      late final addsToHitsList = element.hitValue != null;
      late final setsHitResult =
          hitTestStrategy == LayerHitTestStrategy.allElements &&
              hitResult != true;
      late final unsetsHitResult =
          hitTestStrategy == LayerHitTestStrategy.inverted && hitResult == null;

      if ((addsToHitsList || setsHitResult || unsetsHitResult) &&
          elementHitTest(element, point: position, coordinate: coordinate)) {
        if (element.hitValue != null) {
          _hits.add(element.hitValue!);
          hitResult = true;
          continue;
        }
        if (hitTestStrategy == LayerHitTestStrategy.allElements) {
          hitResult = true;
        }
        if (hitTestStrategy == LayerHitTestStrategy.inverted) {
          hitResult ??= false;
        }
      }
    }

    if (hitResult ?? false) {
      hitNotifier?.value = LayerHitResult(
        hitValues: _hits,
        coordinate: coordinate,
        point: position,
      );
      return true;
    }

    hitNotifier?.value = null;
    return hitTestStrategy == LayerHitTestStrategy.inverted &&
        hitResult == null;
  }
}

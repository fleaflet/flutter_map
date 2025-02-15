import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/layer/shared/feature_layer/utils.dart';
import 'package:meta/meta.dart';

@internal
mixin HitDetectableElement<R extends Object> {
  /// Value to notify layer's `hitNotifier` with (such as
  /// [PolygonLayer.hitNotifier])
  ///
  /// Elements without a defined [hitValue] are still hit tested, but are not
  /// notified about.
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

  /// Elements that should be possibly be hit tested by [elementHitTest]
  /// ([hitTest])
  ///
  /// See [elementHitTest] for more information.
  Iterable<E> get elements;

  /// Method invoked by [hitTest] for every element (each of [elements] in
  /// reverse order) that requires testing
  ///
  /// Not all elements will require testing. For example, testing is skipped if
  /// a hit has already been found on another element, and the
  /// [HitDetectableElement.hitValue] is `null` on this element.
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
    required Offset offset,
  });

  final _hits = <R>[]; // Avoids repetitive memory reallocation

  @override
  @mustCallSuper
  bool? hitTest(Offset position) {
    _hits.clear();
    bool hasHit = false;

    final coordinate = camera.screenOffsetToLatLng(position);

    for (int i = elements.length - 1; i >= 0; i--) {
      final element = elements.elementAt(i);
      if (hasHit && element.hitValue == null) continue;
      if (elementHitTest(element, offset: position)) {
        if (element.hitValue != null) _hits.add(element.hitValue!);
        hasHit = true;
      }
    }

    if (!hasHit) {
      hitNotifier?.value = null;
      return false;
    }

    hitNotifier?.value = LayerHitResult(
      hitValues: _hits,
      coordinate: coordinate,
      point: position,
    );
    return true;
  }
}

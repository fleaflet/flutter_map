import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:meta/meta.dart';

@internal
mixin HitDetectableElement<R extends Object> {
  /// {@template fm.hde.hitValue}
  /// Value to notify layer's `hitNotifier` with (such as
  /// [PolygonLayer.hitNotifier])
  ///
  /// Elements without a defined [hitValue] are still hit tested, but are not
  /// notified about.
  ///
  /// The object should have a valid & useful equality, as it may be used
  /// by FM internals.
  /// {@endtemplate}
  R? get hitValue;
}

@internal
abstract base class HitDetectablePainter<R extends Object,
    E extends HitDetectableElement<R>> extends CustomPainter {
  HitDetectablePainter({required this.camera, required this.hitNotifier});

  final MapCamera camera;
  final LayerHitNotifier<R>? hitNotifier;

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
  /// [point] ([OffsetToPointExtension.toPoint]) and [coordinate]
  /// ([MapCamera.pointToLatLng]) are provided for simplicity.
  ///
  /// Avoid performing calculations that are not dependent on [element]. Instead,
  /// override [hitTest], store the necessary calculation results in
  /// (`late` non-`null`able) members, and call `super.hitTest(position)` at the
  /// end. To calculate the camera origin in this way, instead mix in
  /// [HitTestRequiresCameraOrigin], which makes the origin available through
  /// the `hitTestCameraOrigin` member.
  ///
  /// Should return whether an element has been hit.
  bool elementHitTest(
    E element, {
    required Point<double> point,
    required LatLng coordinate,
  });

  final _hits = <R>[]; // Avoids repetitive memory reallocation

  @override
  @mustCallSuper
  bool? hitTest(Offset position) {
    _hits.clear();
    bool hasHit = false;

    final point = position.toPoint();
    final coordinate = camera.pointToLatLng(point);

    for (int i = elements.length - 1; i >= 0; i--) {
      final element = elements.elementAt(i);
      if (hasHit && element.hitValue == null) continue;
      if (elementHitTest(element, point: point, coordinate: coordinate)) {
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
      point: point,
    );
    return true;
  }
}

@internal
base mixin HitTestRequiresCameraOrigin<R extends Object,
    E extends HitDetectableElement<R>> on HitDetectablePainter<R, E> {
  /// Calculated [MapCamera] origin, using the following formula:
  ///
  /// ```dart
  /// camera.project(camera.center).toOffset() - camera.size.toOffset() / 2
  /// ```
  ///
  /// Only initialised after [hitTest] is invoked. Recalculated every time
  /// [hitTest] is invoked.
  late Offset hitTestCameraOrigin;

  @override
  bool? hitTest(Offset position) {
    hitTestCameraOrigin =
        camera.project(camera.center).toOffset() - camera.size.toOffset() / 2;
    return super.hitTest(position);
  }
}

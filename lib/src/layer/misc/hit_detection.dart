import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:latlong2/latlong.dart';
import 'package:meta/meta.dart';

/// Result emmitted by hit notifiers (see [LayerHitNotifier]) when a hit is
/// detected on a feature within the respective layer
///
/// Not emitted if the hit was not over a feature.
@immutable
class LayerHitResult<R extends Object> {
  /// `hitValue`s from all features hit (which have `hitValue`s defined)
  ///
  /// If a feature is hit but has no `hitValue` defined, it will not be included.
  /// May be empty.
  ///
  /// Ordered by their corresponding feature, first-to-last, visually
  /// top-to-bottom.
  final List<R> hitValues;

  /// Geographical coordinates of the detected hit
  ///
  /// Note that this may not lie on a feature.
  ///
  /// See [point] for the screen point which was hit.
  final LatLng coordinate;

  /// Screen point of the detected hit
  ///
  /// See [coordinate] for the geographical coordinate which was hit.
  final Point<double> point;

  /// Construct a new [LayerHitResult] by providing the values.
  @internal
  const LayerHitResult({
    required this.hitValues,
    required this.coordinate,
    required this.point,
  });
}

/// A [ValueNotifier] that notifies:
///
///  * a [LayerHitResult] when a hit is detected on a feature in a layer
///  * `null` when a hit is detected on the layer but not on a feature
typedef LayerHitNotifier<R extends Object> = ValueNotifier<LayerHitResult<R>?>;

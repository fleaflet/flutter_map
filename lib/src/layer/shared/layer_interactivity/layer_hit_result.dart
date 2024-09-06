import 'dart:math';

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:meta/meta.dart';

/// Result emitted by hit notifiers (see [LayerHitNotifier]) when a hit is
/// detected on an element (such as a [Polyline]) within the respective layer
///
/// Not emitted if the hit was not over an element.
@immutable
class LayerHitResult<R extends Object> {
  /// `hitValue`s from all elements hit (which have `hitValue`s defined)
  ///
  /// If an element is hit but has no `hitValue` defined, it will not be
  /// included. May be empty.
  ///
  /// Ordered by their corresponding element, first-to-last, visually
  /// top-to-bottom.
  final List<R> hitValues;

  /// Geographical coordinates of the detected hit
  ///
  /// Note that this may not lie on an element.
  ///
  /// See [point] for the screen point which was hit.
  final LatLng coordinate;

  /// Screen point of the detected hit
  ///
  /// See [coordinate] for the geographical coordinate which was hit.
  final Point<double> point;

  /// Construct a new [LayerHitResult]
  @internal
  const LayerHitResult({
    required this.hitValues,
    required this.coordinate,
    required this.point,
  });
}

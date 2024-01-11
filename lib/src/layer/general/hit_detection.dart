import 'package:flutter/widgets.dart';
import 'package:latlong2/latlong.dart';
import 'package:meta/meta.dart';

/// Result emmitted by hit notifiers (see [LayerHitNotifier]) when a hit is
/// detected on a feature within the respective layer
///
/// Not emitted if the hit was not over a feature.
@immutable
class LayerHit<R extends Object> {
  /// `hitValues` from all features hit
  ///
  /// Ordered in order of the features first-to-last, visually top-to-bottom.
  final List<R> hitValues;

  /// Coordinates of the detected hit
  ///
  /// Note that this may not lie on a feature.
  final LatLng point;

  @internal
  const LayerHit({required this.hitValues, required this.point});
}

/// A [ValueNotifier] that notifies:
///
///  * a [LayerHit] when a hit is detected on a feature in a layer
///  * `null` when a hit is detected on the layer but not on a feature
typedef LayerHitNotifier<R extends Object> = ValueNotifier<LayerHit<R>?>;

part of 'polyline_layer.dart';

/// Result from polyline hit detection
///
/// Emmitted by [PolylineLayer.hitNotifier]'s [ValueNotifier]
/// ([PolylineHitNotifier]).
class PolylineHit<R extends Object> {
  /// All hit [Polyline.hitValue]s within the corresponding layer
  ///
  /// Ordered from first-last, visually top-bottom.
  final List<R> hitValues;

  /// Coordinates of the detected hit
  ///
  /// Note that this may not lie on a [Polyline].
  final LatLng point;

  const PolylineHit._({required this.hitValues, required this.point});
}

/// Typedef used on [PolylineLayer.hitNotifier]
typedef PolylineHitNotifier<R extends Object> = ValueNotifier<PolylineHit<R>?>;

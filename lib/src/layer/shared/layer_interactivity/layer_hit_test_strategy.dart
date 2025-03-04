import 'package:flutter_map/flutter_map.dart';

/// Controls the results of hit tests performed on hittable layers
///
/// Elements within hittable layers are always (at least for the purpose of
/// external API usage) hit tested when the layers are hit tested. This controls
/// how the results of each element's hit test affects the layer's hit test
/// result (potentially depending on whether elements have non-null
/// `hitValue`s).
///
/// A layer's hit test result is independent of the [LayerHitResult]s emitted by
/// any [LayerHitNotifier] attached to the layer. The layer's hit test result
/// can only be a boolean flag, whereas the notifier allows more detail to be
/// emitted.
enum LayerHitTestStrategy {
  /// Positive if any element has been hit
  ///
  /// The default behaviour.
  allElements,

  /// Positive if any element with a non-null `hitValue` has been hit
  onlyInteractiveElements,

  /// Positive if no elements have been hit, or any element with a non-null
  /// `hitValue` has been hit
  inverted,
}

/// {@template fm.layerHitTestStrategy.usage}
/// The strategy to use to determine the result of a hit test performed on this
/// layer
///
/// Defaults to [LayerHitTestStrategy.allElements].
///
/// See online documentation for more detailed usage instructions. See the
/// example project for an example implementation.
/// {@endtemplate}
// ignore: unused_element, constant_identifier_names
const _doc_fmLayerHitTestStrategyUsage = null;

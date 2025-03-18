import 'package:flutter/foundation.dart';

import 'package:flutter_map/flutter_map.dart';

/// A [ValueNotifier] that emits:
///
///  * a [LayerHitResult] when a hit is detected on an element in a layer
///  * `null` when a hit is detected on the layer but not on an element
///
/// Should be initialised using the following pattern:
/// ```dart
/// final LayerHitNotifier<Object> hitNotifier = ValueNotifier(null);
/// ```
///
/// Note that whether or not this is defined on a layer does not affect whether
/// the layer conducts hit testing.
///
/// A layer's hit test result, the behaviour of which is determined by
/// [LayerHitTestStrategy], is independent of the values emitted by any notifier
/// attached to the layer. The layer's hit test result can only be a boolean
/// flag, whereas the notifier allows more detail to be emitted.
typedef LayerHitNotifier<R extends Object> = ValueNotifier<LayerHitResult<R>?>;

/// {@template fm.layerHitNotifier.usage}
/// A notifier to be notified when a hit test occurs on the layer
///
/// Notified with a [LayerHitResult] if any elements are hit, otherwise
/// notified with `null`.
///
/// Hit testing still occurs even if this is `null`.
///
/// See the online documentation for more detailed usage instructions. See the
/// example project for an example implementation.
/// {@endtemplate}
// ignore: unused_element, constant_identifier_names
const _doc_fmLayerHitNotifierUsage = null;

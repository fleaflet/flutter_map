import 'package:flutter/foundation.dart';

import 'package:flutter_map/src/layer/shared/layer_interactivity/layer_hit_result.dart';

/// A [ValueNotifier] that notifies:
///
///  * a [LayerHitResult] when a hit is detected on an element in a layer
///  * `null` when a hit is detected on the layer but not on an element
///
/// Should be initialised using the following pattern:
/// ```dart
/// final LayerHitNotifier<Object> hitNotifier = ValueNotifier(null);
/// ```
typedef LayerHitNotifier<R extends Object> = ValueNotifier<LayerHitResult<R>?>;

/// {@template fm.lhn.layerHitNotifier.usage}
/// A notifier to be notified when a hit test occurs on the layer
///
/// Notified with a [LayerHitResult] if any elements are hit, otherwise
/// notified with `null`.
///
/// Hit testing still occurs even if this is `null`.
///
/// See online documentation for more detailed usage instructions. See the
/// example project for an example implementation.
/// {@endtemplate}
// ignore: unused_element, constant_identifier_names
const _doc_fmLHNLayerHitNotiferUsage = null;

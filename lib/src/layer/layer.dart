import 'package:flutter/foundation.dart';

/// Common type between all LayerOptions.
///
/// All LayerOptions have access to a stream that notifies when the map needs
/// rebuilding.
class LayerOptions {
  final Key? key;
  final Stream<void>? rebuild;

  /// Indicates whether pitch should be applied to this layer. When true, the
  /// layer is rendered with pitch applied to create perspective when the
  /// map has non-zero pitch.
  ///
  /// Layers that render flat to the viewport (without perspective) should pass
  /// false. Layers that render flat to the viewport must account for pitch and
  /// rotation when computing positioning.
  final bool applyPitch;

  LayerOptions({this.key, this.rebuild, this.applyPitch = true});
}

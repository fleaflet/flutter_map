import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';

/// A soft halo painted only outside a feature's outline
///
/// Supported by `Polyline`s and `CircleMarker`s. The outline includes any
/// border.
@immutable
class ShapeGlow {
  /// Color of the halo, including its opacity
  final Color color;

  /// Standard deviation of the Gaussian blur, in logical pixels
  ///
  /// Defaults to 6.
  final double blurSigma;

  /// Create a new [ShapeGlow]
  const ShapeGlow({required this.color, this.blurSigma = 6})
      : assert(blurSigma >= 0, 'blurSigma cannot be negative');

  /// How far the halo reaches past the outline, in logical pixels
  double get extent => blurSigma * 3;

  /// The paint used to draw this effect
  Paint toPaint() => Paint()
    ..color = color
    ..maskFilter =
        blurSigma > 0 ? MaskFilter.blur(BlurStyle.outer, blurSigma) : null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ShapeGlow &&
          color == other.color &&
          blurSigma == other.blurSigma);

  @override
  int get hashCode => Object.hash(color, blurSigma);
}

/// A blurred, offset copy of a feature's outline painted underneath it
///
/// Supported by `Polyline`s and `CircleMarker`s. The outline includes any
/// border.
@immutable
class ShapeShadow {
  /// Color of the shadow, including its opacity
  final Color color;

  /// Standard deviation of the Gaussian blur, in logical pixels
  ///
  /// Defaults to 4.
  final double blurSigma;

  /// Screen space offset of the shadow, in logical pixels
  ///
  /// Defaults to 2 pixels downwards.
  final Offset offset;

  /// Create a new [ShapeShadow]
  const ShapeShadow({
    required this.color,
    this.blurSigma = 4,
    this.offset = const Offset(0, 2),
  }) : assert(blurSigma >= 0, 'blurSigma cannot be negative');

  /// How far the shadow reaches past the outline, in logical pixels
  double get extent =>
      blurSigma * 3 + math.max(offset.dx.abs(), offset.dy.abs());

  /// The paint used to draw this effect
  Paint toPaint() => Paint()
    ..color = color
    ..maskFilter =
        blurSigma > 0 ? MaskFilter.blur(BlurStyle.normal, blurSigma) : null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ShapeShadow &&
          color == other.color &&
          blurSigma == other.blurSigma &&
          offset == other.offset);

  @override
  int get hashCode => Object.hash(color, blurSigma, offset);
}

/// Largest distance any of the effects reach past a feature's outline
@internal
double shapeEffectsExtent(ShapeGlow? glow, ShapeShadow? shadow) =>
    math.max(glow?.extent ?? 0, shadow?.extent ?? 0);

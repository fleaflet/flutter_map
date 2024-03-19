part of 'polyline_layer.dart';

/// Determines whether a [Polyline] should be solid, dotted, or dashed, and
/// the exact characteristics of each
@immutable
class PolylinePattern {
  /// Solid/unbroken
  const PolylinePattern.solid()
      : spacingFactor = null,
        segments = null;

  /// Circular dots, spaced with [spacingFactor]
  ///
  /// [spacingFactor] is
  /// {@macro fm.polylinePattern.spacingFactor}
  const PolylinePattern.dotted({double this.spacingFactor = 1.5})
      : segments = null;

  /// Elongated dashes, with length and spacing set by [segments]
  ///
  /// Dashes may not be linear: they may pass through different [Polyline.points]
  /// without regard to their relative bearing/direction.
  ///
  /// ---
  ///
  /// [segments] is
  /// {@macro fm.polylinePattern.segments}
  const PolylinePattern.dashed({required List<double> this.segments})
      : assert(
          segments.length >= 2,
          '`segments` must contain at least two items',
        ),
        assert(
          // ignore: use_is_even_rather_than_modulo
          segments.length % 2 == 0,
          '`segments` must have an even length',
        ),
        spacingFactor = null;

  /// {@template fm.polylinePattern.spacingFactor}
  /// The multiplier used to calculate the spacing between segments in a
  /// dotted/dashed polyline, with respect to [Polyline.strokeWidth]. A value of
  /// 1.0 will result in spacing equal to the `strokeWidth`. Increasing the value
  /// increases the spacing with the same scaling. It defaults to 1.5.
  /// {@endtemplate}
  final double? spacingFactor;

  /// {@template fm.polylinePattern.segments}
  /// A list of even length with a minimum of 2, in the form of
  /// `[a₁, b₁, (a₂, b₂, ...)]`, where `a` should be the length of segments in
  /// pixels, and `b` the length of the space after each segment in pixels. Both
  /// values must be strictly positive.
  ///
  /// If more than two items are specified, then each segments will
  /// alternate/iterate through the values.
  ///
  /// For example, `[50, 10]` will cause:
  ///  * a segment of length 50px
  ///  * followed by a space of 10px
  ///  * followed by a segment of length 50px
  ///  * followed by a space of 10px
  ///  * etc...
  ///
  /// For example, `[50, 10, 10, 10]` will cause:
  ///  * a segment of length 50px
  ///  * followed by a space of 10px
  ///  * followed by a segment of length 10px
  ///  * followed by a space of 10px
  ///  * followed by a segment of length of 50px
  ///  * followed by a space of 10px
  ///  * etc...
  /// {@endtemplate}
  final List<double>? segments;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PolylinePattern &&
          spacingFactor == other.spacingFactor &&
          listEquals(segments, other.segments));

  @override
  int get hashCode => Object.hash(spacingFactor, segments);
}

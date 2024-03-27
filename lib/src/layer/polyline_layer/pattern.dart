part of 'polyline_layer.dart';

/// Determines whether a [Polyline] should be solid, dotted, or dashed, and the
/// exact characteristics of each
@immutable
class PolylinePattern {
  /// Solid/unbroken
  const PolylinePattern.solid()
      : spacingFactor = null,
        segments = null,
        patternFit = null;

  /// Circular dots, spaced with [spacingFactor]
  ///
  /// See [spacingFactor] and [PatternFit] for more information about parameters.
  /// [spacingFactor] defaults to 1.5, and [patternFit] defaults to
  /// [PatternFit.scaleUp].
  const PolylinePattern.dotted({
    double this.spacingFactor = 1.5,
    PatternFit this.patternFit = PatternFit.scaleUp,
  }) : segments = null;

  /// Elongated dashes, with length and spacing set by [segments]
  ///
  /// Dashes may not be linear: they may pass through different [Polyline.points]
  /// without regard to their relative bearing/direction.
  ///
  /// See [segments] and [PatternFit] for more information about parameters.
  /// [patternFit] defaults to [PatternFit.scaleUp].
  const PolylinePattern.dashed({
    required List<double> this.segments,
    PatternFit this.patternFit = PatternFit.scaleUp,
  })  : assert(
          segments.length >= 2,
          '`segments` must contain at least two items',
        ),
        assert(
          // ignore: use_is_even_rather_than_modulo
          segments.length % 2 == 0,
          '`segments` must have an even length',
        ),
        spacingFactor = null;

  /// The multiplier used to calculate the spacing between dots in a dotted
  /// polyline, with respect to [Polyline.strokeWidth]
  ///
  /// A value of 1.0 will result in spacing equal to the `strokeWidth`.
  /// Increasing the value increases the spacing with the same scaling.
  ///
  /// May also be scaled by the use of [PatternFit.scaleUp].
  ///
  /// Defaults to 1.5.
  final double? spacingFactor;

  /// A list of even length with a minimum of 2, in the form of
  /// `[a₁, b₁, (a₂, b₂, ...)]`, where `a` should be the length of segments in
  /// 'units', and `b` the length of the space after each segment in units. Both
  /// values must be strictly positive.
  ///
  /// 'Units' refers to pixels, unless the pattern has been scaled due to the
  /// use of [PatternFit.scaleUp].
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
  final List<double>? segments;

  /// Determines how a non-solid [PolylinePattern] should be fit to a [Polyline]
  /// when their lengths are not equal or multiples
  ///
  /// Defaults to [PatternFit.scaleUp].
  final PatternFit? patternFit;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PolylinePattern &&
          spacingFactor == other.spacingFactor &&
          patternFit == other.patternFit &&
          ((segments == null && other.segments == null) ||
              listEquals(segments, other.segments)));

  @override
  int get hashCode => Object.hash(spacingFactor, segments, patternFit);
}

/// Determines how a non-solid [PolylinePattern] should be fit to a [Polyline]
/// when their lengths are not equal or multiples
///
/// [PolylinePattern.solid]s do not require fitting.
enum PatternFit {
  /// Don't apply any specific fit to the pattern - repeat exactly as specified,
  /// and stop when the last point is reached
  ///
  /// Not recommended. May leave a gap between the final segment and the last
  /// point, making it unclear where the line ends.
  none,

  /// Scale the pattern to ensure it fits an integer number of times into the
  /// polyline (smaller version regarding rounding, cf. [scaleUp])
  scaleDown,

  /// Scale the pattern to ensure it fits an integer number of times into the
  /// polyline (bigger version regarding rounding, cf. [scaleDown])
  scaleUp,

  /// Uses the pattern exactly, truncating the final dash if it does not fit, or
  /// adding a single dot at the last point if the final dash does not reach the
  /// last point (there is a gap at that location)
  appendDot,

  /// (Only valid for [PolylinePattern.dashed], equal to [appendDot] for
  /// [PolylinePattern.dotted])
  ///
  /// Uses the pattern exactly, truncating the final dash if it does not fit, or
  /// extending the final dash to the last point if it would not normally reach
  /// that point (there is a gap at that location).
  extendFinalDash;
}

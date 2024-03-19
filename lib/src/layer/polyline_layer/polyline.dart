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

/// [Polyline] (aka. LineString) class, to be used for the [PolylineLayer].
class Polyline<R extends Object> {
  /// The list of coordinates for the [Polyline].
  final List<LatLng> points;

  /// The width of the stroke
  final double strokeWidth;

  /// Determines whether this should be solid, dotted, or dashed, and the exact
  /// characteristics of each
  ///
  /// Defaults to being a solid/unbroken line ([PolylinePattern.solid]).
  final PolylinePattern pattern;

  /// The color of the line stroke.
  final Color color;

  /// The width of the stroke with of the line border.
  /// Defaults to 0.0 (disabled).
  final double borderStrokeWidth;

  /// The [Color] of the [Polyline] border.
  final Color borderColor;

  /// The List of colors in case a gradient should get used.
  final List<Color>? gradientColors;

  /// The stops for the gradient colors.
  final List<double>? colorsStop;

  /// Deprecated: use [Polyline.pattern], which also supports dashed lines
  ///
  /// See deprecation message for more info.
  @Deprecated(
    'Prefer setting `pattern` to toggle dotting. '
    'This parameter will be replaced by `pattern`, which supports further '
    'customization & dashed lines through a single, less complex, external API. '
    'This feature was deprecated after v7.',
  )
  final bool isDotted;

  /// Styles to use for line endings.
  final StrokeCap strokeCap;

  /// Styles to use for line segment joins.
  final StrokeJoin strokeJoin;

  /// Set to true if the width of the stroke should have meters as unit.
  final bool useStrokeWidthInMeter;

  /// Value notified in [PolylineLayer.hitNotifier]
  ///
  /// Polylines without a defined [hitValue] are still hit tested, but are not
  /// notified about.
  ///
  /// Should implement an equality operator to avoid breaking [Polyline.==].
  final R? hitValue;

  /// Create a new [Polyline] used for the [PolylineLayer].
  Polyline({
    required this.points,
    this.strokeWidth = 1.0,
    this.pattern = const PolylinePattern.solid(),
    this.color = const Color(0xFF00FF00),
    this.borderStrokeWidth = 0.0,
    this.borderColor = const Color(0xFFFFFF00),
    this.gradientColors,
    this.colorsStop,
    this.strokeCap = StrokeCap.round,
    this.strokeJoin = StrokeJoin.round,
    this.useStrokeWidthInMeter = false,
    this.hitValue,
    @Deprecated(
      'Prefer setting `pattern` to toggle dotting. '
      'This parameter will be replaced by `pattern`, which supports further '
      'customization & dashed lines through a single, less complex, external API. '
      'This feature was deprecated after v7.',
    )
    this.isDotted = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Polyline &&
          strokeWidth == other.strokeWidth &&
          color == other.color &&
          borderStrokeWidth == other.borderStrokeWidth &&
          borderColor == other.borderColor &&
          pattern == other.pattern &&
          strokeCap == other.strokeCap &&
          strokeJoin == other.strokeJoin &&
          useStrokeWidthInMeter == other.useStrokeWidthInMeter &&
          hitValue == other.hitValue &&
          // Expensive computations last to take advantage of lazy logic gates
          listEquals(colorsStop, other.colorsStop) &&
          listEquals(gradientColors, other.gradientColors) &&
          listEquals(points, other.points));

  // Used to batch draw calls to the canvas
  int? _renderHashCode;

  /// A for rendering purposes optimized hashCode function.
  int get renderHashCode => _renderHashCode ??= Object.hash(
        strokeWidth,
        color,
        borderStrokeWidth,
        borderColor,
        gradientColors,
        colorsStop,
        pattern,
        strokeCap,
        strokeJoin,
        useStrokeWidthInMeter,
        hitValue,
      );

  int? _hashCode;

  @override
  int get hashCode => _hashCode ??= Object.hashAll([...points, renderHashCode]);
}

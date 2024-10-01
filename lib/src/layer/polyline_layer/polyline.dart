part of 'polyline_layer.dart';

/// [Polyline] (aka. LineString) class, to be used for the [PolylineLayer].
class Polyline<R extends Object> {
  /// The list of coordinates for the [Polyline].
  final List<LatLng> points;

  /// The width of the stroke
  final double strokeWidth;

  /// Determines whether the line should be solid, dotted, or dashed, and the
  /// exact characteristics of each
  ///
  /// Defaults to being a solid/unbroken line ([StrokePattern.solid]).
  final StrokePattern pattern;

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

  /// Styles to use for line endings.
  final StrokeCap strokeCap;

  /// Styles to use for line segment joins.
  final StrokeJoin strokeJoin;

  /// Set to true if the width of the stroke should have meters as unit.
  final bool useStrokeWidthInMeter;

  /// {@macro fm.hde.hitValue}
  final R? hitValue;

  /// Create a new [Polyline] used for the [PolylineLayer].
  Polyline({
    required this.points,
    this.strokeWidth = 1.0,
    this.pattern = const StrokePattern.solid(),
    this.color = const Color(0xFF00FF00),
    this.borderStrokeWidth = 0.0,
    this.borderColor = const Color(0xFFFFFF00),
    this.gradientColors,
    this.colorsStop,
    this.strokeCap = StrokeCap.round,
    this.strokeJoin = StrokeJoin.round,
    this.useStrokeWidthInMeter = false,
    this.hitValue,
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
      );

  int? _hashCode;

  @override
  int get hashCode => _hashCode ??= Object.hashAll([...points, renderHashCode]);
}

part of 'polyline_layer.dart';

/// [Polyline] (aka. LineString) class, to be used for the [PolylineLayer].
class Polyline<R extends Object> {
  /// The list of coordinates for the [Polyline].
  final List<LatLng> points;

  /// The width of the stroke
  final double strokeWidth;

  /// The color of the line stroke.
  final Color color;

  /// The width of the stroke with of the line border.
  /// Defaults to 0.0 (disabled).
  final double borderStrokeWidth;

  /// The [Color] of the [Polyline] border.
  final Color borderColor;
  final List<Color>? gradientColors;
  final List<double>? colorsStop;

  /// Set to true if the line stroke should be rendered as a dotted line.
  final bool isDotted;
  final StrokeCap strokeCap;
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
    this.color = const Color(0xFF00FF00),
    this.borderStrokeWidth = 0.0,
    this.borderColor = const Color(0xFFFFFF00),
    this.gradientColors,
    this.colorsStop,
    this.isDotted = false,
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
          isDotted == other.isDotted &&
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

  int get renderHashCode => _renderHashCode ??= Object.hash(
        strokeWidth,
        color,
        borderStrokeWidth,
        borderColor,
        gradientColors,
        colorsStop,
        isDotted,
        strokeCap,
        strokeJoin,
        useStrokeWidthInMeter,
        hitValue,
      );

  int? _hashCode;

  @override
  int get hashCode => _hashCode ??= Object.hashAll([...points, renderHashCode]);
}

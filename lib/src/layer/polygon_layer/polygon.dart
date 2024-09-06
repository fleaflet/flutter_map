part of 'polygon_layer.dart';

/// Defines the algorithm used to calculate the position of the [Polygon] label.
enum PolygonLabelPlacement {
  /// Use the centroid of the [Polygon] outline as position for the label.
  centroid,

  /// Use the Mapbox Polylabel algorithm as position for the label.
  polylabel,
}

/// [Polygon] class, to be used for the [PolygonLayer].
class Polygon<R extends Object> {
  /// The points for the outline of the [Polygon].
  final List<LatLng> points;

  /// The point lists that define holes in the [Polygon].
  final List<List<LatLng>>? holePointsList;

  /// The fill color of the [Polygon].
  ///
  /// Note that translucent (opacity is not 1 or 0) colors will reduce
  /// performance, as the internal canvas must be drawn to and 'saved' more
  /// frequently to ensure the colors of overlapping polygons are mixed
  /// correctly.
  final Color? color;

  /// The stroke width of the [Polygon] outline.
  final double borderStrokeWidth;

  /// The color of the [Polygon] outline.
  final Color borderColor;

  /// Whether holes should have borders
  ///
  /// Defaults to false (enabled).
  final bool disableHolesBorder;

  /// Determines whether the border (if visible) should be solid, dotted, or
  /// dashed, and the exact characteristics of each
  ///
  /// Defaults to being a solid/unbroken line ([StrokePattern.solid]).
  /// Note that there is no border by default: increase [borderStrokeWidth] to
  /// display it.
  final StrokePattern pattern;

  /// **DEPRECATED**
  ///
  /// Prefer setting `color` to null to disable filling, or a `Color` to enable
  /// filling of that color.
  ///
  /// This parameter will be removed to simplify the API, as this was a remnant of pre-null-safety.
  ///
  /// The default of this parameter is now `null` and will use the rules above -
  /// the option is retained so as not to break APIs.
  ///
  /// This feature was deprecated (and the default changed) after v7.
  ///
  /// ---
  ///
  /// Set to true if the [Polygon] should be filled with a color.
  @Deprecated(
    'Prefer setting `color` to null to disable filling, or a `Color` to enable filling of that color. '
    'This parameter will be removed to simplify the API, as this was a remnant of pre-null-safety. '
    'The default of this parameter is now `null` and will use the rules above - the option is retained so as not to break APIs. '
    'This feature was deprecated (and the default changed) after v7.',
  )
  final bool? isFilled;

  /// Styles to use for line endings.
  final StrokeCap strokeCap;

  /// Styles to use for line segment joins.
  final StrokeJoin strokeJoin;

  /// The optional label of the [Polygon].
  ///
  /// Note that specifying a label will reduce performance, as the internal
  /// canvas must be drawn to and 'saved' more frequently to ensure the proper
  /// stacking order is maintained. This can be avoided, potentially at the
  /// expense of appearance, by setting [PolygonLayer.drawLabelsLast].
  final String? label;

  /// The [TextStyle] of the [Polygon.label].
  final TextStyle labelStyle;

  /// The placement logic of the [Polygon.label]
  ///
  /// [PolygonLabelPlacement.polylabel] can be expensive for some polygons. If
  /// there is a large lag spike, try using [PolygonLabelPlacement.centroid].
  ///
  /// Labels will not be drawn if there is not enough space.
  final PolygonLabelPlacement labelPlacement;

  /// Whether to rotate the label counter to the camera's rotation, to ensure
  /// it remains upright
  final bool rotateLabel;

  /// {@macro fm.hde.hitValue}
  final R? hitValue;

  /// Designates whether the given polygon points follow a clock or
  /// anti-clockwise direction.
  /// This is respected during draw call batching for filled polygons.
  /// Otherwise, batched polygons of opposing clock-directions cut holes into
  /// each other leading to a leaky optimization.
  final bool _filledAndClockwise;

  /// Location where to place the label if `label` is set.
  LatLng? _labelPosition;

  /// Get the coordinates of the label position (cached).
  LatLng get labelPosition =>
      _labelPosition ??= _computeLabelPosition(labelPlacement, points);

  LatLngBounds? _boundingBox;

  /// Get the bounding box of the [Polygon.points] (cached).
  LatLngBounds get boundingBox =>
      _boundingBox ??= LatLngBounds.fromPoints(points);

  TextPainter? _textPainter;

  /// Get the [TextPainter] for the polygon label (cached).
  ///
  /// Returns null if [Polygon.label] is not set.
  TextPainter? get textPainter {
    if (label != null) {
      return _textPainter ??= TextPainter(
        text: TextSpan(text: label, style: labelStyle),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();
    }
    return null;
  }

  /// Create a new [Polygon] instance by setting it's parameters.
  Polygon({
    required this.points,
    this.holePointsList,
    this.color,
    this.borderStrokeWidth = 0,
    this.borderColor = const Color(0xFFFFFF00),
    this.disableHolesBorder = false,
    this.pattern = const StrokePattern.solid(),
    @Deprecated(
      'Prefer setting `color` to null to disable filling, or a `Color` to enable filling of that color. '
      'This parameter will be removed to simplify the API, as this was a remnant of pre-null-safety. '
      'The default of this parameter is now `null` and will use the rules above - the option is retained so as not to break APIs. '
      'This feature was deprecated (and the default changed) after v7.',
    )
    this.isFilled,
    this.strokeCap = StrokeCap.round,
    this.strokeJoin = StrokeJoin.round,
    this.label,
    this.labelStyle = const TextStyle(),
    this.labelPlacement = PolygonLabelPlacement.centroid,
    this.rotateLabel = false,
    this.hitValue,
  }) : _filledAndClockwise =
            (isFilled ?? (color != null)) && isClockwise(points);

  /// Checks if the [Polygon] points are ordered clockwise in the list.
  static bool isClockwise(List<LatLng> points) {
    double sum = 0;
    for (int i = 0; i < points.length; ++i) {
      final a = points[i];
      final b = points[(i + 1) % points.length];

      sum += (b.longitude - a.longitude) * (b.latitude + a.latitude);
    }
    return sum >= 0;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Polygon &&
          color == other.color &&
          borderStrokeWidth == other.borderStrokeWidth &&
          borderColor == other.borderColor &&
          disableHolesBorder == other.disableHolesBorder &&
          pattern == other.pattern &&
          // ignore: deprecated_member_use_from_same_package
          isFilled == other.isFilled &&
          strokeCap == other.strokeCap &&
          strokeJoin == other.strokeJoin &&
          label == other.label &&
          labelStyle == other.labelStyle &&
          labelPlacement == other.labelPlacement &&
          rotateLabel == other.rotateLabel &&
          hitValue == other.hitValue &&
          // Expensive computations last to take advantage of lazy logic gates
          listEquals(holePointsList, other.holePointsList) &&
          listEquals(points, other.points));

  // Used to batch draw calls to the canvas
  int? _renderHashCode;

  /// An optimized hash code dedicated to be used inside the [_PolygonPainter].
  ///
  /// Note that opacity is handled in the painter.
  int get renderHashCode => _renderHashCode ??= Object.hash(
        color,
        borderStrokeWidth,
        borderColor,
        disableHolesBorder,
        pattern,
        // ignore: deprecated_member_use_from_same_package
        isFilled,
        strokeCap,
        strokeJoin,
        _filledAndClockwise,
      );

  int? _hashCode;

  @override
  int get hashCode => _hashCode ??= Object.hashAll([
        ...points,
        label,
        labelStyle,
        labelPlacement,
        rotateLabel,
        renderHashCode,
      ]);
}

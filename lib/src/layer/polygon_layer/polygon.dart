part of 'polygon_layer.dart';

/// [Polygon] class, to be used for the [PolygonLayer].
class Polygon<R extends Object> with HitDetectableElement<R> {
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
  /// > [!IMPORTANT]
  /// > If polygons may be over the anti-meridan boundary,
  /// > [SimpleMultiWorldCentroidCalculator] must be used - other
  /// > calculators will produce unexpected results.
  ///
  /// See [labelPlacementCalculator] for more information.
  @Deprecated(
    'Use `labelPlacementCalculator` with the equivalent calculator instead. '
    'Then, remove any arguments to this parameter and allow it to default. '
    'This enables more flexibility and extensibility. '
    'This was deprecated after v8.2.0, and will be removed in a future version.',
  )
  final PolygonLabelPlacement labelPlacement;

  /// The calculator to use to determine the position of the [Polygon.label]
  ///
  /// Labels are not drawn if there is not enough space.
  ///
  /// > [!IMPORTANT]
  /// > If polygons may be over the anti-meridan boundary,
  /// > [PolygonLabelPlacementCalculator.simpleMultiWorldCentroid] must be
  /// > used - other calculators will produce unexpected results.
  ///
  /// Pre-provided calculators are available as constructors on
  /// [PolygonLabelPlacementCalculator]. See the documentation on each for
  /// advantages & disadvantages of each implementation.
  ///
  /// Defaults to [PolygonLabelPlacementCalculator.centroid]
  /// ([CentroidCalculator]).
  final PolygonLabelPlacementCalculator labelPlacementCalculator;

  /// Whether to rotate the label counter to the camera's rotation, to ensure
  /// it remains upright
  final bool rotateLabel;

  @override
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
  LatLng get labelPosition => _labelPosition ??= labelPlacementCalculator(this);

  LatLngBounds? _boundingBox;

  /// Get the bounding box of the [points] (cached).
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
    this.strokeCap = StrokeCap.round,
    this.strokeJoin = StrokeJoin.round,
    this.label,
    this.labelStyle = const TextStyle(),
    // TODO: Remove `labelPlacement`, and make `labelPlacementCalculator`
    // `this.` with default, then remove initialiser list
    @Deprecated(
      'Use `labelPlacementCalculator` with the equivalent calculator instead. '
      'Then, remove any arguments to this parameter and allow it to default. '
      'This enables more flexibility and extensibility. '
      'This was deprecated after v8.2.0, and will be removed in a future '
      'version.',
    )
    this.labelPlacement = PolygonLabelPlacement.centroid,

    /// See [labelPlacementCalculator]
    PolygonLabelPlacementCalculator? labelPlacementCalculator,
    this.rotateLabel = false,
    this.hitValue,
  })  : _filledAndClockwise = color != null && isClockwise(points),
        labelPlacementCalculator = labelPlacementCalculator ??
            switch (labelPlacement) {
              // ignore: deprecated_member_use_from_same_package
              PolygonLabelPlacement.centroid =>
                const PolygonLabelPlacementCalculator.centroid(),
              // ignore: deprecated_member_use_from_same_package
              PolygonLabelPlacement.centroidWithMultiWorld =>
                const PolygonLabelPlacementCalculator
                    .simpleMultiWorldCentroid(),
              // ignore: deprecated_member_use_from_same_package
              PolygonLabelPlacement.polylabel =>
                const PolygonLabelPlacementCalculator.polylabel(),
            };

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
          strokeCap == other.strokeCap &&
          strokeJoin == other.strokeJoin &&
          label == other.label &&
          labelStyle == other.labelStyle &&
          // ignore: deprecated_member_use_from_same_package
          labelPlacement == other.labelPlacement &&
          labelPlacementCalculator == other.labelPlacementCalculator &&
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
        // ignore: deprecated_member_use_from_same_package
        labelPlacement,
        labelPlacementCalculator,
        rotateLabel,
        renderHashCode,
      ]);
}

part of 'polygon_layer.dart';

/// Defines the algorithm used to calculate the position of the [Polygon] label.
enum PolygonLabelPlacement {
  /// Use the centroid of the [Polygon] outline as position for the label.
  centroid,

  /// Use the Mapbox Polylabel algorithm as position for the label.
  polylabel,
}

/// [Polygon] class, to be used for the [PolygonLayer].
class Polygon {
  /// The points for the outline of the [Polygon].
  final List<LatLng> points;

  /// The point lists that define holes in the [Polygon].
  final List<List<LatLng>>? holePointsList;

  /// The fill color of the [Polygon].
  final Color? color;

  /// The stroke with of the [Polygon] outline.
  final double borderStrokeWidth;

  /// The color of the [Polygon] outline.
  final Color borderColor;

  final bool disableHolesBorder;

  /// Set to true if the border of the [Polygon] should be rendered
  /// as dotted line.
  final bool isDotted;

  /// Set to true if the [Polygon] should be filled with a color.
  @Deprecated(
    'Prefer setting `color` to null to disable filling, or a `Color` to enable filling of that color. '
    'This parameter will be removed to simplify the API, as this was a remnant of pre-null-safety. '
    'The default of this parameter is now `null` and will use the rules above - the option is retained so as not to break APIs. '
    'This feature was deprecated after v7.',
  )
  final bool? isFilled;
  final StrokeCap strokeCap;
  final StrokeJoin strokeJoin;

  /// The optional label of the [Polygon].
  final String? label;

  /// The [TextStyle] of the [Polygon.label].
  final TextStyle labelStyle;

  /// The placement logic of the [Polygon.label]
  ///
  /// [PolygonLabelPlacement.polylabel] can be expensive for some polygons. If
  /// there is a large lag spike, try using [PolygonLabelPlacement.centroid].
  final PolygonLabelPlacement labelPlacement;

  /// Whether to rotate the label counter to the camera's rotation, to ensure
  /// it remains upright
  final bool rotateLabel;

  /// {@macro fm.PolygonLayer.performantRendering}
  ///
  /// Value meanings (defaults to `true`):
  ///
  /// - `true` : respect layer-level value (disabled by default)
  /// - `false`: disabled, ignore layer-level value
  ///
  /// Also see [PolygonLayer.performantRendering].
  final bool performantRendering;

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
    this.isDotted = false,
    @Deprecated(
      'Prefer setting `color` to null to disable filling, or a `Color` to enable filling of that color. '
      'This parameter will be removed to simplify the API, as this was a remnant of pre-null-safety. '
      'The default of this parameter is now `null` and will use the rules above - the option is retained so as not to break APIs. '
      'This feature was deprecated after v7.',
    )
    this.isFilled,
    this.strokeCap = StrokeCap.round,
    this.strokeJoin = StrokeJoin.round,
    this.label,
    this.labelStyle = const TextStyle(),
    this.labelPlacement = PolygonLabelPlacement.centroid,
    this.rotateLabel = false,
    this.performantRendering = true,
  }) : _filledAndClockwise =
            (isFilled ?? (color != null)) && isClockwise(points);

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
          isDotted == other.isDotted &&
          // ignore: deprecated_member_use_from_same_package
          isFilled == other.isFilled &&
          strokeCap == other.strokeCap &&
          strokeJoin == other.strokeJoin &&
          label == other.label &&
          labelStyle == other.labelStyle &&
          labelPlacement == other.labelPlacement &&
          rotateLabel == other.rotateLabel &&
          performantRendering == other.performantRendering &&
          // Expensive computations last to take advantage of lazy logic gates
          listEquals(holePointsList, other.holePointsList) &&
          listEquals(points, other.points));

  // Used to batch draw calls to the canvas
  int? _renderHashCode;

  /// An optimized hash code dedicated to be used inside the [PolygonPainter].
  int get renderHashCode => _renderHashCode ??= Object.hash(
        holePointsList,
        color,
        borderStrokeWidth,
        borderColor,
        disableHolesBorder,
        isDotted,
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
        performantRendering,
        renderHashCode,
      ]);
}

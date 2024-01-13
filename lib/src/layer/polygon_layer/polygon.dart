part of 'polygon_layer.dart';

enum PolygonLabelPlacement {
  centroid,
  polylabel,
}

class Polygon {
  final List<LatLng> points;
  final List<List<LatLng>>? holePointsList;

  final Color color;
  final double borderStrokeWidth;
  final Color borderColor;
  final bool disableHolesBorder;
  final bool isDotted;
  final bool isFilled;
  final StrokeCap strokeCap;
  final StrokeJoin strokeJoin;
  final String? label;
  final TextStyle labelStyle;
  final PolygonLabelPlacement labelPlacement;
  final bool rotateLabel;
  // Designates whether the given polygon points follow a clock or anti-clockwise direction.
  // This is respected during draw call batching for filled polygons. Otherwise, batched polygons
  // of opposing clock-directions cut holes into each other leading to a leaky optimization.
  final bool _filledAndClockwise;

  // Location where to place the label if `label` is set.
  LatLng? _labelPosition;
  LatLng get labelPosition =>
      _labelPosition ??= _computeLabelPosition(labelPlacement, points);

  LatLngBounds? _boundingBox;
  LatLngBounds get boundingBox =>
      _boundingBox ??= LatLngBounds.fromPoints(points);

  TextPainter? _textPainter;
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

  Polygon({
    required this.points,
    this.holePointsList,
    this.color = const Color(0xFF00FF00),
    this.borderStrokeWidth = 0.0,
    this.borderColor = const Color(0xFFFFFF00),
    this.disableHolesBorder = false,
    this.isDotted = false,
    this.isFilled = false,
    this.strokeCap = StrokeCap.round,
    this.strokeJoin = StrokeJoin.round,
    this.label,
    this.labelStyle = const TextStyle(),
    this.labelPlacement = PolygonLabelPlacement.centroid,
    this.rotateLabel = false,
  }) : _filledAndClockwise = isFilled && isClockwise(points);

  Polygon copyWithNewPoints(List<LatLng> points) => Polygon(
        points: points,
        holePointsList: holePointsList,
        color: color,
        borderStrokeWidth: borderStrokeWidth,
        borderColor: borderColor,
        disableHolesBorder: disableHolesBorder,
        isDotted: isDotted,
        strokeCap: strokeCap,
        strokeJoin: strokeJoin,
        label: label,
        labelStyle: labelStyle,
        labelPlacement: labelPlacement,
        rotateLabel: rotateLabel,
      );

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
          strokeCap == other.strokeCap &&
          strokeJoin == other.strokeJoin &&
          label == other.label &&
          labelStyle == other.labelStyle &&
          labelPlacement == other.labelPlacement &&
          rotateLabel == other.rotateLabel &&
          // Expensive computations last to take advantage of lazy logic gates
          listEquals(holePointsList, other.holePointsList) &&
          listEquals(points, other.points));

  // Used to batch draw calls to the canvas
  int? _renderHashCode;
  int get renderHashCode => _renderHashCode ??= Object.hash(
        holePointsList,
        color,
        borderStrokeWidth,
        borderColor,
        disableHolesBorder,
        isDotted,
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

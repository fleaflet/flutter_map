part of 'polyline_layer.dart';

/// A solid [Polyline] that paints a smooth gradient between vertex colors.
///
/// Map metrics recorded alongside GPS coordinates, such as speed, elevation,
/// heart rate, or accuracy, to one color per coordinate.
///
/// Layer simplification retains source indices and limits sampled color error
/// to 0.02 per RGBA channel. Set [PolylineLayer.simplificationTolerance] to zero
/// to render every recorded sample.
///
/// Consecutive segments use round joins. Line endings use [strokeCap].
class MulticolorPolyline<R extends Object> extends Polyline<R> {
  /// The color applied at each vertex in [points].
  ///
  /// When `null` or empty, [defaultColor] is used instead.
  final List<Color>? vertexColors;

  /// The fallback color used when no [vertexColors] are provided.
  final Color defaultColor;

  /// Optional colors used only to select simplification vertices.
  ///
  /// Supply the foreground's vertex colors for a separate solid outline so
  /// both strokes retain identical geometry. Defaults to [vertexColors].
  final List<Color>? simplificationColors;

  int? _multicolorRenderHashCode;
  int? _multicolorHashCode;
  List<Color>? _resolvedColors;

  /// Create a multicolor polyline that interpolates between the supplied
  /// [vertexColors].
  // Super parameters cannot initialize `color`, which is derived from
  // `vertexColors` and `defaultColor`.
  // ignore: use_super_parameters
  MulticolorPolyline({
    required List<LatLng> points,
    List<Color>? vertexColors,
    List<Color>? simplificationColors,
    this.defaultColor = const Color(0xFF00FF00),
    double strokeWidth = 1.0,
    double borderStrokeWidth = 0.0,
    Color borderColor = const Color(0xFFFFFF00),
    StrokeCap strokeCap = StrokeCap.round,
    bool useStrokeWidthInMeter = false,
    R? hitValue,
  })  : vertexColors = _validateVertexColors(points, vertexColors),
        simplificationColors =
            _validateVertexColors(points, simplificationColors),
        super(
          points: points,
          strokeWidth: strokeWidth,
          pattern: const StrokePattern.solid(),
          color: (vertexColors != null && vertexColors.isNotEmpty)
              ? vertexColors.first
              : defaultColor,
          borderStrokeWidth: borderStrokeWidth,
          borderColor: borderColor,
          gradientColors: null,
          colorsStop: null,
          strokeCap: strokeCap,
          strokeJoin: StrokeJoin.round,
          useStrokeWidthInMeter: useStrokeWidthInMeter,
          hitValue: hitValue,
        );

  late final bool _hasTransparentVertices = vertexColors == null
      ? defaultColor.a < 1
      : vertexColors!.any((color) => color.a < 1);

  late final bool _isOpaqueSolid = color.a == 1 &&
      (vertexColors == null ||
          vertexColors!.every((vertex) => vertex == color));

  List<Color> get _resolvedVertexColors => _resolvedColors ??=
      vertexColors ?? List<Color>.filled(points.length, defaultColor);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MulticolorPolyline<R> &&
          super == other &&
          defaultColor == other.defaultColor &&
          listEquals(simplificationColors, other.simplificationColors) &&
          listEquals(vertexColors, other.vertexColors));

  @override
  int get renderHashCode => _multicolorRenderHashCode ??= Object.hash(
      super.renderHashCode,
      defaultColor,
      simplificationColors == null
          ? null
          : Object.hashAll(simplificationColors!),
      vertexColors == null ? null : Object.hashAll(vertexColors!));

  @override
  int get hashCode => _multicolorHashCode ??= Object.hash(
      super.hashCode,
      defaultColor,
      vertexColors == null ? null : Object.hashAll(vertexColors!));
}

List<Color>? _validateVertexColors(
  List<LatLng> points,
  List<Color>? vertexColors,
) {
  if (points.length < 2) {
    throw ArgumentError.value(
      points,
      'points',
      'MulticolorPolyline requires at least two points',
    );
  }
  if (vertexColors == null || vertexColors.isEmpty) return null;
  if (points.length != vertexColors.length) {
    throw ArgumentError.value(
      vertexColors,
      'vertexColors',
      'length must match points length',
    );
  }
  return List<Color>.unmodifiable(vertexColors);
}

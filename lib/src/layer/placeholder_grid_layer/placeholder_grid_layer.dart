import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';

part 'painter.dart';

/// Layer which draws a grid consisting of orthogonal major and minor strokes,
/// configured by a [PlaceholderGridOptions].
///
/// This layer is usually drawn by default on the map background, but can be
/// inserted manually. See [MapOptions.backgroundGridOptions] for info.
///
/// This layer is intended for use in a [FlutterMap]. However, it will work
/// without being placed in one.
class PlaceholderGridLayer extends StatelessWidget {
  /// Build a widget which draws a grid consisting of orthogonal major and minor
  /// strokes, configured by a [PlaceholderGridOptions].
  ///
  /// The widget does not have to be used within a map context.
  const PlaceholderGridLayer({
    super.key,
    this.gridOptions = const PlaceholderGridOptions(),
  });

  /// Configuration of the grid drawn.
  final PlaceholderGridOptions gridOptions;

  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.maybeOf(context);

    late final autoGridColor = () {
      const delta = 0.15;

      if (MapOptions.maybeOf(context)?.backgroundColor case final color?) {
        final hsl = HSLColor.fromColor(color);
        return hsl
            .withLightness(
              ((hsl.lightness > 0.5 ? -delta : delta) + hsl.lightness)
                  .clamp(0, 1),
            )
            .toColor();
      }
    }();
    final static = gridOptions.static || camera == null;
    final spacing = gridOptions.spacing *
        (static
            ? 1
            : camera.getZoomScale(camera.zoom, camera.zoom.floorToDouble()));

    final painted = CustomPaint(
      painter: _BackgroundGridPainter(
        color: gridOptions.color ?? autoGridColor ?? const Color(0x14000000),
        spacing: spacing,
        pixelOrigin: static ? null : camera.pixelOrigin,
        numOfMinors: gridOptions.numOfMinors,
        majorStrokeWidth: gridOptions.majorStrokeWidth,
        minorStrokeWidth: gridOptions.minorStrokeWidth,
      ),
    );
    if (static) return painted;
    return MobileLayerTransformer(child: painted);
  }
}

/// Configuration options for a [PlaceholderGridLayer], which is usually
/// displayed on the map background.
///
/// The grid consists of orthogonal major and minor strokes.
@immutable
class PlaceholderGridOptions {
  /// Color of the grid strokes.
  ///
  /// Defaults to a slightly ligher or darker shade of the
  /// [MapOptions.backgroundColor], based on if it's dark or light respectively.
  ///
  /// If no inherited [MapOptions] is available, the default color is a
  /// translucent black.
  final Color? color;

  /// Gap between major strokes (at integer zoom levels when [static] is
  /// `false`), in logical pixels.
  ///
  /// To ensure a grid is visible while tiles are loading in holes, it's
  /// recommended to set this to a smaller value than the tile size.
  ///
  /// Defaults to 64.
  final double spacing;

  /// Whether the grid should be static and not move or zoom with the map,
  /// instead of its default behaviour of moving and scaling with zoom levels.
  ///
  /// If no inherited [MapCamera] is available, the grid is always static.
  final bool static;

  /// Thickness of major strokes.
  ///
  /// Defaults to 1.5.
  final double majorStrokeWidth;

  /// Thickness of minor strokes.
  ///
  /// Defaults to 0 (a hairline stroke).
  final double minorStrokeWidth;

  /// Number of minor strokes to insert between major strokes.
  ///
  /// Defaults to 3. Set to 0 to disable minor strokes.
  final int numOfMinors;

  /// Configuration options for a grid, usually displayed on the map background.
  const PlaceholderGridOptions({
    this.color,
    this.spacing = 64,
    this.static = false,
    this.majorStrokeWidth = 1.5,
    this.minorStrokeWidth = 0,
    this.numOfMinors = 3,
  })  : assert(
          spacing >= 1 && spacing < double.infinity,
          '`spacing` must be equal to or greater than one, and finite',
        ),
        assert(
          majorStrokeWidth >= 0,
          '`majorStrokeWidth` must be equal to or greater than zero',
        ),
        assert(
          minorStrokeWidth >= 0,
          '`minorStrokeWidth` must be equal to or greater than zero',
        ),
        assert(
          numOfMinors >= 0,
          '`numOfMinors` must be equal to or greater than zero',
        );

  @override
  int get hashCode => Object.hash(
        color,
        spacing,
        static,
        majorStrokeWidth,
        minorStrokeWidth,
        numOfMinors,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlaceholderGridOptions &&
          color == other.color &&
          spacing == other.spacing &&
          static == other.static &&
          majorStrokeWidth == other.majorStrokeWidth &&
          minorStrokeWidth == other.minorStrokeWidth &&
          numOfMinors == other.numOfMinors;
}

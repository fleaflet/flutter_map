import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';

@immutable
class RasterTileLayerOptions {
  const RasterTileLayerOptions({
    this.crs,
    this.basePaint,
    this.paintTile,
  });

  final Crs? crs;

  /// Optional custom [Paint] which is used (potentially with further
  /// modifications) to render tile raster images to the canvas.
  ///
  /// It is recommended to set:
  ///  - [Paint.filterQuality] to [FilterQuality.high] (to maximize image
  ///    quality)
  ///  - [Paint.isAntiAlias] to `false` (to avoid hairline fractures between
  ///    tiles)
  ///
  /// These are the default properties if unset.
  final Paint? basePaint;

  /// Optional callback responsible for painting tiles onto the canvas.
  ///
  /// If left unset, the painting algorithm is simple and uses the [basePaint]
  /// (if set, otherwise the default).
  ///
  /// ---
  ///
  /// This callback works by providing a sub-`canvas`, which has the `size` of
  /// the tile scaled for the current zoom level. When this `canvas` is applied
  /// to the layer canvas, it is positioned at the screen position of the tile.
  /// See [CustomPainter.paint] for more image about painting onto a canvas.
  ///
  /// The tile image and any other custom drawings should be painted onto the
  /// provided `canvas`, usually without any overflow. The non-overflowing area
  /// `Rect` is given by:
  ///
  /// ```dart
  /// final rect = Offset.zero & size;
  /// // To clip all operations to the non-overflowing area, if necessary:
  /// canvas.clipRect(rect);
  /// ```
  ///
  /// `tileCoordinates` and `tileData` are information about the tile currently
  /// being painted.
  ///
  /// `tilePaint` is initially the [basePaint] (if set, otherwise the default).
  /// `tilePaint` may be modified in the callback. If so, the modified paint
  /// is then reused for every subsequent paint. Therefore, it is important to
  /// re-modify any modified properties on every paint. Therefore, if only the
  /// same properties that [basePaint] sets are modified, then there is no use
  /// for [basePaint]. This behaviour is used to improve performance: only one
  /// [Paint] object is constructed by default. Note that any [Paint.color] set
  /// may have no effect, except for its [Color.a] field, which may be changed
  /// by the renderer.
  ///
  /// `drawImage` should be called in the callback. It uses the `tilePaint` to
  /// draw the tile's image into the supplied argument `destRect` (the entire
  /// available tile `canvas` if unset).
  ///
  /// For example, to shrink the tile image to leave a 20 logical pixel margin
  /// on the right and bottom sides:
  ///
  /// ```dart
  /// paintTile: (canvas, size, tileCoordinates, tileData,
  ///     tilePaint, drawImage) {
  ///   drawImage(
  ///     destRect: Offset.zero & ((size - Offset(20, 20)) as Size),
  ///   );
  /// },
  /// ```
  ///
  /// Only calling `drawImage` without any arguments is equivalent to not
  /// setting this callback.
  final void Function(
    Canvas canvas,
    Size size,
    TileCoordinates tileCoordinates,
    RasterTileData tileData,
    Paint tilePaint,
    void Function({Rect? destRect}) drawImage,
  )? paintTile;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RasterTileLayerOptions &&
          crs == other.crs &&
          basePaint == other.basePaint &&
          paintTile == other.paintTile);

  @override
  int get hashCode => Object.hash(crs, basePaint, paintTile);
}

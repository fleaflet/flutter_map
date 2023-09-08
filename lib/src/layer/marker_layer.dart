import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_map/src/map/camera/camera.dart';
import 'package:flutter_map/src/misc/bounds.dart';
import 'package:flutter_map/src/misc/point_extensions.dart';
import 'package:latlong2/latlong.dart';

/// Defines the positioning of a [Marker.builder] widget relative to the center
/// of its bounding box
///
/// Can be defined exactly (using [AnchorPos.exactly] with an [Anchor]) or in
/// a relative/dynamic alignment (using [AnchorPos.align] with an [Alignment]).
///
/// If using [AnchorPos.align], the provided [AlignmentGeometry]'s factors must
/// be either -1, 1, or 0 only (ie. the pre-provided [Alignment]s).
/// [textDirection] will default to [TextDirection.ltr], and is used to resolve
/// the [AlignmentGeometry].
@immutable
class AnchorPos {
  /// The default, central alignment
  static const defaultAnchorPos = AnchorPos.align(Alignment.center);

  /// Exact left/top anchor
  ///
  /// Set only if constructed with [AnchorPos.exactly].
  final Anchor? anchor;

  /// Relative/dynamic alignment
  ///
  /// Transformed into [anchor] at runtime by [Anchor.fromPos]. Resolved by
  /// [textDirection].
  ///
  /// Set only if constructed with [AnchorPos.align].
  final AlignmentGeometry? alignment;

  /// Used to resolve [alignment].
  ///
  /// Set only if constructed with [AnchorPos.align].
  final TextDirection? textDirection;

  /// Defines the positioning of a [Marker.builder] widget relative to the center
  /// of its bounding box, with an exact left/top anchor
  const AnchorPos.exactly(Anchor this.anchor)
      : alignment = null,
        textDirection = null;

  /// Defines the positioning of a [Marker.builder] widget relative to the center
  /// of its bounding box, with a relative/dynamic alignment
  ///
  /// [alignment]'s factors must be either -1, 1, or 0 only (ie. the pre-provided
  /// [Alignment]s). [textDirection] will default to [TextDirection.ltr], and is
  /// used to resolve the [AlignmentGeometry].
  const AnchorPos.align(
    AlignmentGeometry this.alignment, {
    this.textDirection = TextDirection.ltr,
  }) : anchor = null;
}

/// Exact alignment for a [Marker.builder] widget relative to the center
/// of its bounding box defined by its [Marker.height] & [Marker.width]
///
/// May be generated from an [AnchorPos] (usually with [AnchorPos.alignment]
/// defined) and dimensions through [Anchor.fromPos].
@immutable
class Anchor {
  final double left;
  final double top;

  const Anchor(this.left, this.top);

  factory Anchor.fromPos(AnchorPos pos, double width, double height) {
    if (pos.anchor case final anchor?) return anchor;
    if (pos.alignment case final alignment?) {
      return Anchor(
        switch (alignment.resolve(pos.textDirection).x) {
          -1 => 0,
          1 => width,
          0 => width / 2,
          _ => throw ArgumentError.value(
              alignment,
              'alignment',
              'The `x` factor must be -1, 1, or 0 only (ie. the pre-provided alignments)',
            ),
        },
        switch (alignment.resolve(pos.textDirection).y) {
          -1 => 0,
          1 => height,
          0 => height / 2,
          _ => throw ArgumentError.value(
              alignment,
              'alignment',
              'The `y` factor must be -1, 1, or 0 only (ie. the pre-provided alignments)',
            ),
        },
      );
    }
    throw Exception();
  }
}

/// Represents a coordinate point on the map with an attached widget [builder],
/// rendered by [MarkerLayer]
///
/// Some properties defaults will absorb the values from the parent [MarkerLayer],
/// if the reflected properties are defined there.
@immutable
class Marker {
  final Key? key;

  /// Coordinates of the marker
  final LatLng point;

  /// Function that builds UI of the marker
  final WidgetBuilder builder;

  /// Bounding box width of the marker
  final double width;

  /// Bounding box height of the marker
  final double height;

  /// Positioning of the [builder] widget relative to the center of its bounding
  /// box.
  final Anchor? anchor;

  /// Whether to counter rotate markers to the map's rotation, to keep a fixed
  /// orientation
  final bool? rotate;

  /// The origin of the coordinate system (relative to the upper left corner of
  /// this render object) in which to apply the matrix.
  ///
  /// Setting an origin is equivalent to conjugating the transform matrix by a
  /// translation. This property is provided just for convenience.
  final Offset? rotateOrigin;

  /// The alignment of the origin, relative to the size of the box.
  ///
  /// Automatically set to the opposite of `anchorPos`, if it was constructed by
  /// [AnchorPos.align], but can be overridden.
  ///
  /// This is equivalent to setting an origin based on the size of the box.
  /// If it is specified at the same time as the [rotateOrigin], both are applied.
  ///
  /// An [AlignmentDirectional.centerStart] value is the same as an [Alignment]
  /// whose [Alignment.x] value is `-1.0` if [Directionality.of] returns
  /// [TextDirection.ltr], and `1.0` if [Directionality.of] returns
  /// [TextDirection.rtl].	 Similarly [AlignmentDirectional.centerEnd] is the
  /// same as an [Alignment] whose [Alignment.x] value is `1.0` if
  /// [Directionality.of] returns	 [TextDirection.ltr], and `-1.0` if
  /// [Directionality.of] returns [TextDirection.rtl].
  final AlignmentGeometry? rotateAlignment;

  Marker({
    this.key,
    required this.point,
    required this.builder,
    this.width = 30.0,
    this.height = 30.0,
    AnchorPos? anchorPos,
    this.rotate,
    this.rotateOrigin,
    AlignmentGeometry? rotateAlignment,
  })  : anchor =
            anchorPos == null ? null : Anchor.fromPos(anchorPos, width, height),
        rotateAlignment = rotateAlignment ??
            (anchorPos?.alignment != null ? anchorPos!.alignment! * -1 : null);
}

@immutable
class MarkerLayer extends StatelessWidget {
  final List<Marker> markers;

  /// Positioning of the [Marker.builder] widget relative to the center of its
  /// bounding box defined by its [Marker.height] & [Marker.width]
  ///
  /// Overriden on a per [Marker] basis if [Marker.anchorPos] is specified.
  final AnchorPos? anchorPos;

  /// Whether to counter rotate markers to the map's rotation, to keep a fixed
  /// orientation
  ///
  /// Overriden on a per [Marker] basis if [Marker.rotate] is specified.
  final bool rotate;

  /// The origin of the coordinate system (relative to the upper left corner of
  /// this render object) in which to apply the matrix.
  ///
  /// Setting an origin is equivalent to conjugating the transform matrix by a
  /// translation. This property is provided just for convenience.
  ///
  /// Overriden on a per [Marker] basis if [Marker.rotateOrigin] is specified.
  final Offset? rotateOrigin;

  /// The alignment of the origin, relative to the size of the box.
  ///
  /// Automatically set to the opposite of `anchorPos`, if it was constructed by
  /// [AnchorPos.align], but can be overridden.
  ///
  /// This is equivalent to setting an origin based on the size of the box.
  /// If it is specified at the same time as the [rotateOrigin], both are applied.
  ///
  /// An [AlignmentDirectional.centerStart] value is the same as an [Alignment]
  /// whose [Alignment.x] value is `-1.0` if [Directionality.of] returns
  /// [TextDirection.ltr], and `1.0` if [Directionality.of] returns
  /// [TextDirection.rtl].	 Similarly [AlignmentDirectional.centerEnd] is the
  /// same as an [Alignment] whose [Alignment.x] value is `1.0` if
  /// [Directionality.of] returns	 [TextDirection.ltr], and `-1.0` if
  /// [Directionality.of] returns [TextDirection.rtl].
  ///
  /// Overriden on a per [Marker] basis if [Marker.rotateAlignment] is specified.
  final AlignmentGeometry? rotateAlignment;

  const MarkerLayer({
    super.key,
    this.markers = const [],
    this.anchorPos,
    this.rotate = false,
    this.rotateOrigin,
    this.rotateAlignment,
  });

  @override
  Widget build(BuildContext context) {
    final map = MapCamera.of(context);
    final markerWidgets = <Widget>[];

    for (final marker in markers) {
      final pxPoint = map.project(marker.point);

      // See if any portion of the Marker rect resides in the map bounds
      // If not, don't spend any resources on build function.
      // This calculation works for any Anchor position whithin the Marker
      // Note that Anchor coordinates of (0,0) are at bottom-right of the Marker
      // unlike the map coordinates.
      final anchor = marker.anchor ??
          Anchor.fromPos(
            anchorPos ?? AnchorPos.defaultAnchorPos,
            marker.width,
            marker.height,
          );
      final rightPortion = marker.width - anchor.left;
      final leftPortion = anchor.left;
      final bottomPortion = marker.height - anchor.top;
      final topPortion = anchor.top;
      if (!map.pixelBounds.containsPartialBounds(Bounds(
          Point(pxPoint.x + leftPortion, pxPoint.y - bottomPortion),
          Point(pxPoint.x - rightPortion, pxPoint.y + topPortion)))) {
        continue;
      }

      final defaultAlignment = anchorPos?.alignment != null
          ? anchorPos!.alignment! * -1
          : Alignment.center;

      final pos = pxPoint.subtract(map.pixelOrigin);
      final markerWidget = (marker.rotate ?? rotate)
          ? Transform.rotate(
              angle: -map.rotationRad,
              origin: marker.rotateOrigin ?? rotateOrigin ?? Offset.zero,
              alignment:
                  marker.rotateAlignment ?? rotateAlignment ?? defaultAlignment,
              child: marker.builder(context),
            )
          : marker.builder(context);

      markerWidgets.add(
        Positioned(
          key: marker.key,
          width: marker.width,
          height: marker.height,
          left: pos.x - rightPortion,
          top: pos.y - bottomPortion,
          child: markerWidget,
        ),
      );
    }
    return Stack(children: markerWidgets);
  }
}

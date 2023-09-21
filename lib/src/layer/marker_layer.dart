import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_map/src/map/camera/camera.dart';
import 'package:flutter_map/src/misc/point_extensions.dart';
import 'package:flutter_map/src/misc/private/bounds.dart';
import 'package:latlong2/latlong.dart';

/// Defines the positioning of a [Marker.builder] widget relative to the center
/// of its bounding box
///
/// The provided [AlignmentGeometry]'s factors must be either -1, 1, or 0 only
/// (i.e. the pre-provided [Alignment]s). [textDirection] will default to
/// [TextDirection.ltr], and is used to resolve the [AlignmentGeometry].
@immutable
class AnchorPos {
  /// The default, central alignment
  static const defaultAnchorPos = AnchorPos(Alignment.center);

  /// Relative/dynamic alignment geometry.
  ///
  /// Transformed into [anchor] at runtime by [Anchor.fromPos]. Resolved by
  /// [textDirection].
  final AlignmentGeometry geometry;

  /// Used to resolve [alignment].
  final TextDirection textDirection;

  /// Defines the positioning of a [Marker.builder] widget relative to the center
  /// of its bounding box, with a relative/dynamic alignment
  ///
  /// [alignment]'s factors must be either -1, 1, or 0 only (ie. the pre-provided
  /// [Alignment]s). [textDirection] will default to [TextDirection.ltr], and is
  /// used to resolve the [AlignmentGeometry].
  const AnchorPos(
    this.geometry, {
    this.textDirection = TextDirection.ltr,
  });
}

/// Exact alignment for a [Marker.builder] widget relative to the center
/// of its bounding box defined by its [Marker.height] & [Marker.width]
///
/// May be generated from an [AnchorPos] (usually with [AnchorPos.geometry]
/// defined) and dimensions through [Anchor.fromPos].
@immutable
class Anchor {
  final double left;
  final double top;

  const Anchor(this.left, this.top);

  factory Anchor.fromPos(AnchorPos pos, double width, double height) {
    final geometry = pos.geometry;
    return Anchor(
      switch (geometry.resolve(pos.textDirection).x) {
        -1 => 0,
        1 => width,
        0 => width / 2,
        _ => throw ArgumentError.value(
            geometry,
            'alignment',
            'The `x` factor must be -1, 1, or 0 only (ie. the pre-provided alignments)',
          ),
      },
      switch (geometry.resolve(pos.textDirection).y) {
        -1 => 0,
        1 => height,
        0 => height / 2,
        _ => throw ArgumentError.value(
            geometry,
            'alignment',
            'The `y` factor must be -1, 1, or 0 only (ie. the pre-provided alignments)',
          ),
      },
    );
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
  /// Automatically set to the opposite of `alignment`, if it was constructed by
  /// [Marker.align], but can be overridden.
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

  const Marker({
    this.key,
    required this.point,
    required this.builder,
    this.width = 30.0,
    this.height = 30.0,
    this.anchor,
    this.rotate,
    this.rotateOrigin,
    this.rotateAlignment,
  });

  Marker.positioned({
    this.key,
    required this.point,
    required this.builder,
    this.width = 30.0,
    this.height = 30.0,
    AnchorPos? position,
    this.rotate,
    this.rotateOrigin,
    AlignmentGeometry? rotateAlignment,
  })  : anchor =
            position == null ? null : Anchor.fromPos(position, width, height),
        rotateAlignment = rotateAlignment ??
            (position != null ? position.geometry * -1 : null);
}

@immutable
class MarkerLayer extends StatelessWidget {
  final List<Marker> markers;

  /// Positioning of the [Marker.builder] widget relative to the center of its
  /// bounding box defined by its [Marker.height] & [Marker.width]
  ///
  /// Overriden on a per [Marker] basis if [Marker.alignment] is specified.
  final AnchorPos? position;

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
  /// Automatically set to the opposite of `alignment`, if it was constructed by
  /// [AnchorPos], but can be overridden.
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
    this.position,
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
            position ?? AnchorPos.defaultAnchorPos,
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

      final defaultRotateAlignment =
          position != null ? position!.geometry * -1 : Alignment.center;

      final pos = pxPoint.subtract(map.pixelOrigin);
      final markerWidget = (marker.rotate ?? rotate)
          ? Transform.rotate(
              angle: -map.rotationRad,
              origin: marker.rotateOrigin ?? rotateOrigin ?? Offset.zero,
              alignment: marker.rotateAlignment ??
                  rotateAlignment ??
                  defaultRotateAlignment,
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

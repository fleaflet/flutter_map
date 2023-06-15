import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/map/flutter_map_frame.dart';
import 'package:flutter_map/src/misc/private/bounds.dart';
import 'package:latlong2/latlong.dart';

/// Defines the positioning of a [Marker.builder] widget relative to the center
/// of its bounding box defined by its [Marker.height] & [Marker.width]
///
/// Can be defined exactly (using [AnchorPos.exactly] with an [Anchor]) or in
/// a relative alignment (using [AnchorPos.align] with an [AnchorAlign]).
class AnchorPos {
  static const defaultAnchorPos = AnchorPos.align(AnchorAlign.center);

  final Anchor? anchor;
  final AnchorAlign? alignment;

  const AnchorPos.exactly(Anchor this.anchor) : alignment = null;
  const AnchorPos.align(AnchorAlign this.alignment) : anchor = null;
}

/// Exact alignment for a [Marker.builder] widget relative to the center
/// of its bounding box defined by its [Marker.height] & [Marker.width]
///
/// May be generated from an [AnchorPos] (usually with [AnchorPos.alignment]
/// defined) and dimensions through [Anchor.fromPos].
class Anchor {
  final double left;
  final double top;

  const Anchor(this.left, this.top);

  factory Anchor.fromPos(AnchorPos pos, double width, double height) {
    if (pos.anchor case final anchor?) return anchor;
    if (pos.alignment case final alignment?) {
      return Anchor(
        switch (alignment._x) { -1 => 0, 1 => width, _ => width / 2 },
        switch (alignment._y) { 1 => 0, -1 => height, _ => height / 2 },
      );
    }
    throw Exception();
  }
}

/// Relative alignment for a [Marker.builder] widget relative to the center
/// of its bounding box defined by its [Marker.height] & [Marker.width]
enum AnchorAlign {
  topLeft(-1, 1),
  topRight(1, 1),
  bottomLeft(-1, -1),
  bottomRight(1, -1),

  center(0, 0),

  /// Top center
  top(0, 1),

  /// Bottom center
  bottom(0, -1),

  /// Left center
  left(-1, 0),

  /// Right center
  right(1, 0),

  @Deprecated(
    'Prefer `center`. '
    'This value is equivalent to the `center` alignment. '
    'If you notice a difference in behaviour, please open a bug report on GitHub. '
    'This feature is deprecated since v5.',
  )
  none(0, 0);

  final int _x;
  final int _y;

  const AnchorAlign(this._x, this._y);
}

/// Represents a coordinate point on the map with an attached widget [builder],
/// rendered by [MarkerLayer]
///
/// Some properties defaults will absorb the values from the parent [MarkerLayer],
/// if the reflected properties are defined there.
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
    this.rotateAlignment,
  }) : anchor =
            anchorPos == null ? null : Anchor.fromPos(anchorPos, width, height);
}

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
    this.rotateAlignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    final map = MapFrame.of(context);
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
          CustomPoint(pxPoint.x + leftPortion, pxPoint.y - bottomPortion),
          CustomPoint(pxPoint.x - rightPortion, pxPoint.y + topPortion)))) {
        continue;
      }

      final pos = pxPoint - map.pixelOrigin;
      final markerWidget = (marker.rotate ?? rotate)
          ? Transform.rotate(
              angle: -map.rotationRad,
              origin: marker.rotateOrigin ?? rotateOrigin ?? Offset.zero,
              alignment: marker.rotateAlignment ?? rotateAlignment,
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

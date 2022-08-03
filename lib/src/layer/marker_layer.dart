import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/core/bounds.dart';
import 'package:flutter_map/src/map/map.dart';
import 'package:latlong2/latlong.dart';

/// Configuration for marker layer
class MarkerLayerOptions {
  final List<Marker> markers;

  /// Toggle marker position caching. Enabling will improve performance, but may introducen
  /// errors when adding/removing markers. Default is enabled (`true`).
  final bool usePxCache;

  /// If true markers will be counter rotated to the map rotation
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

  MarkerLayerOptions({
    this.markers = const [],
    this.rotate = false,
    this.rotateOrigin,
    this.rotateAlignment = Alignment.center,
    this.usePxCache = true,
  });
}

class Anchor {
  final double left;
  final double top;

  Anchor(this.left, this.top);

  Anchor._(double width, double height, AnchorAlign alignOpt)
      : left = _leftOffset(width, alignOpt),
        top = _topOffset(height, alignOpt);

  static double _leftOffset(double width, AnchorAlign alignOpt) {
    switch (alignOpt) {
      case AnchorAlign.left:
        return 0;
      case AnchorAlign.right:
        return width;
      case AnchorAlign.top:
      case AnchorAlign.bottom:
      case AnchorAlign.center:
      default:
        return width / 2;
    }
  }

  static double _topOffset(double height, AnchorAlign alignOpt) {
    switch (alignOpt) {
      case AnchorAlign.top:
        return 0;
      case AnchorAlign.bottom:
        return height;
      case AnchorAlign.left:
      case AnchorAlign.right:
      case AnchorAlign.center:
      default:
        return height / 2;
    }
  }

  factory Anchor.forPos(AnchorPos<dynamic>? pos, double width, double height) {
    if (pos == null) return Anchor._(width, height, AnchorAlign.none);
    if (pos.value is AnchorAlign) {
      return Anchor._(width, height, pos.value as AnchorAlign);
    }
    if (pos.value is Anchor) return pos.value as Anchor;
    throw Exception('Unsupported AnchorPos value type: ${pos.runtimeType}.');
  }
}

class AnchorPos<T> {
  AnchorPos._(this.value);
  T value;
  static AnchorPos<Anchor> exactly(Anchor anchor) =>
      AnchorPos<Anchor>._(anchor);
  static AnchorPos<AnchorAlign> align(AnchorAlign alignOpt) =>
      AnchorPos<AnchorAlign>._(alignOpt);
}

enum AnchorAlign {
  none,
  left,
  right,
  top,
  bottom,
  center,
}

/// Marker object that is rendered by [MarkerLayerWidget]
class Marker {
  /// Coordinates of the marker
  final LatLng point;

  /// Function that builds UI of the marker
  final WidgetBuilder builder;
  final Key? key;

  /// Bounding box width of the marker
  final double width;

  /// Bounding box height of the marker
  final double height;
  final Anchor anchor;

  /// If true marker will be counter rotated to the map rotation
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
    required this.point,
    required this.builder,
    this.key,
    this.width = 30.0,
    this.height = 30.0,
    this.rotate,
    this.rotateOrigin,
    this.rotateAlignment,
    AnchorPos<dynamic>? anchorPos,
  }) : anchor = Anchor.forPos(anchorPos, width, height);
}

class MarkerLayerWidget extends StatelessWidget {
  final MarkerLayerOptions options;

  const MarkerLayerWidget({super.key, required this.options});

  @override
  Widget build(BuildContext context) {
    final mapState = MapState.maybeOf(context)!;
    return MarkerLayer(key: key, markerLayerOptions: options, map: mapState);
  }
}

class MarkerLayer extends StatefulWidget {
  final MarkerLayerOptions markerLayerOptions;
  final MapState map;

  const MarkerLayer(
      {super.key, required this.markerLayerOptions, required this.map});

  @override
  State<MarkerLayer> createState() => _MarkerLayerState();
}

class _MarkerLayerState extends State<MarkerLayer> {
  double lastZoom = -1;

  /// List containing cached pixel positions of markers
  /// Should be discarded when zoom changes
  // Has a fixed length of markerOpts.markers.length - better performance:
  // https://stackoverflow.com/questions/15943890/is-there-a-performance-benefit-in-using-fixed-length-lists-in-dart
  var _pxCache = <CustomPoint>[];

  /// Calling this every time markerOpts change should guarantee proper length
  List<CustomPoint> generatePxCache() {
    if (widget.markerLayerOptions.usePxCache) {
      return List.generate(
        widget.markerLayerOptions.markers.length,
        (i) => widget.map.project(widget.markerLayerOptions.markers[i].point),
      );
    }
    return [];
  }

  bool updatePxCacheIfNeeded() {
    var didUpdate = false;

    /// markers may be modified, so update cache. Note, someone may
    /// have not added to a cache, but modified, so this won't catch
    /// this case. Parent widget setState should be called to call
    /// didUpdateWidget to force a cache reload

    if (widget.markerLayerOptions.markers.length != _pxCache.length) {
      _pxCache = generatePxCache();
      didUpdate = true;
    }
    return didUpdate;
  }

  @override
  void initState() {
    super.initState();
    _pxCache = generatePxCache();
  }

  @override
  void didUpdateWidget(covariant MarkerLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    lastZoom = -1.0;
    _pxCache = generatePxCache();
  }

  @override
  Widget build(BuildContext context) {
    final layerOptions = widget.markerLayerOptions;
    final map = widget.map;
    final usePxCache = layerOptions.usePxCache;
    final markers = <Widget>[];
    final sameZoom = map.zoom == lastZoom;

    final cacheUpdated = updatePxCacheIfNeeded();

    for (var i = 0; i < layerOptions.markers.length; i++) {
      final marker = layerOptions.markers[i];

      // Decide whether to use cached point or calculate it
      final pxPoint = usePxCache && (sameZoom || cacheUpdated)
          ? _pxCache[i]
          : map.project(marker.point);
      if (!sameZoom && usePxCache) {
        _pxCache[i] = pxPoint;
      }

      // See if any portion of the Marker rect resides in the map bounds
      // If not, don't spend any resources on build function.
      // This calculation works for any Anchor position whithin the Marker
      // Note that Anchor coordinates of (0,0) are at bottom-right of the Marker
      // unlike the map coordinates.
      final rightPortion = marker.width - marker.anchor.left;
      final leftPortion = marker.anchor.left;
      final bottomPortion = marker.height - marker.anchor.top;
      final topPortion = marker.anchor.top;

      final sw =
          CustomPoint(pxPoint.x + leftPortion, pxPoint.y - bottomPortion);
      final ne = CustomPoint(pxPoint.x - rightPortion, pxPoint.y + topPortion);

      if (!map.pixelBounds.containsPartialBounds(Bounds(sw, ne))) {
        continue;
      }

      final pos = pxPoint - map.getPixelOrigin();
      final markerWidget = (marker.rotate ?? layerOptions.rotate ?? false)
          // Counter rotated marker to the map rotation
          ? Transform.rotate(
              angle: -map.rotationRad,
              origin: marker.rotateOrigin ?? layerOptions.rotateOrigin,
              alignment: marker.rotateAlignment ?? layerOptions.rotateAlignment,
              child: marker.builder(context),
            )
          : marker.builder(context);

      markers.add(
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
    lastZoom = map.zoom;
    return Stack(
      children: markers,
    );
  }
}

import 'package:latlong/latlong.dart';

enum MapEventSource {
  mapController,
  tap,
  longPress,
  doubleTap,
  doubleTapHold,
  dragStart,
  onDrag,
  dragEnd,
  flingAnimationController,
  doubleTapZoomAnimationController,
  interactiveFlagsChanged,
}

abstract class MapEvent {
  // who / what issued the event
  final MapEventSource source;
  // current center when event is emitted
  final LatLng center;
  // current zoom when event is emitted
  final double zoom;

  MapEvent({this.source, this.center, this.zoom});
}

abstract class MapEventWithMove extends MapEvent {
  final LatLng targetCenter;
  final double targetZoom;

  MapEventWithMove({
    this.targetCenter,
    this.targetZoom,
    MapEventSource source,
    LatLng center,
    double zoom,
  }) : super(source: source, center: center, zoom: zoom);
}

class MapEventTap extends MapEvent {
  final LatLng tapPosition;

  MapEventTap({
    this.tapPosition,
    MapEventSource source,
    LatLng center,
    double zoom,
  }) : super(source: source, center: center, zoom: zoom);
}

class MapEventLongPress extends MapEvent {
  final LatLng tapPosition;

  MapEventLongPress({
    this.tapPosition,
    MapEventSource source,
    LatLng center,
    double zoom,
  }) : super(source: source, center: center, zoom: zoom);
}

class MapEventMove extends MapEventWithMove {
  final String id;

  MapEventMove({
    this.id,
    LatLng targetCenter,
    double targetZoom,
    MapEventSource source,
    LatLng center,
    double zoom,
  }) : super(
          targetCenter: targetCenter,
          targetZoom: targetZoom,
          source: source,
          center: center,
          zoom: zoom,
        );
}

class MapEventMoveStart extends MapEvent {
  MapEventMoveStart({MapEventSource source, LatLng center, double zoom})
      : super(source: source, center: center, zoom: zoom);
}

class MapEventMoveEnd extends MapEvent {
  MapEventMoveEnd({MapEventSource source, LatLng center, double zoom})
      : super(source: source, center: center, zoom: zoom);
}

class MapEventFling extends MapEventWithMove {
  MapEventFling({
    LatLng targetCenter,
    double targetZoom,
    MapEventSource source,
    LatLng center,
    double zoom,
  }) : super(
          targetCenter: targetCenter,
          targetZoom: targetZoom,
          source: source,
          center: center,
          zoom: zoom,
        );
}

/// Emits when InteractiveFlags contains fling and there wasn't enough velocity
/// to start fling animation
class MapEventFlingNotStarted extends MapEvent {
  MapEventFlingNotStarted({MapEventSource source, LatLng center, double zoom})
      : super(source: source, center: center, zoom: zoom);
}

class MapEventFlingStart extends MapEvent {
  MapEventFlingStart({MapEventSource source, LatLng center, double zoom})
      : super(source: source, center: center, zoom: zoom);
}

class MapEventFlingEnd extends MapEvent {
  MapEventFlingEnd({MapEventSource source, LatLng center, double zoom})
      : super(source: source, center: center, zoom: zoom);
}

class MapEventDoubleTapZoom extends MapEventWithMove {
  MapEventDoubleTapZoom({
    LatLng targetCenter,
    double targetZoom,
    MapEventSource source,
    LatLng center,
    double zoom,
  }) : super(
          targetCenter: targetCenter,
          targetZoom: targetZoom,
          source: source,
          center: center,
          zoom: zoom,
        );
}

class MapEventDoubleTapZoomStart extends MapEvent {
  MapEventDoubleTapZoomStart(
      {MapEventSource source, LatLng center, double zoom})
      : super(source: source, center: center, zoom: zoom);
}

class MapEventDoubleTapZoomEnd extends MapEvent {
  MapEventDoubleTapZoomEnd({MapEventSource source, LatLng center, double zoom})
      : super(source: source, center: center, zoom: zoom);
}

class MapEventRotate extends MapEvent {
  final String id;

  MapEventRotate({MapEventSource source, this.id, LatLng center, double zoom})
      : super(source: source, center: center, zoom: zoom);
}

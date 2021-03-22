import 'package:latlong2/latlong.dart';

enum MapEventSource {
  mapController,
  tap,
  longPress,
  doubleTap,
  doubleTapHold,
  dragStart,
  onDrag,
  dragEnd,
  multiFingerGestureStart,
  onMultiFinger,
  multiFingerEnd,
  flingAnimationController,
  doubleTapZoomAnimationController,
  interactiveFlagsChanged,
  fitBounds,
  initialization,
  custom
}

abstract class MapEvent {
  // who / what issued the event
  final MapEventSource source;
  // current center when event is emitted
  final LatLng center;
  // current zoom when event is emitted
  final double zoom;

  MapEvent({required this.source, required this.center, required this.zoom});
}

abstract class MapEventWithMove extends MapEvent {
  final LatLng targetCenter;
  final double targetZoom;

  MapEventWithMove({
    required this.targetCenter,
    required this.targetZoom,
    required MapEventSource source,
    required LatLng center,
    required double zoom,
  }) : super(source: source, center: center, zoom: zoom);
}

class MapEventTap extends MapEvent {
  final LatLng tapPosition;

  MapEventTap({
    required this.tapPosition,
    required MapEventSource source,
    required LatLng center,
    required double zoom,
  }) : super(source: source, center: center, zoom: zoom);
}

class MapEventLongPress extends MapEvent {
  final LatLng tapPosition;

  MapEventLongPress({
    required this.tapPosition,
    required MapEventSource source,
    required LatLng center,
    required double zoom,
  }) : super(source: source, center: center, zoom: zoom);
}

class MapEventMove extends MapEventWithMove {
  final String? id;

  MapEventMove({
    this.id,
    required LatLng targetCenter,
    required double targetZoom,
    required MapEventSource source,
    required LatLng center,
    required double zoom,
  }) : super(
          targetCenter: targetCenter,
          targetZoom: targetZoom,
          source: source,
          center: center,
          zoom: zoom,
        );
}

class MapEventMoveStart extends MapEvent {
  MapEventMoveStart(
      {required MapEventSource source,
      required LatLng center,
      required double zoom})
      : super(source: source, center: center, zoom: zoom);
}

class MapEventMoveEnd extends MapEvent {
  MapEventMoveEnd(
      {required MapEventSource source,
      required LatLng center,
      required double zoom})
      : super(source: source, center: center, zoom: zoom);
}

class MapEventFlingAnimation extends MapEventWithMove {
  MapEventFlingAnimation({
    required LatLng targetCenter,
    required double targetZoom,
    required MapEventSource source,
    required LatLng center,
    required double zoom,
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
class MapEventFlingAnimationNotStarted extends MapEvent {
  MapEventFlingAnimationNotStarted(
      {required MapEventSource source,
      required LatLng center,
      required double zoom})
      : super(source: source, center: center, zoom: zoom);
}

class MapEventFlingAnimationStart extends MapEvent {
  MapEventFlingAnimationStart(
      {required MapEventSource source,
      required LatLng center,
      required double zoom})
      : super(source: source, center: center, zoom: zoom);
}

class MapEventFlingAnimationEnd extends MapEvent {
  MapEventFlingAnimationEnd(
      {required MapEventSource source,
      required LatLng center,
      required double zoom})
      : super(source: source, center: center, zoom: zoom);
}

class MapEventDoubleTapZoom extends MapEventWithMove {
  MapEventDoubleTapZoom({
    required LatLng targetCenter,
    required double targetZoom,
    required MapEventSource source,
    required LatLng center,
    required double zoom,
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
      {required MapEventSource source,
      required LatLng center,
      required double zoom})
      : super(source: source, center: center, zoom: zoom);
}

class MapEventDoubleTapZoomEnd extends MapEvent {
  MapEventDoubleTapZoomEnd(
      {required MapEventSource source,
      required LatLng center,
      required double zoom})
      : super(source: source, center: center, zoom: zoom);
}

class MapEventRotate extends MapEvent {
  final String? id;
  final double currentRotation;
  final double targetRotation;

  MapEventRotate({
    required this.id,
    required this.currentRotation,
    required this.targetRotation,
    required MapEventSource source,
    required LatLng center,
    required double zoom,
  }) : super(source: source, center: center, zoom: zoom);
}

class MapEventRotateStart extends MapEvent {
  MapEventRotateStart(
      {required MapEventSource source,
      required LatLng center,
      required double zoom})
      : super(source: source, center: center, zoom: zoom);
}

class MapEventRotateEnd extends MapEvent {
  MapEventRotateEnd(
      {required MapEventSource source,
      required LatLng center,
      required double zoom})
      : super(source: source, center: center, zoom: zoom);
}

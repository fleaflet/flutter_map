import 'package:latlong2/latlong.dart';

/// Event sources which are used to identify different types of
/// [MapEvent] events
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

/// Base event class which is emitted by MapController instance, the event
/// is usually related to performed gesture on the map itself or it can
/// be an event related to map configuration
abstract class MapEvent {
  /// who / what issued the event
  final MapEventSource source;

  /// geographical coordinates related to current event
  final LatLng center;

  /// zoom value related to current event
  final double zoom;

  MapEvent({required this.source, required this.center, required this.zoom});
}

/// Base event class which is emitted by MapController instance and
/// includes information about camera movement
abstract class MapEventWithMove extends MapEvent {
  /// Target coordinates of point where map is being pointed to
  final LatLng targetCenter;

  /// Zoom value of point where map is being pointed to
  final double targetZoom;

  MapEventWithMove({
    required this.targetCenter,
    required this.targetZoom,
    required MapEventSource source,
    required LatLng center,
    required double zoom,
  }) : super(source: source, center: center, zoom: zoom);
}

/// Event which is fired when map is tapped
class MapEventTap extends MapEvent {
  /// Point coordinates where user has tapped
  final LatLng tapPosition;

  MapEventTap({
    required this.tapPosition,
    required MapEventSource source,
    required LatLng center,
    required double zoom,
  }) : super(source: source, center: center, zoom: zoom);
}

/// Event which is fired when map is long-pressed
class MapEventLongPress extends MapEvent {
  /// Point coordinates where user has long-pressed
  final LatLng tapPosition;

  MapEventLongPress({
    required this.tapPosition,
    required MapEventSource source,
    required LatLng center,
    required double zoom,
  }) : super(source: source, center: center, zoom: zoom);
}

/// Event which is fired when map is being dragged
class MapEventMove extends MapEventWithMove {
  /// Custom ID to identify related object(s)
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

/// Event which is fired when dragging is started
class MapEventMoveStart extends MapEvent {
  MapEventMoveStart(
      {required MapEventSource source,
      required LatLng center,
      required double zoom})
      : super(source: source, center: center, zoom: zoom);
}

/// Event which is fired when dragging is finished
class MapEventMoveEnd extends MapEvent {
  MapEventMoveEnd(
      {required MapEventSource source,
      required LatLng center,
      required double zoom})
      : super(source: source, center: center, zoom: zoom);
}

/// Event which is fired when animation started by fling gesture is in progress
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

/// Event which is fired when fling gesture is detected
class MapEventFlingAnimationStart extends MapEvent {
  MapEventFlingAnimationStart(
      {required MapEventSource source,
      required LatLng center,
      required double zoom})
      : super(source: source, center: center, zoom: zoom);
}

/// Event which is fired when animation started by fling gesture finished
class MapEventFlingAnimationEnd extends MapEvent {
  MapEventFlingAnimationEnd(
      {required MapEventSource source,
      required LatLng center,
      required double zoom})
      : super(source: source, center: center, zoom: zoom);
}

/// Event which is fired when map is double tapped
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

/// Event which is fired when animation for double tap gesture is started
class MapEventDoubleTapZoomStart extends MapEvent {
  MapEventDoubleTapZoomStart(
      {required MapEventSource source,
      required LatLng center,
      required double zoom})
      : super(source: source, center: center, zoom: zoom);
}

/// Event which is fired when animation for double tap gesture ends
class MapEventDoubleTapZoomEnd extends MapEvent {
  MapEventDoubleTapZoomEnd(
      {required MapEventSource source,
      required LatLng center,
      required double zoom})
      : super(source: source, center: center, zoom: zoom);
}

/// Event which is fired when map is being rotated
class MapEventRotate extends MapEvent {
  /// Custom ID to identify related object(s)
  final String? id;

  /// Current rotation in radians
  final double currentRotation;

  /// Target rotation in radians
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

/// Event which is fired when rotate gesture was started
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

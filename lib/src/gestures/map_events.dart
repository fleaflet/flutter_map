import 'package:flutter_map/src/misc/point.dart';
import 'package:latlong2/latlong.dart';

/// Event sources which are used to identify different types of
/// [MapEvent] events
enum MapEventSource {
  mapController,
  tap,
  secondaryTap,
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
  custom,
  scrollWheel,
  nonRotatedSizeChange,
}

/// Base event class which is emitted by MapController instance, the event
/// is usually related to performed gesture on the map itself or it can
/// be an event related to map configuration
abstract class MapEvent {
  /// Who / what issued the event.
  final MapEventSource source;

  /// Geographical coordinates related to current event.
  final LatLng center;

  /// Zoom value related to current event.
  final double zoom;

  const MapEvent({
    required this.source,
    required this.center,
    required this.zoom,
  });
}

/// Base event class which is emitted by MapController instance and
/// includes information about camera movement
abstract class MapEventWithMove extends MapEvent {
  /// Target coordinates of point where map is being pointed to
  final LatLng targetCenter;

  /// Zoom value of point where map is being pointed to
  final double targetZoom;

  const MapEventWithMove({
    required this.targetCenter,
    required this.targetZoom,
    required super.source,
    required super.center,
    required super.zoom,
  });

  /// Returns a subclass of [MapEventWithMove] if the [source] belongs to a
  /// movement event, otherwise returns null.
  static MapEventWithMove? fromSource({
    required LatLng targetCenter,
    required double targetZoom,
    required LatLng oldCenter,
    required double oldZoom,
    required bool hasGesture,
    required MapEventSource source,
    String? id,
  }) =>
      switch (source) {
        MapEventSource.flingAnimationController => MapEventFlingAnimation(
            center: oldCenter,
            zoom: oldZoom,
            targetCenter: targetCenter,
            targetZoom: targetZoom,
            source: source,
          ),
        MapEventSource.doubleTapZoomAnimationController =>
          MapEventDoubleTapZoom(
            center: oldCenter,
            zoom: oldZoom,
            targetCenter: targetCenter,
            targetZoom: targetZoom,
            source: source,
          ),
        MapEventSource.scrollWheel => MapEventScrollWheelZoom(
            center: oldCenter,
            zoom: oldZoom,
            targetCenter: targetCenter,
            targetZoom: targetZoom,
            source: source,
          ),
        MapEventSource.onDrag ||
        MapEventSource.onMultiFinger ||
        MapEventSource.mapController ||
        MapEventSource.custom =>
          MapEventMove(
            id: id,
            center: oldCenter,
            zoom: oldZoom,
            targetCenter: targetCenter,
            targetZoom: targetZoom,
            source: source,
          ),
        _ => null,
      };
}

/// Event which is fired when map is tapped
class MapEventTap extends MapEvent {
  /// Point coordinates where user has tapped
  final LatLng tapPosition;

  const MapEventTap({
    required this.tapPosition,
    required super.source,
    required super.center,
    required super.zoom,
  });
}

class MapEventSecondaryTap extends MapEvent {
  /// Point coordinates where user has tapped
  final LatLng tapPosition;

  const MapEventSecondaryTap({
    required this.tapPosition,
    required super.source,
    required super.center,
    required super.zoom,
  });
}

/// Event which is fired when map is long-pressed
class MapEventLongPress extends MapEvent {
  /// Point coordinates where user has long-pressed
  final LatLng tapPosition;

  const MapEventLongPress({
    required this.tapPosition,
    required super.source,
    required super.center,
    required super.zoom,
  });
}

/// Event which is fired when map is being moved.
class MapEventMove extends MapEventWithMove {
  /// Custom ID to identify related object(s)
  final String? id;

  const MapEventMove({
    this.id,
    required LatLng targetCenter,
    required double targetZoom,
    required super.source,
    required super.center,
    required super.zoom,
  }) : super(
          targetCenter: targetCenter,
          targetZoom: targetZoom,
        );
}

/// Event which is fired when dragging is started
class MapEventMoveStart extends MapEvent {
  const MapEventMoveStart({
    required super.source,
    required super.center,
    required super.zoom,
  });
}

/// Event which is fired when dragging is finished
class MapEventMoveEnd extends MapEvent {
  const MapEventMoveEnd({
    required super.source,
    required super.center,
    required super.zoom,
  });
}

/// Event which is fired when animation started by fling gesture is in progress
class MapEventFlingAnimation extends MapEventWithMove {
  const MapEventFlingAnimation({
    required LatLng targetCenter,
    required double targetZoom,
    required super.source,
    required super.center,
    required super.zoom,
  }) : super(
          targetCenter: targetCenter,
          targetZoom: targetZoom,
        );
}

/// Emits when InteractiveFlags contains fling and there wasn't enough velocity
/// to start fling animation
class MapEventFlingAnimationNotStarted extends MapEvent {
  const MapEventFlingAnimationNotStarted({
    required super.source,
    required super.center,
    required super.zoom,
  });
}

/// Event which is fired when fling gesture is detected
class MapEventFlingAnimationStart extends MapEvent {
  const MapEventFlingAnimationStart({
    required super.source,
    required super.center,
    required super.zoom,
  });
}

/// Event which is fired when animation started by fling gesture finished
class MapEventFlingAnimationEnd extends MapEvent {
  const MapEventFlingAnimationEnd({
    required super.source,
    required super.center,
    required super.zoom,
  });
}

/// Event which is fired when map is double tapped
class MapEventDoubleTapZoom extends MapEventWithMove {
  const MapEventDoubleTapZoom({
    required LatLng targetCenter,
    required double targetZoom,
    required super.source,
    required super.center,
    required super.zoom,
  }) : super(
          targetCenter: targetCenter,
          targetZoom: targetZoom,
        );
}

/// Event which is fired when scroll wheel is used to zoom
class MapEventScrollWheelZoom extends MapEventWithMove {
  const MapEventScrollWheelZoom({
    required LatLng targetCenter,
    required double targetZoom,
    required super.source,
    required super.center,
    required super.zoom,
  }) : super(
          targetCenter: targetCenter,
          targetZoom: targetZoom,
        );
}

/// Event which is fired when animation for double tap gesture is started
class MapEventDoubleTapZoomStart extends MapEvent {
  const MapEventDoubleTapZoomStart({
    required super.source,
    required super.center,
    required super.zoom,
  });
}

/// Event which is fired when animation for double tap gesture ends
class MapEventDoubleTapZoomEnd extends MapEvent {
  const MapEventDoubleTapZoomEnd({
    required super.source,
    required super.center,
    required super.zoom,
  });
}

/// Event which is fired when map is being rotated
class MapEventRotate extends MapEvent {
  /// Custom ID to identify related object(s)
  final String? id;

  /// Current rotation in radians
  final double currentRotation;

  /// Target rotation in radians
  final double targetRotation;

  const MapEventRotate({
    required this.id,
    required this.currentRotation,
    required this.targetRotation,
    required super.source,
    required super.center,
    required super.zoom,
  });
}

/// Event which is fired when rotate gesture was started
class MapEventRotateStart extends MapEvent {
  const MapEventRotateStart({
    required super.source,
    required super.center,
    required super.zoom,
  });
}

class MapEventRotateEnd extends MapEvent {
  const MapEventRotateEnd({
    required super.source,
    required super.center,
    required super.zoom,
  });
}

class MapEventNonRotatedSizeChange extends MapEvent {
  const MapEventNonRotatedSizeChange({
    required super.source,
    required CustomPoint<double> previousNonRotatedSize,
    required CustomPoint<double> nonRotatedSize,
    required super.center,
    required super.zoom,
  });
}

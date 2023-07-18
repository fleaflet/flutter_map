import 'package:flutter_map/src/map/camera/camera.dart';
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
  fitCamera,
  custom,
  scrollWheel,
  nonRotatedSizeChange,
  cursorRotation,
}

/// Base event class which is emitted by MapController instance, the event
/// is usually related to performed gesture on the map itself or it can
/// be an event related to map configuration
abstract class MapEvent {
  /// Who / what issued the event.
  final MapEventSource source;

  /// The map camera after the event.
  final MapCamera camera;

  const MapEvent({
    required this.source,
    required this.camera,
  });
}

/// Base event class which is emitted by MapController instance and
/// includes information about camera movement
/// which are not partial (e.g start rotate, rotate, end rotate).
abstract class MapEventWithMove extends MapEvent {
  final MapCamera oldCamera;

  const MapEventWithMove({
    required super.source,
    required this.oldCamera,
    required super.camera,
  });

  /// Returns a subclass of [MapEventWithMove] if the [source] belongs to a
  /// movement event, otherwise returns null.
  static MapEventWithMove? fromSource({
    required MapCamera oldCamera,
    required MapCamera camera,
    required bool hasGesture,
    required MapEventSource source,
    String? id,
  }) =>
      switch (source) {
        MapEventSource.flingAnimationController => MapEventFlingAnimation(
            oldCamera: oldCamera,
            camera: camera,
            source: source,
          ),
        MapEventSource.doubleTapZoomAnimationController =>
          MapEventDoubleTapZoom(
            oldCamera: oldCamera,
            camera: camera,
            source: source,
          ),
        MapEventSource.scrollWheel => MapEventScrollWheelZoom(
            oldCamera: oldCamera,
            camera: camera,
            source: source,
          ),
        MapEventSource.onDrag ||
        MapEventSource.onMultiFinger ||
        MapEventSource.mapController ||
        MapEventSource.custom =>
          MapEventMove(
            id: id,
            oldCamera: oldCamera,
            camera: camera,
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
    required super.camera,
  });
}

class MapEventSecondaryTap extends MapEvent {
  /// Point coordinates where user has tapped
  final LatLng tapPosition;

  const MapEventSecondaryTap({
    required this.tapPosition,
    required super.source,
    required super.camera,
  });
}

/// Event which is fired when map is long-pressed
class MapEventLongPress extends MapEvent {
  /// Point coordinates where user has long-pressed
  final LatLng tapPosition;

  const MapEventLongPress({
    required this.tapPosition,
    required super.source,
    required super.camera,
  });
}

/// Event which is fired when map is being moved.
class MapEventMove extends MapEventWithMove {
  /// Custom ID to identify related object(s)
  final String? id;

  const MapEventMove({
    this.id,
    required super.source,
    required super.oldCamera,
    required super.camera,
  });
}

/// Event which is fired when dragging is started
class MapEventMoveStart extends MapEvent {
  const MapEventMoveStart({
    required super.source,
    required super.camera,
  });
}

/// Event which is fired when dragging is finished
class MapEventMoveEnd extends MapEvent {
  const MapEventMoveEnd({
    required super.source,
    required super.camera,
  });
}

/// Event which is fired when animation started by fling gesture is in progress
class MapEventFlingAnimation extends MapEventWithMove {
  const MapEventFlingAnimation({
    required super.source,
    required super.oldCamera,
    required super.camera,
  });
}

/// Emits when InteractiveFlags contains fling and there wasn't enough velocity
/// to start fling animation
class MapEventFlingAnimationNotStarted extends MapEvent {
  const MapEventFlingAnimationNotStarted({
    required super.source,
    required super.camera,
  });
}

/// Event which is fired when fling gesture is detected
class MapEventFlingAnimationStart extends MapEvent {
  const MapEventFlingAnimationStart({
    required super.source,
    required super.camera,
  });
}

/// Event which is fired when animation started by fling gesture finished
class MapEventFlingAnimationEnd extends MapEvent {
  const MapEventFlingAnimationEnd({
    required super.source,
    required super.camera,
  });
}

/// Event which is fired when map is double tapped
class MapEventDoubleTapZoom extends MapEventWithMove {
  const MapEventDoubleTapZoom({
    required super.source,
    required super.oldCamera,
    required super.camera,
  });
}

/// Event which is fired when scroll wheel is used to zoom
class MapEventScrollWheelZoom extends MapEventWithMove {
  const MapEventScrollWheelZoom({
    required super.source,
    required super.oldCamera,
    required super.camera,
  });
}

/// Event which is fired when animation for double tap gesture is started
class MapEventDoubleTapZoomStart extends MapEvent {
  const MapEventDoubleTapZoomStart({
    required super.source,
    required super.camera,
  });
}

/// Event which is fired when animation for double tap gesture ends
class MapEventDoubleTapZoomEnd extends MapEvent {
  const MapEventDoubleTapZoomEnd({
    required super.source,
    required super.camera,
  });
}

/// Event which is fired when map is being rotated
class MapEventRotate extends MapEventWithMove {
  /// Custom ID to identify related object(s)
  final String? id;

  const MapEventRotate({
    required this.id,
    required super.source,
    required super.oldCamera,
    required super.camera,
  });
}

/// Event which is fired when rotate gesture was started
class MapEventRotateStart extends MapEvent {
  const MapEventRotateStart({
    required super.source,
    required super.camera,
  });
}

class MapEventRotateEnd extends MapEvent {
  const MapEventRotateEnd({
    required super.source,
    required super.camera,
  });
}

class MapEventNonRotatedSizeChange extends MapEventWithMove {
  const MapEventNonRotatedSizeChange({
    required super.source,
    required super.oldCamera,
    required super.camera,
  });
}

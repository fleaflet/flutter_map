import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Event sources which are used to identify different types of
/// [MapEvent] events
enum MapEventSource {
  /// The [MapEvent] is caused programmatically by the [MapController].
  mapController,

  /// The [MapEvent] is caused by a tap gesture.
  tap,

  /// The [MapEvent] is caused by a secondary tap gesture.
  secondaryTap,

  /// The [MapEvent] is caused by a long press gesture.
  longPress,

  /// The [MapEvent] is caused by a double tap gesture.
  doubleTap,

  /// The [MapEvent] is caused by a double tap and hold gesture.
  doubleTapHold,

  /// The [MapEvent] is caused by the start of a drag gesture.
  dragStart,

  /// The [MapEvent] is caused by a drag update gesture.
  onDrag,

  /// The [MapEvent] is caused by the end of a drag gesture.
  dragEnd,

  /// The [MapEvent] is caused by the start of a two finger gesture.
  multiFingerGestureStart,

  /// The [MapEvent] is caused by a two finger gesture update.
  onMultiFinger,

  /// The [MapEvent] is caused by a the end of a two finger gesture.
  multiFingerEnd,

  /// The [MapEvent] is caused by the [AnimationController] while performing
  /// the fling gesture.
  flingAnimationController,

  /// The [MapEvent] is caused by the [AnimationController] while performing
  /// the double tap zoom in animation.
  doubleTapZoomAnimationController,

  /// The [MapEvent] is caused by a change of the interactive flags.
  interactiveFlagsChanged,

  /// The [MapEvent] is caused by calling fitCamera.
  fitCamera,

  /// The [MapEvent] is caused by a custom source.
  custom,

  /// The [MapEvent] is caused by a scroll wheel zoom gesture.
  scrollWheel,

  /// The [MapEvent] is caused by a size change of the [FlutterMap] constraints.
  nonRotatedSizeChange,

  /// The [MapEvent] is caused by a CTRL + drag rotation gesture.
  cursorKeyboardRotation,
}

/// Base event class which is emitted by MapController instance, the event
/// is usually related to performed gesture on the map itself or it can
/// be an event related to map configuration
@immutable
abstract class MapEvent {
  /// Who / what issued the event.
  final MapEventSource source;

  /// The map camera after the event.
  final MapCamera camera;

  /// Base constructor for [MapEvent] that gets overridden by its extended
  /// classes.
  const MapEvent({
    required this.source,
    required this.camera,
  });
}

/// Base event class which is emitted by MapController instance and
/// includes information about camera movement
/// which are not partial (e.g start rotate, rotate, end rotate).
@immutable
abstract class MapEventWithMove extends MapEvent {
  /// The [MapCamera] before the map move event occurred.
  final MapCamera oldCamera;

  /// Create a new map event that represents a movement event
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
@immutable
class MapEventTap extends MapEvent {
  /// Point coordinates where user has tapped
  final LatLng tapPosition;

  /// Create a new map event that represents a tap on the map
  const MapEventTap({
    required this.tapPosition,
    required super.source,
    required super.camera,
  });
}

/// Event which is fired when map is secondary tapped
@immutable
class MapEventSecondaryTap extends MapEvent {
  /// Point coordinates where user has tapped
  final LatLng tapPosition;

  /// Create a new map event that represents a secondary tap on the map
  const MapEventSecondaryTap({
    required this.tapPosition,
    required super.source,
    required super.camera,
  });
}

/// Event which is fired when map is long-pressed
@immutable
class MapEventLongPress extends MapEvent {
  /// Point coordinates where user has long-pressed
  final LatLng tapPosition;

  /// Create a new map event that represents a long press on the map
  const MapEventLongPress({
    required this.tapPosition,
    required super.source,
    required super.camera,
  });
}

/// Event which is fired when map is being moved.
@immutable
class MapEventMove extends MapEventWithMove {
  /// Custom ID to identify related object(s)
  final String? id;

  /// Create a new map event that represents a map movement
  const MapEventMove({
    this.id,
    required super.source,
    required super.oldCamera,
    required super.camera,
  });
}

/// Event which is fired when dragging is started
@immutable
class MapEventMoveStart extends MapEvent {
  /// Create a new map event that represents the start of a drag event
  const MapEventMoveStart({
    required super.source,
    required super.camera,
  });
}

/// Event which is fired when dragging is finished
@immutable
class MapEventMoveEnd extends MapEvent {
  /// Create a new map event that represents the end of a drag event
  const MapEventMoveEnd({
    required super.source,
    required super.camera,
  });
}

/// Event which is fired when animation started by fling gesture is in progress
@immutable
class MapEventFlingAnimation extends MapEventWithMove {
  /// Create a new map event that represents an ongoing fling animation
  const MapEventFlingAnimation({
    required super.source,
    required super.oldCamera,
    required super.camera,
  });
}

/// Emits when InteractiveFlags contains fling and there wasn't enough velocity
/// to start fling animation
@immutable
class MapEventFlingAnimationNotStarted extends MapEvent {
  /// Create a new map event that for when the performed fling gesture had
  /// not enough velocity to cause a fling animation.
  const MapEventFlingAnimationNotStarted({
    required super.source,
    required super.camera,
  });
}

/// Event which is fired when fling gesture is detected
@immutable
class MapEventFlingAnimationStart extends MapEvent {
  /// Create a new map event that represents the start of a fling animation
  const MapEventFlingAnimationStart({
    required super.source,
    required super.camera,
  });
}

/// Event which is fired when animation started by fling gesture finished
@immutable
class MapEventFlingAnimationEnd extends MapEvent {
  /// Create a new map event that represents the end of a fling animation
  const MapEventFlingAnimationEnd({
    required super.source,
    required super.camera,
  });
}

/// Event which is fired when map is double tapped
@immutable
class MapEventDoubleTapZoom extends MapEventWithMove {
  /// Create a new map event that represents an ongoing double tap zoom gesture.
  const MapEventDoubleTapZoom({
    required super.source,
    required super.oldCamera,
    required super.camera,
  });
}

/// Event which is fired when scroll wheel is used to zoom
@immutable
class MapEventScrollWheelZoom extends MapEventWithMove {
  /// Create a new map event that represents an ongoing scroll wheel
  /// zoom gesture.
  const MapEventScrollWheelZoom({
    required super.source,
    required super.oldCamera,
    required super.camera,
  });
}

/// Event which is fired when animation for double tap gesture is started
@immutable
class MapEventDoubleTapZoomStart extends MapEvent {
  /// Create a new map event that represents the start of a double tap
  /// zoom gesture.
  const MapEventDoubleTapZoomStart({
    required super.source,
    required super.camera,
  });
}

/// Event which is fired when animation for double tap gesture ends
@immutable
class MapEventDoubleTapZoomEnd extends MapEvent {
  /// Create a new map event that represents the end of a double tap
  /// zoom gesture.
  const MapEventDoubleTapZoomEnd({
    required super.source,
    required super.camera,
  });
}

/// Event which is fired when map is being rotated
@immutable
class MapEventRotate extends MapEventWithMove {
  /// Custom ID to identify related object(s)
  final String? id;

  /// Create a new map event that represents an ongoing map rotation.
  const MapEventRotate({
    required this.id,
    required super.source,
    required super.oldCamera,
    required super.camera,
  });
}

/// Event which is fired when rotate gesture was started
@immutable
class MapEventRotateStart extends MapEvent {
  /// Create a new map event that represents the start of a map rotation.
  const MapEventRotateStart({
    required super.source,
    required super.camera,
  });
}

/// Event which is fired when rotate gesture has ended
@immutable
class MapEventRotateEnd extends MapEvent {
  /// Create a new map event that represents the end of a map rotation.
  const MapEventRotateEnd({
    required super.source,
    required super.camera,
  });
}

/// Event that fires when the map widget changes size, e.g. when the app window
/// gets changed in size.
@immutable
class MapEventNonRotatedSizeChange extends MapEventWithMove {
  /// Create a new map event that represents that the widget size has changed.
  const MapEventNonRotatedSizeChange({
    required super.source,
    required super.oldCamera,
    required super.camera,
  });
}

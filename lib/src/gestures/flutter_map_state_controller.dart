import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map/src/gestures/flutter_map_interactive_viewer.dart';
import 'package:flutter_map/src/map/flutter_map_state_controller_interface.dart';
import 'package:flutter_map/src/map/map_controller_impl.dart';
import 'package:latlong2/latlong.dart';

// This controller is for internal use. All updates to the state should be done
// by calling methods of this class to ensure consistency.
class FlutterMapStateController extends ValueNotifier<FlutterMapState>
    implements FlutterMapStateControllerInterface {
  late final FlutterMapInteractiveViewerState _interactiveViewerState;
  late MapControllerImpl _mapControllerImpl;

  FlutterMapStateController(MapOptions options)
      : super(FlutterMapState.initialState(options));

  // Link the viewer state with the controller. This should be done once when
  // the FlutterMapInteractiveViewerState is initialized.
  set interactiveViewerState(
    FlutterMapInteractiveViewerState interactiveViewerState,
  ) =>
      _interactiveViewerState = interactiveViewerState;

  void linkMapController(MapControllerImpl mapControllerImpl) {
    _mapControllerImpl = mapControllerImpl;
    _mapControllerImpl.stateController = this;
  }

  /// This setter should only be called in this class or within tests. Changes
  /// to the FlutterMapState should be done via methods in this class.
  @visibleForTesting
  @override
  set value(FlutterMapState value) => super.value = value;

  // Note: All named parameters are required to prevent inconsistent default
  // values since this method can be called by MapController which declares
  // defaults.
  @override
  bool move(
    LatLng newCenter,
    double newZoom, {
    required Offset offset,
    required bool hasGesture,
    required MapEventSource source,
    required String? id,
  }) {
    newZoom = value.fitZoomToBounds(newZoom);

    // Algorithm thanks to https://github.com/tlserver/flutter_map_location_marker
    if (offset != Offset.zero) {
      final newPoint = value.project(newCenter, newZoom);
      newCenter = value.unproject(
        value.rotatePoint(
          newPoint,
          newPoint - CustomPoint(offset.dx, offset.dy),
        ),
        newZoom,
      );
    }

    if (value.isOutOfBounds(newCenter)) {
      if (!value.options.slideOnBoundaries) return false;
      newCenter = value.containPoint(newCenter, value.center);
    }

    if (value.options.maxBounds != null) {
      final adjustedCenter = value.adjustCenterIfOutsideMaxBounds(
        newCenter,
        newZoom,
        value.options.maxBounds!,
      );

      if (adjustedCenter == null) return false;
      newCenter = adjustedCenter;
    }

    if (newCenter == value.center && newZoom == value.zoom) {
      return false;
    }

    final oldMapState = value;
    value = value.copyWith(zoom: newZoom, center: newCenter);

    final movementEvent = MapEventWithMove.fromSource(
      oldMapState: oldMapState,
      mapState: value,
      hasGesture: hasGesture,
      source: source,
      id: id,
    );
    if (movementEvent != null) _emitMapEvent(movementEvent);

    value.options.onPositionChanged?.call(
      MapPosition(
        center: newCenter,
        bounds: value.bounds,
        zoom: newZoom,
        hasGesture: hasGesture,
      ),
      hasGesture,
    );

    return true;
  }

  // Note: All named parameters are required to prevent inconsistent default
  // values since this method can be called by MapController which declares
  // defaults.
  @override
  bool rotate(
    double newRotation, {
    required bool hasGesture,
    required MapEventSource source,
    required String? id,
  }) {
    if (newRotation != value.rotation) {
      final oldMapState = value;
      //Apply state then emit events and callbacks
      value = value.withRotation(newRotation);

      _emitMapEvent(
        MapEventRotate(
          id: id,
          source: source,
          oldMapState: oldMapState,
          mapState: value,
        ),
      );
      return true;
    }

    return false;
  }

  // Note: All named parameters are required to prevent inconsistent default
  // values since this method can be called by MapController which declares
  // defaults.
  @override
  MoveAndRotateResult rotateAroundPoint(
    double degree, {
    required CustomPoint<double>? point,
    required Offset? offset,
    required bool hasGesture,
    required MapEventSource source,
    required String? id,
  }) {
    if (point != null && offset != null) {
      throw ArgumentError('Only one of `point` or `offset` may be non-null');
    }
    if (point == null && offset == null) {
      throw ArgumentError('One of `point` or `offset` must be non-null');
    }

    if (degree == value.rotation) {
      return MoveAndRotateResult(false, false);
    }

    if (offset == Offset.zero) {
      return MoveAndRotateResult(
        true,
        rotate(
          degree,
          hasGesture: hasGesture,
          source: source,
          id: id,
        ),
      );
    }

    final rotationDiff = degree - value.rotation;
    final rotationCenter = value.project(value.center) +
        (point != null
                ? (point - (value.nonRotatedSize / 2.0))
                : CustomPoint(offset!.dx, offset.dy))
            .rotate(value.rotationRad);

    return MoveAndRotateResult(
      move(
        value.unproject(
          rotationCenter +
              (value.project(value.center) - rotationCenter)
                  .rotate(degToRadian(rotationDiff)),
        ),
        value.zoom,
        offset: Offset.zero,
        hasGesture: hasGesture,
        source: source,
        id: id,
      ),
      rotate(
        value.rotation + rotationDiff,
        hasGesture: hasGesture,
        source: source,
        id: id,
      ),
    );
  }

  // Note: All named parameters are required to prevent inconsistent default
  // values since this method can be called by MapController which declares
  // defaults.
  @override
  MoveAndRotateResult moveAndRotate(
    LatLng newCenter,
    double newZoom,
    double newRotation, {
    required Offset offset,
    required bool hasGesture,
    required MapEventSource source,
    required String? id,
  }) =>
      MoveAndRotateResult(
        move(
          newCenter,
          newZoom,
          offset: offset,
          hasGesture: hasGesture,
          source: source,
          id: id,
        ),
        rotate(newRotation, id: id, source: source, hasGesture: hasGesture),
      );

  // Note: All named parameters are required to prevent inconsistent default
  // values since this method can be called by MapController which declares
  // defaults.
  @override
  bool fitBounds(
    LatLngBounds bounds,
    FitBoundsOptions options, {
    required Offset offset,
  }) {
    final target = value.getBoundsCenterZoom(bounds, options);
    return move(
      target.center,
      target.zoom,
      offset: offset,
      hasGesture: false,
      source: MapEventSource.fitBounds,
      id: null,
    );
  }

  bool setNonRotatedSizeWithoutEmittingEvent(
    CustomPoint<double> nonRotatedSize,
  ) {
    if (nonRotatedSize != FlutterMapState.kImpossibleSize &&
        nonRotatedSize != value.nonRotatedSize) {
      value = value.withNonRotatedSize(nonRotatedSize);
      return true;
    }

    return false;
  }

  void setOptions(MapOptions options) {
    if (value.options != options) {
      value = value.withOptions(options);
    }
  }

  // To be called when a gesture that causes movement starts.
  void moveStarted(MapEventSource source) {
    _emitMapEvent(
      MapEventMoveStart(
        mapState: value,
        source: source,
      ),
    );
  }

  // To be called when an ongoing drag movement updates.
  void dragUpdated(MapEventSource source, Offset offset) {
    final oldCenterPt = value.project(value.center);

    final newCenterPt = oldCenterPt + offset.toCustomPoint();
    final newCenter = value.unproject(newCenterPt);

    move(
      newCenter,
      value.zoom,
      offset: Offset.zero,
      hasGesture: true,
      source: source,
      id: null,
    );
  }

  // To be called when a drag gesture ends.
  void moveEnded(MapEventSource source) {
    _emitMapEvent(
      MapEventMoveEnd(
        mapState: value,
        source: source,
      ),
    );
  }

  // To be called when a rotation gesture starts.
  void rotateStarted(MapEventSource source) {
    _emitMapEvent(
      MapEventRotateStart(
        mapState: value,
        source: source,
      ),
    );
  }

  // To be called when a rotation gesture ends.
  void rotateEnded(MapEventSource source) {
    _emitMapEvent(
      MapEventRotateEnd(
        mapState: value,
        source: source,
      ),
    );
  }

  // To be called when a fling gesture starts.
  void flingStarted(MapEventSource source) {
    _emitMapEvent(
      MapEventFlingAnimationStart(
        mapState: value,
        source: MapEventSource.flingAnimationController,
      ),
    );
  }

  // To be called when a fling gesture ends.
  void flingEnded(MapEventSource source) {
    _emitMapEvent(
      MapEventFlingAnimationEnd(
        mapState: value,
        source: source,
      ),
    );
  }

  // To be called when a fling gesture does not start.
  void flingNotStarted(MapEventSource source) {
    _emitMapEvent(
      MapEventFlingAnimationNotStarted(
        mapState: value,
        source: source,
      ),
    );
  }

  // To be called when a double tap zoom starts.
  void doubleTapZoomStarted(MapEventSource source) {
    _emitMapEvent(
      MapEventDoubleTapZoomStart(
        mapState: value,
        source: source,
      ),
    );
  }

  // To be called when a double tap zoom ends.
  void doubleTapZoomEnded(MapEventSource source) {
    _emitMapEvent(
      MapEventDoubleTapZoomEnd(
        mapState: value,
        source: source,
      ),
    );
  }

  void tapped(
    MapEventSource source,
    TapPosition tapPosition,
    LatLng position,
  ) {
    value.options.onTap?.call(tapPosition, position);
    _emitMapEvent(
      MapEventTap(
        tapPosition: position,
        mapState: value,
        source: source,
      ),
    );
  }

  void secondaryTapped(
    MapEventSource source,
    TapPosition tapPosition,
    LatLng position,
  ) {
    value.options.onSecondaryTap?.call(tapPosition, position);
    _emitMapEvent(
      MapEventSecondaryTap(
        tapPosition: position,
        mapState: value,
        source: source,
      ),
    );
  }

  void longPressed(
    MapEventSource source,
    TapPosition tapPosition,
    LatLng position,
  ) {
    value.options.onLongPress?.call(tapPosition, position);
    _emitMapEvent(
      MapEventLongPress(
        tapPosition: position,
        mapState: value,
        source: MapEventSource.longPress,
      ),
    );
  }

  // To be called when the map's size constraints change.
  void nonRotatedSizeChange(
    MapEventSource source,
    FlutterMapState oldMapState,
    FlutterMapState newMapState,
  ) {
    _emitMapEvent(
      MapEventNonRotatedSizeChange(
        source: MapEventSource.nonRotatedSizeChange,
        oldMapState: oldMapState,
        mapState: newMapState,
      ),
    );
  }

  void _emitMapEvent(MapEvent event) {
    if (event.source == MapEventSource.mapController && event is MapEventMove) {
      _interactiveViewerState.interruptAnimatedMovement(event);
    }

    value.options.onMapEvent?.call(event);

    _mapControllerImpl.mapEventSink.add(event);
  }
}

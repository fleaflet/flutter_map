import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map/src/gestures/flutter_map_interactive_viewer.dart';
import 'package:flutter_map/src/map/flutter_map_internal_state.dart';
import 'package:flutter_map/src/map/map_controller_impl.dart';
import 'package:latlong2/latlong.dart';

// This controller is for internal use. All updates to the state should be done
// by calling methods of this class to ensure consistency.
class FlutterMapInternalController
    extends ValueNotifier<FlutterMapInternalState> {
  late final FlutterMapInteractiveViewerState _interactiveViewerState;
  late MapControllerImpl _mapControllerImpl;

  FlutterMapInternalController(MapOptions options)
      : super(
          FlutterMapInternalState(
            options: options,
            mapState: FlutterMapState.initialState(options),
          ),
        );

  // Link the viewer state with the controller. This should be done once when
  // the FlutterMapInteractiveViewerState is initialized.
  set interactiveViewerState(
    FlutterMapInteractiveViewerState interactiveViewerState,
  ) =>
      _interactiveViewerState = interactiveViewerState;

  MapOptions get options => value.options;
  FlutterMapState get mapState => value.mapState;

  void linkMapController(MapControllerImpl mapControllerImpl) {
    _mapControllerImpl = mapControllerImpl;
    _mapControllerImpl.stateController = this;
  }

  /// This setter should only be called in this class or within tests. Changes
  /// to the FlutterMapState should be done via methods in this class.
  @visibleForTesting
  @override
  set value(FlutterMapInternalState value) => super.value = value;

  // Note: All named parameters are required to prevent inconsistent default
  // values since this method can be called by MapController which declares
  // defaults.
  bool move(
    LatLng newCenter,
    double newZoom, {
    required Offset offset,
    required bool hasGesture,
    required MapEventSource source,
    required String? id,
  }) {
    newZoom = mapState.fitZoomToBounds(newZoom);

    // Algorithm thanks to https://github.com/tlserver/flutter_map_location_marker
    if (offset != Offset.zero) {
      final newPoint = mapState.project(newCenter, newZoom);
      newCenter = mapState.unproject(
        mapState.rotatePoint(
          newPoint,
          newPoint - CustomPoint(offset.dx, offset.dy),
        ),
        newZoom,
      );
    }

    // TODO: Why do we have two separate methods of adjusting the bounds?
    if (mapState.isOutOfBounds(newCenter)) {
      if (!options.slideOnBoundaries) return false;
      newCenter = mapState.clampWithFallback(newCenter, mapState.center);
    }

    if (options.maxBounds != null) {
      final adjustedCenter = mapState.adjustCenterIfOutsideMaxBounds(
        newCenter,
        newZoom,
        options.maxBounds!,
      );

      if (adjustedCenter == null) return false;
      newCenter = adjustedCenter;
    }

    if (newCenter == mapState.center && newZoom == mapState.zoom) {
      return false;
    }

    final oldMapState = mapState;
    value = value.withMapState(
      mapState.withPosition(zoom: newZoom, center: newCenter),
    );

    final movementEvent = MapEventWithMove.fromSource(
      oldMapState: oldMapState,
      mapState: mapState,
      hasGesture: hasGesture,
      source: source,
      id: id,
    );
    if (movementEvent != null) _emitMapEvent(movementEvent);

    options.onPositionChanged?.call(
      MapPosition(
        center: newCenter,
        bounds: mapState.visibleBounds,
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
  bool rotate(
    double newRotation, {
    required bool hasGesture,
    required MapEventSource source,
    required String? id,
  }) {
    if (newRotation != mapState.rotation) {
      final oldMapState = mapState;
      // Apply state then emit events and callbacks
      value = value.withMapState(mapState.withRotation(newRotation));

      _emitMapEvent(
        MapEventRotate(
          id: id,
          source: source,
          oldMapState: oldMapState,
          mapState: mapState,
        ),
      );
      return true;
    }

    return false;
  }

  // Note: All named parameters are required to prevent inconsistent default
  // values since this method can be called by MapController which declares
  // defaults.
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

    if (degree == mapState.rotation) {
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

    final rotationDiff = degree - mapState.rotation;
    final rotationCenter = mapState.project(mapState.center) +
        (point != null
                ? (point - (mapState.nonRotatedSize / 2.0))
                : CustomPoint(offset!.dx, offset.dy))
            .rotate(mapState.rotationRad);

    return MoveAndRotateResult(
      move(
        mapState.unproject(
          rotationCenter +
              (mapState.project(mapState.center) - rotationCenter)
                  .rotate(degToRadian(rotationDiff)),
        ),
        mapState.zoom,
        offset: Offset.zero,
        hasGesture: hasGesture,
        source: source,
        id: id,
      ),
      rotate(
        mapState.rotation + rotationDiff,
        hasGesture: hasGesture,
        source: source,
        id: id,
      ),
    );
  }

  // Note: All named parameters are required to prevent inconsistent default
  // values since this method can be called by MapController which declares
  // defaults.
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
  bool fitBounds(
    LatLngBounds bounds,
    FitBoundsOptions options, {
    required Offset offset,
  }) {
    final target = mapState.centerZoomFitBounds(bounds, options: options);
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
        nonRotatedSize != mapState.nonRotatedSize) {
      value = value.withMapState(mapState.withNonRotatedSize(nonRotatedSize));
      return true;
    }

    return false;
  }

  void setOptions(MapOptions options) {
    if (options != this.options) {
      value = value.withMapState(mapState.withOptions(options));
    }
  }

  // To be called when a gesture that causes movement starts.
  void moveStarted(MapEventSource source) {
    _emitMapEvent(
      MapEventMoveStart(
        mapState: mapState,
        source: source,
      ),
    );
  }

  // To be called when an ongoing drag movement updates.
  void dragUpdated(MapEventSource source, Offset offset) {
    final oldCenterPt = mapState.project(mapState.center);

    final newCenterPt = oldCenterPt + offset.toCustomPoint();
    final newCenter = mapState.unproject(newCenterPt);

    move(
      newCenter,
      mapState.zoom,
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
        mapState: mapState,
        source: source,
      ),
    );
  }

  // To be called when a rotation gesture starts.
  void rotateStarted(MapEventSource source) {
    _emitMapEvent(
      MapEventRotateStart(
        mapState: mapState,
        source: source,
      ),
    );
  }

  // To be called when a rotation gesture ends.
  void rotateEnded(MapEventSource source) {
    _emitMapEvent(
      MapEventRotateEnd(
        mapState: mapState,
        source: source,
      ),
    );
  }

  // To be called when a fling gesture starts.
  void flingStarted(MapEventSource source) {
    _emitMapEvent(
      MapEventFlingAnimationStart(
        mapState: mapState,
        source: MapEventSource.flingAnimationController,
      ),
    );
  }

  // To be called when a fling gesture ends.
  void flingEnded(MapEventSource source) {
    _emitMapEvent(
      MapEventFlingAnimationEnd(
        mapState: mapState,
        source: source,
      ),
    );
  }

  // To be called when a fling gesture does not start.
  void flingNotStarted(MapEventSource source) {
    _emitMapEvent(
      MapEventFlingAnimationNotStarted(
        mapState: mapState,
        source: source,
      ),
    );
  }

  // To be called when a double tap zoom starts.
  void doubleTapZoomStarted(MapEventSource source) {
    _emitMapEvent(
      MapEventDoubleTapZoomStart(
        mapState: mapState,
        source: source,
      ),
    );
  }

  // To be called when a double tap zoom ends.
  void doubleTapZoomEnded(MapEventSource source) {
    _emitMapEvent(
      MapEventDoubleTapZoomEnd(
        mapState: mapState,
        source: source,
      ),
    );
  }

  void tapped(
    MapEventSource source,
    TapPosition tapPosition,
    LatLng position,
  ) {
    options.onTap?.call(tapPosition, position);
    _emitMapEvent(
      MapEventTap(
        tapPosition: position,
        mapState: mapState,
        source: source,
      ),
    );
  }

  void secondaryTapped(
    MapEventSource source,
    TapPosition tapPosition,
    LatLng position,
  ) {
    options.onSecondaryTap?.call(tapPosition, position);
    _emitMapEvent(
      MapEventSecondaryTap(
        tapPosition: position,
        mapState: mapState,
        source: source,
      ),
    );
  }

  void longPressed(
    MapEventSource source,
    TapPosition tapPosition,
    LatLng position,
  ) {
    options.onLongPress?.call(tapPosition, position);
    _emitMapEvent(
      MapEventLongPress(
        tapPosition: position,
        mapState: mapState,
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

    options.onMapEvent?.call(event);

    _mapControllerImpl.mapEventSink.add(event);
  }
}

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
            mapCamera: MapCamera.initialCamera(options),
          ),
        );

  // Link the viewer state with the controller. This should be done once when
  // the FlutterMapInteractiveViewerState is initialized.
  set interactiveViewerState(
    FlutterMapInteractiveViewerState interactiveViewerState,
  ) =>
      _interactiveViewerState = interactiveViewerState;

  MapOptions get options => value.options;
  MapCamera get mapCamera => value.mapCamera;

  void linkMapController(MapControllerImpl mapControllerImpl) {
    _mapControllerImpl = mapControllerImpl;
    _mapControllerImpl.internalController = this;
  }

  /// This setter should only be called in this class or within tests. Changes
  /// to the [FlutterMapInternalState] should be done via methods in this class.
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
    // Algorithm thanks to https://github.com/tlserver/flutter_map_location_marker
    if (offset != Offset.zero) {
      final newPoint = mapCamera.project(newCenter, newZoom);
      newCenter = mapCamera.unproject(
        mapCamera.rotatePoint(
          newPoint,
          newPoint - CustomPoint(offset.dx, offset.dy),
        ),
        newZoom,
      );
    }

    MapCamera? newMapCamera = mapCamera.withPosition(
      center: newCenter,
      zoom: mapCamera.clampZoom(newZoom),
    );

    newMapCamera = options.cameraConstraint.constrain(newMapCamera);
    if (newMapCamera == null ||
        (newMapCamera.center == mapCamera.center &&
            newMapCamera.zoom == mapCamera.zoom)) {
      return false;
    }

    final oldMapCamera = mapCamera;
    value = value.withMapCamera(newMapCamera);

    final movementEvent = MapEventWithMove.fromSource(
      oldMapCamera: oldMapCamera,
      mapCamera: mapCamera,
      hasGesture: hasGesture,
      source: source,
      id: id,
    );
    if (movementEvent != null) _emitMapEvent(movementEvent);

    options.onPositionChanged?.call(
      MapPosition(
        center: newCenter,
        bounds: mapCamera.visibleBounds,
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
    if (newRotation != mapCamera.rotation) {
      final newMapCamera = options.cameraConstraint.constrain(
        mapCamera.withRotation(newRotation),
      );
      if (newMapCamera == null) return false;

      final oldMapCamera = mapCamera;

      // Update camera then emit events and callbacks
      value = value.withMapCamera(newMapCamera);

      _emitMapEvent(
        MapEventRotate(
          id: id,
          source: source,
          oldMapCamera: oldMapCamera,
          mapCamera: mapCamera,
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

    if (degree == mapCamera.rotation) {
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

    final rotationDiff = degree - mapCamera.rotation;
    final rotationCenter = mapCamera.project(mapCamera.center) +
        (point != null
                ? (point - (mapCamera.nonRotatedSize / 2.0))
                : CustomPoint(offset!.dx, offset.dy))
            .rotate(mapCamera.rotationRad);

    return MoveAndRotateResult(
      move(
        mapCamera.unproject(
          rotationCenter +
              (mapCamera.project(mapCamera.center) - rotationCenter)
                  .rotate(degToRadian(rotationDiff)),
        ),
        mapCamera.zoom,
        offset: Offset.zero,
        hasGesture: hasGesture,
        source: source,
        id: id,
      ),
      rotate(
        mapCamera.rotation + rotationDiff,
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
  bool fitCamera(
    CameraFit cameraFit, {
    required Offset offset,
  }) {
    final fitted = cameraFit.fit(mapCamera);

    return move(
      fitted.center,
      fitted.zoom,
      offset: offset,
      hasGesture: false,
      source: MapEventSource.fitCamera,
      id: null,
    );
  }

  bool setNonRotatedSizeWithoutEmittingEvent(
    CustomPoint<double> nonRotatedSize,
  ) {
    if (nonRotatedSize != MapCamera.kImpossibleSize &&
        nonRotatedSize != mapCamera.nonRotatedSize) {
      value = value.withMapCamera(mapCamera.withNonRotatedSize(nonRotatedSize));
      return true;
    }

    return false;
  }

  void setOptions(MapOptions newOptions) {
    assert(
      newOptions != value.options,
      'Should not update options unless they change',
    );

    final newMapCamera = mapCamera.withOptions(newOptions);

    assert(
      newOptions.cameraConstraint.constrain(newMapCamera) == newMapCamera,
      'MapCamera is no longer within the cameraConstraint after an option change.',
    );

    if (options.interactionOptions != newOptions.interactionOptions) {
      _interactiveViewerState.updateGestures(
        options.interactionOptions,
        newOptions.interactionOptions,
      );
    }

    value = FlutterMapInternalState(
      options: newOptions,
      mapCamera: newMapCamera,
    );
  }

  // To be called when a gesture that causes movement starts.
  void moveStarted(MapEventSource source) {
    _emitMapEvent(
      MapEventMoveStart(
        mapCamera: mapCamera,
        source: source,
      ),
    );
  }

  // To be called when an ongoing drag movement updates.
  void dragUpdated(MapEventSource source, Offset offset) {
    final oldCenterPt = mapCamera.project(mapCamera.center);

    final newCenterPt = oldCenterPt + offset.toCustomPoint();
    final newCenter = mapCamera.unproject(newCenterPt);

    move(
      newCenter,
      mapCamera.zoom,
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
        mapCamera: mapCamera,
        source: source,
      ),
    );
  }

  // To be called when a rotation gesture starts.
  void rotateStarted(MapEventSource source) {
    _emitMapEvent(
      MapEventRotateStart(
        mapCamera: mapCamera,
        source: source,
      ),
    );
  }

  // To be called when a rotation gesture ends.
  void rotateEnded(MapEventSource source) {
    _emitMapEvent(
      MapEventRotateEnd(
        mapCamera: mapCamera,
        source: source,
      ),
    );
  }

  // To be called when a fling gesture starts.
  void flingStarted(MapEventSource source) {
    _emitMapEvent(
      MapEventFlingAnimationStart(
        mapCamera: mapCamera,
        source: MapEventSource.flingAnimationController,
      ),
    );
  }

  // To be called when a fling gesture ends.
  void flingEnded(MapEventSource source) {
    _emitMapEvent(
      MapEventFlingAnimationEnd(
        mapCamera: mapCamera,
        source: source,
      ),
    );
  }

  // To be called when a fling gesture does not start.
  void flingNotStarted(MapEventSource source) {
    _emitMapEvent(
      MapEventFlingAnimationNotStarted(
        mapCamera: mapCamera,
        source: source,
      ),
    );
  }

  // To be called when a double tap zoom starts.
  void doubleTapZoomStarted(MapEventSource source) {
    _emitMapEvent(
      MapEventDoubleTapZoomStart(
        mapCamera: mapCamera,
        source: source,
      ),
    );
  }

  // To be called when a double tap zoom ends.
  void doubleTapZoomEnded(MapEventSource source) {
    _emitMapEvent(
      MapEventDoubleTapZoomEnd(
        mapCamera: mapCamera,
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
        mapCamera: mapCamera,
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
        mapCamera: mapCamera,
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
        mapCamera: mapCamera,
        source: MapEventSource.longPress,
      ),
    );
  }

  // To be called when the map's size constraints change.
  void nonRotatedSizeChange(
    MapEventSource source,
    MapCamera oldMapCamera,
    MapCamera newMapCamera,
  ) {
    _emitMapEvent(
      MapEventNonRotatedSizeChange(
        source: MapEventSource.nonRotatedSizeChange,
        oldMapCamera: oldMapCamera,
        mapCamera: newMapCamera,
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

import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/gestures/map_interactive_viewer.dart';

/// This controller is for internal use. All updates to the state should be done
/// by calling methods of this class to ensure consistency.
class InternalMapController extends ValueNotifier<_InternalState> {
  late final MapInteractiveViewerState _interactiveViewerState;
  late MapControllerImpl _mapControllerImpl;

  InternalMapController(MapOptions options)
      : super(
          _InternalState(
            options: options,
            camera: MapCamera.initialCamera(options),
          ),
        );

  /// Link the viewer state with the controller. This should be done once when
  /// the MapInteractiveViewerState is initialized.
  set interactiveViewerState(
    MapInteractiveViewerState interactiveViewerState,
  ) =>
      _interactiveViewerState = interactiveViewerState;

  MapOptions get options => value.options;

  MapCamera get camera => value.camera;

  void linkMapController(MapControllerImpl mapControllerImpl) {
    _mapControllerImpl = mapControllerImpl;
    _mapControllerImpl.internalController = this;
  }

  /// This setter should only be called in this class or within tests. Changes
  /// to the [FlutterMapInternalState] should be done via methods in this class.
  @visibleForTesting
  @override
  // ignore: library_private_types_in_public_api
  set value(_InternalState value) => super.value = value;

  /// Note: All named parameters are required to prevent inconsistent default
  /// values since this method can be called by MapController which declares
  /// defaults.
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
      final newPoint = camera.project(newCenter, newZoom);
      newCenter = camera.unproject(
        camera.rotatePoint(
          newPoint,
          newPoint - Point(offset.dx, offset.dy),
        ),
        newZoom,
      );
    }

    MapCamera? newCamera = camera.withPosition(
      center: newCenter,
      zoom: camera.clampZoom(newZoom),
    );

    newCamera = options.cameraConstraint.constrain(newCamera);
    if (newCamera == null ||
        (newCamera.center == camera.center && newCamera.zoom == camera.zoom)) {
      return false;
    }

    final oldCamera = camera;
    value = value.withMapCamera(newCamera);

    final movementEvent = MapEventWithMove.fromSource(
      oldCamera: oldCamera,
      camera: camera,
      hasGesture: hasGesture,
      source: source,
      id: id,
    );
    if (movementEvent != null) emitMapEvent(movementEvent);

    options.onPositionChanged?.call(
      MapPosition(
        center: newCenter,
        bounds: camera.visibleBounds,
        zoom: newZoom,
        hasGesture: hasGesture,
      ),
      hasGesture,
    );

    return true;
  }

  /// Note: All named parameters are required to prevent inconsistent default
  /// values since this method can be called by MapController which declares
  /// defaults.
  bool rotate(
    double newRotation, {
    required bool hasGesture,
    required MapEventSource source,
    required String? id,
  }) {
    if (newRotation != camera.rotation) {
      final newCamera = options.cameraConstraint.constrain(
        camera.withRotation(newRotation),
      );
      if (newCamera == null) return false;

      final oldCamera = camera;

      // Update camera then emit events and callbacks
      value = value.withMapCamera(newCamera);

      emitMapEvent(
        MapEventRotate(
          id: id,
          source: source,
          oldCamera: oldCamera,
          camera: camera,
        ),
      );
      return true;
    }

    return false;
  }

  /// Note: All named parameters are required to prevent inconsistent default
  /// values since this method can be called by MapController which declares
  /// defaults.
  MoveAndRotateResult rotateAroundPoint(
    double degree, {
    required Point<double>? point,
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

    if (degree == camera.rotation) {
      return const (moveSuccess: false, rotateSuccess: false);
    }

    if (offset == Offset.zero) {
      return (
        moveSuccess: true,
        rotateSuccess: rotate(
          degree,
          hasGesture: hasGesture,
          source: source,
          id: id,
        ),
      );
    }

    final rotationDiff = degree - camera.rotation;
    final rotationCenter = camera.project(camera.center) +
        (point != null
                ? (point - (camera.nonRotatedSize / 2.0))
                : Point(offset!.dx, offset.dy))
            .rotate(camera.rotationRad);

    return (
      moveSuccess: move(
        camera.unproject(
          rotationCenter +
              (camera.project(camera.center) - rotationCenter)
                  .rotate(degToRadian(rotationDiff)),
        ),
        camera.zoom,
        offset: Offset.zero,
        hasGesture: hasGesture,
        source: source,
        id: id,
      ),
      rotateSuccess: rotate(
        camera.rotation + rotationDiff,
        hasGesture: hasGesture,
        source: source,
        id: id,
      ),
    );
  }

  /// Note: All named parameters are required to prevent inconsistent default
  /// values since this method can be called by MapController which declares
  /// defaults.
  MoveAndRotateResult moveAndRotate(
    LatLng newCenter,
    double newZoom,
    double newRotation, {
    required Offset offset,
    required bool hasGesture,
    required MapEventSource source,
    required String? id,
  }) =>
      (
        moveSuccess: move(
          newCenter,
          newZoom,
          offset: offset,
          hasGesture: hasGesture,
          source: source,
          id: id,
        ),
        rotateSuccess:
            rotate(newRotation, id: id, source: source, hasGesture: hasGesture),
      );

  /// Note: All named parameters are required to prevent inconsistent default
  /// values since this method can be called by MapController which declares
  /// defaults.
  bool fitCamera(
    CameraFit cameraFit, {
    required Offset offset,
  }) {
    final fitted = cameraFit.fit(camera);

    return move(
      fitted.center,
      fitted.zoom,
      offset: offset,
      hasGesture: false,
      source: MapEventSource.mapController,
      id: null,
    );
  }

  bool setNonRotatedSizeWithoutEmittingEvent(
    Point<double> nonRotatedSize,
  ) {
    if (nonRotatedSize != MapCamera.kImpossibleSize &&
        nonRotatedSize != camera.nonRotatedSize) {
      value = value.withMapCamera(camera.withNonRotatedSize(nonRotatedSize));
      return true;
    }

    return false;
  }

  void setOptions(MapOptions newOptions) {
    assert(
      newOptions != value.options,
      'Should not update options unless they change',
    );

    final newCamera = camera.withOptions(newOptions);

    assert(
      newOptions.cameraConstraint.constrain(newCamera) == newCamera,
      'MapCamera is no longer within the cameraConstraint after an option change.',
    );

    if (options.interactionOptions != newOptions.interactionOptions) {
      _interactiveViewerState.updateGestures(
        newOptions.interactionOptions.flags,
      );
    }

    value = _InternalState(
      options: newOptions,
      camera: newCamera,
    );
  }

  /// To be called when an ongoing drag movement updates.
  void dragUpdated(MapEventSource source, Offset offset) {
    final oldCenterPt = camera.project(camera.center);

    final newCenterPt = oldCenterPt + offset.toPoint();
    final newCenter = camera.unproject(newCenterPt);

    move(
      newCenter,
      camera.zoom,
      offset: Offset.zero,
      hasGesture: true,
      source: source,
      id: null,
    );
  }

  /// To be called when a rotation gesture starts.
  void rotateStarted(MapEventSource source) {
    emitMapEvent(
      MapEventRotateStart(
        camera: camera,
        source: source,
      ),
    );
  }

  /// To be called when a rotation gesture ends.
  void rotateEnded(MapEventSource source) {
    emitMapEvent(
      MapEventRotateEnd(
        camera: camera,
        source: source,
      ),
    );
  }

  /// To be called when a fling gesture starts.
  void flingStarted(MapEventSource source) {
    emitMapEvent(
      MapEventFlingAnimationStart(
        camera: camera,
        source: MapEventSource.flingAnimationController,
      ),
    );
  }

  /// To be called when a fling gesture ends.
  void flingEnded(MapEventSource source) {
    emitMapEvent(
      MapEventFlingAnimationEnd(
        camera: camera,
        source: source,
      ),
    );
  }

  /// To be called when a fling gesture does not start.
  void flingNotStarted(MapEventSource source) {
    emitMapEvent(
      MapEventFlingAnimationNotStarted(
        camera: camera,
        source: source,
      ),
    );
  }

  /// To be called when the map's size constraints change.
  void nonRotatedSizeChange(
    MapEventSource source,
    MapCamera oldCamera,
    MapCamera newCamera,
  ) {
    emitMapEvent(
      MapEventNonRotatedSizeChange(
        source: MapEventSource.nonRotatedSizeChange,
        oldCamera: oldCamera,
        camera: newCamera,
      ),
    );
  }

  void emitMapEvent(MapEvent event) {
    if (event.source == MapEventSource.mapController && event is MapEventMove) {
      _interactiveViewerState.interruptAnimatedMovement(event);
    }
    options.onMapEvent?.call(event);
    _mapControllerImpl.mapEventSink.add(event);
  }
}

@immutable
class _InternalState {
  final MapCamera camera;
  final MapOptions options;

  const _InternalState({
    required this.options,
    required this.camera,
  });

  _InternalState withMapCamera(MapCamera camera) => _InternalState(
        options: options,
        camera: camera,
      );
}

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
            mapFrame: MapFrame.initialFrame(options),
          ),
        );

  // Link the viewer state with the controller. This should be done once when
  // the FlutterMapInteractiveViewerState is initialized.
  set interactiveViewerState(
    FlutterMapInteractiveViewerState interactiveViewerState,
  ) =>
      _interactiveViewerState = interactiveViewerState;

  MapOptions get options => value.options;
  MapFrame get mapFrame => value.mapFrame;

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
      final newPoint = mapFrame.project(newCenter, newZoom);
      newCenter = mapFrame.unproject(
        mapFrame.rotatePoint(
          newPoint,
          newPoint - CustomPoint(offset.dx, offset.dy),
        ),
        newZoom,
      );
    }

    MapFrame? newMapFrame = mapFrame.withPosition(
      center: newCenter,
      zoom: mapFrame.clampZoom(newZoom),
    );

    newMapFrame = options.frameConstraint.constrain(newMapFrame);
    if (newMapFrame == null ||
        (newMapFrame.center == mapFrame.center &&
            newMapFrame.zoom == mapFrame.zoom)) {
      return false;
    }

    final oldMapFrame = mapFrame;
    value = value.withMapFrame(newMapFrame);

    final movementEvent = MapEventWithMove.fromSource(
      oldMapFrame: oldMapFrame,
      mapFrame: mapFrame,
      hasGesture: hasGesture,
      source: source,
      id: id,
    );
    if (movementEvent != null) _emitMapEvent(movementEvent);

    options.onPositionChanged?.call(
      MapPosition(
        center: newCenter,
        bounds: mapFrame.visibleBounds,
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
    if (newRotation != mapFrame.rotation) {
      final newMapFrame = options.frameConstraint.constrain(
        mapFrame.withRotation(newRotation),
      );
      if (newMapFrame == null) return false;

      final oldMapFrame = mapFrame;

      // Update frame then emit events and callbacks
      value = value.withMapFrame(newMapFrame);

      _emitMapEvent(
        MapEventRotate(
          id: id,
          source: source,
          oldMapFrame: oldMapFrame,
          mapFrame: mapFrame,
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

    if (degree == mapFrame.rotation) {
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

    final rotationDiff = degree - mapFrame.rotation;
    final rotationCenter = mapFrame.project(mapFrame.center) +
        (point != null
                ? (point - (mapFrame.nonRotatedSize / 2.0))
                : CustomPoint(offset!.dx, offset.dy))
            .rotate(mapFrame.rotationRad);

    return MoveAndRotateResult(
      move(
        mapFrame.unproject(
          rotationCenter +
              (mapFrame.project(mapFrame.center) - rotationCenter)
                  .rotate(degToRadian(rotationDiff)),
        ),
        mapFrame.zoom,
        offset: Offset.zero,
        hasGesture: hasGesture,
        source: source,
        id: id,
      ),
      rotate(
        mapFrame.rotation + rotationDiff,
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
  bool fitFrame(
    FrameFit frameFit, {
    required Offset offset,
  }) {
    final fitted = frameFit.fit(mapFrame);

    return move(
      fitted.center,
      fitted.zoom,
      offset: offset,
      hasGesture: false,
      source: MapEventSource.fitFrame,
      id: null,
    );
  }

  bool setNonRotatedSizeWithoutEmittingEvent(
    CustomPoint<double> nonRotatedSize,
  ) {
    if (nonRotatedSize != MapFrame.kImpossibleSize &&
        nonRotatedSize != mapFrame.nonRotatedSize) {
      value = value.withMapFrame(mapFrame.withNonRotatedSize(nonRotatedSize));
      return true;
    }

    return false;
  }

  void setOptions(MapOptions newOptions) {
    assert(
      newOptions != value.options,
      'Should not update options unless they change',
    );

    final newMapFrame = mapFrame.withOptions(newOptions);

    assert(
      newOptions.frameConstraint.constrain(newMapFrame) == newMapFrame,
      'MapFrame is no longer within the frameConstraint after an option change.',
    );

    if (options.interactionOptions != newOptions.interactionOptions) {
      _interactiveViewerState.updateGestures(
        options.interactionOptions,
        newOptions.interactionOptions,
      );
    }

    value = FlutterMapInternalState(
      options: newOptions,
      mapFrame: newMapFrame,
    );
  }

  // To be called when a gesture that causes movement starts.
  void moveStarted(MapEventSource source) {
    _emitMapEvent(
      MapEventMoveStart(
        mapFrame: mapFrame,
        source: source,
      ),
    );
  }

  // To be called when an ongoing drag movement updates.
  void dragUpdated(MapEventSource source, Offset offset) {
    final oldCenterPt = mapFrame.project(mapFrame.center);

    final newCenterPt = oldCenterPt + offset.toCustomPoint();
    final newCenter = mapFrame.unproject(newCenterPt);

    move(
      newCenter,
      mapFrame.zoom,
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
        mapFrame: mapFrame,
        source: source,
      ),
    );
  }

  // To be called when a rotation gesture starts.
  void rotateStarted(MapEventSource source) {
    _emitMapEvent(
      MapEventRotateStart(
        mapFrame: mapFrame,
        source: source,
      ),
    );
  }

  // To be called when a rotation gesture ends.
  void rotateEnded(MapEventSource source) {
    _emitMapEvent(
      MapEventRotateEnd(
        mapFrame: mapFrame,
        source: source,
      ),
    );
  }

  // To be called when a fling gesture starts.
  void flingStarted(MapEventSource source) {
    _emitMapEvent(
      MapEventFlingAnimationStart(
        mapFrame: mapFrame,
        source: MapEventSource.flingAnimationController,
      ),
    );
  }

  // To be called when a fling gesture ends.
  void flingEnded(MapEventSource source) {
    _emitMapEvent(
      MapEventFlingAnimationEnd(
        mapFrame: mapFrame,
        source: source,
      ),
    );
  }

  // To be called when a fling gesture does not start.
  void flingNotStarted(MapEventSource source) {
    _emitMapEvent(
      MapEventFlingAnimationNotStarted(
        mapFrame: mapFrame,
        source: source,
      ),
    );
  }

  // To be called when a double tap zoom starts.
  void doubleTapZoomStarted(MapEventSource source) {
    _emitMapEvent(
      MapEventDoubleTapZoomStart(
        mapFrame: mapFrame,
        source: source,
      ),
    );
  }

  // To be called when a double tap zoom ends.
  void doubleTapZoomEnded(MapEventSource source) {
    _emitMapEvent(
      MapEventDoubleTapZoomEnd(
        mapFrame: mapFrame,
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
        mapFrame: mapFrame,
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
        mapFrame: mapFrame,
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
        mapFrame: mapFrame,
        source: MapEventSource.longPress,
      ),
    );
  }

  // To be called when the map's size constraints change.
  void nonRotatedSizeChange(
    MapEventSource source,
    MapFrame oldMapFrame,
    MapFrame newMapFrame,
  ) {
    _emitMapEvent(
      MapEventNonRotatedSizeChange(
        source: MapEventSource.nonRotatedSizeChange,
        oldMapFrame: oldMapFrame,
        mapFrame: newMapFrame,
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

import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/map/gestures/map_interactive_viewer.dart';
import 'package:latlong2/latlong.dart';
import 'package:vector_math/vector_math_64.dart';

/// Implements [MapController] whilst exposing methods for internal use which
/// should not be visible to the user (e.g. for setting the current camera).
/// This controller is for internal use. All updates to the state should be done
/// by calling methods of this class to ensure consistency.
class MapControllerImpl extends ValueNotifier<_MapControllerState>
    implements MapController {
  final _mapEventStreamController = StreamController<MapEvent>.broadcast();

  late final MapInteractiveViewerState _interactiveViewerState;

  Animation<LatLng>? _moveAnimation;
  Animation<double>? _zoomAnimation;
  Animation<double>? _rotationAnimation;
  Animation<Offset>? _flingAnimation;
  late bool _animationHasGesture;
  late Offset _animationOffset;
  late Point _flingMapCenterStartPoint;

  /// Create a new [MapController] instance. This constructor is only used
  /// internally.
  MapControllerImpl({MapOptions? options, TickerProvider? vsync})
      : super(
          _MapControllerState(
            options: options,
            camera: options == null ? null : MapCamera.initialCamera(options),
            animationController:
                vsync == null ? null : AnimationController(vsync: vsync),
          ),
        ) {
    value.animationController?.addListener(_handleAnimation);
  }

  /// Link the viewer state with the controller. This should be done once when
  /// the FlutterMapInteractiveViewerState is initialized.
  set interactiveViewerState(
    MapInteractiveViewerState interactiveViewerState,
  ) =>
      _interactiveViewerState = interactiveViewerState;

  StreamSink<MapEvent> get _mapEventSink => _mapEventStreamController.sink;

  @override
  Stream<MapEvent> get mapEventStream => _mapEventStreamController.stream;

  /// Get the [MapOptions] from the controller state
  MapOptions get options {
    return value.options ??
        (throw Exception('You need to have the FlutterMap widget rendered at '
            'least once before using the MapController.'));
  }

  /// Get the [MapCamera] from the controller state
  @override
  MapCamera get camera {
    return value.camera ??
        (throw Exception('You need to have the FlutterMap widget rendered at '
            'least once before using the MapController.'));
  }

  /// Get the [AnimationController] from the controller state
  AnimationController get _animationController {
    return value.animationController ??
        (throw Exception('You need to have the FlutterMap widget rendered at '
            'least once before using the MapController.'));
  }

  /// This setter should only be called in this class or within tests. Changes
  /// to the [_MapControllerState] should be done via methods in this class.
  @visibleForTesting
  @override
  // ignore: library_private_types_in_public_api
  set value(_MapControllerState value) => super.value = value;

  /// Implemented method from the public [MapController.move] API.
  /// Calls [moveRaw] with [MapEventSource.mapController] as event source.
  @override
  bool move(
    LatLng center,
    double zoom, {
    Offset offset = Offset.zero,
    String? id,
  }) =>
      moveRaw(
        center,
        zoom,
        offset: offset,
        hasGesture: false,
        source: MapEventSource.mapController,
        id: id,
      );

  /// Implemented method from the public [MapController.rotate] API.
  /// Calls [rotateRaw] with [MapEventSource.mapController] as event source.
  @override
  bool rotate(double degree, {String? id}) => rotateRaw(
        degree,
        hasGesture: false,
        source: MapEventSource.mapController,
        id: id,
      );

  /// Implemented method from the public [MapController.rotateAroundPoint] API.
  /// Calls [rotateAroundPointRaw] with [MapEventSource.mapController] as
  /// event source.
  @override
  bool rotateAroundPoint(
    double degree, {
    Point<double>? point,
    Offset? offset,
    String? id,
  }) =>
      rotateAroundPointRaw(
        degree,
        point: point,
        offset: offset,
        hasGesture: false,
        source: MapEventSource.mapController,
        id: id,
      );

  /// Implemented method from the public [MapController.moveAndRotate] API.
  /// Calls [moveAndRotateRaw] with [MapEventSource.mapController] as
  /// event source.
  @override
  bool moveAndRotate(
    LatLng center,
    double zoom,
    double degree, {
    String? id,
  }) =>
      moveAndRotateRaw(
        center,
        zoom,
        degree,
        offset: Offset.zero,
        hasGesture: false,
        source: MapEventSource.mapController,
        id: id,
      );

  /// Implemented method from the public [MapController.fitCamera] API.
  /// Calls [fitCameraRaw] with [MapEventSource.mapController] as event source.
  @override
  bool fitCamera(CameraFit cameraFit) => fitCameraRaw(
        cameraFit,
        source: MapEventSource.mapController,
      );

  /// Internal method, allows access to every parameter.
  bool moveRaw(
    LatLng newCenter,
    double newZoom, {
    Offset offset = Offset.zero,
    required bool hasGesture,
    required MapEventSource source,
    String? id,
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

  /// Internal method, allows access to every parameter.
  bool rotateRaw(
    double newRotation, {
    required bool hasGesture,
    required MapEventSource source,
    String? id,
  }) {
    if (newRotation == camera.rotation) return false;

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

  /// Internal method, allows access to every parameter.
  bool rotateAroundPointRaw(
    double degree, {
    required Point<double>? point,
    required Offset? offset,
    required bool hasGesture,
    required MapEventSource source,
    String? id,
  }) {
    if (point != null && offset != null) {
      throw ArgumentError('Only one of `point` or `offset` may be non-null');
    }
    if (point == null && offset == null) {
      throw ArgumentError('One of `point` or `offset` must be non-null');
    }

    if (degree == camera.rotation) return false;

    if (offset == Offset.zero) {
      return rotateRaw(
        degree,
        hasGesture: hasGesture,
        source: source,
        id: id,
      );
    }

    final rotationDiff = degree - camera.rotation;
    final rotationCenter = camera.project(camera.center) +
        (point != null
                ? (point - (camera.nonRotatedSize / 2.0))
                : Point(offset!.dx, offset.dy))
            .rotate(camera.rotationRad);

    final moved = moveRaw(
      camera.unproject(
        rotationCenter +
            (camera.project(camera.center) - rotationCenter)
                .rotate(degrees2Radians * rotationDiff),
      ),
      camera.zoom,
      hasGesture: hasGesture,
      source: source,
      id: id,
    );
    final rotated = rotateRaw(
      camera.rotation + rotationDiff,
      hasGesture: hasGesture,
      source: source,
      id: id,
    );
    return moved || rotated;
  }

  /// Internal method, allows access to every parameter.
  /// Calls [moveRaw] and [rotateRaw].
  bool moveAndRotateRaw(
    LatLng newCenter,
    double newZoom,
    double newRotation, {
    required Offset offset,
    required bool hasGesture,
    required MapEventSource source,
    String? id,
  }) {
    final moved = moveRaw(
      newCenter,
      newZoom,
      offset: offset,
      hasGesture: hasGesture,
      source: source,
      id: id,
    );
    final rotated = rotateRaw(
      newRotation,
      id: id,
      source: source,
      hasGesture: hasGesture,
    );
    return moved || rotated;
  }

  /// Internal method, allows access to every parameter.
  bool fitCameraRaw(
    CameraFit cameraFit, {
    Offset offset = Offset.zero,
    bool hasGesture = false,
    required MapEventSource source,
  }) {
    final fitted = cameraFit.fit(camera);
    return moveRaw(
      fitted.center,
      fitted.zoom,
      offset: offset,
      hasGesture: hasGesture,
      source: source,
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

  /// Update the [MapOptions] in the controller state.
  set options(MapOptions newOptions) {
    assert(
      newOptions != value.options,
      'Should not update options unless they change',
    );

    final newCamera = value.camera?.withOptions(newOptions) ??
        MapCamera.initialCamera(newOptions);

    assert(
      newOptions.cameraConstraint.constrain(newCamera) == newCamera,
      'MapCamera is no longer within the cameraConstraint after an option change.',
    );

    if (value.options != null &&
        value.options!.interactionOptions != newOptions.interactionOptions) {
      _interactiveViewerState.updateGestures(
        value.options!.interactionOptions.enabledGestures,
        newOptions.interactionOptions.enabledGestures,
      );
    }

    value = _MapControllerState(
      options: newOptions,
      camera: newCamera,
      animationController: value.animationController,
    );
  }

  /// Update the [TickerProvider] for the animations in the controller state.
  set vsync(TickerProvider tickerProvider) {
    if (value.animationController == null) {
      value = _MapControllerState(
        options: value.options,
        camera: value.camera,
        animationController: AnimationController(vsync: tickerProvider)
          ..addListener(_handleAnimation),
      );
    } else {
      _animationController.resync(tickerProvider);
    }
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

  /// Internal method, allows access to every parameter.
  void moveAndRotateAnimatedRaw(
    LatLng newCenter,
    double newZoom,
    double newRotation, {
    required Offset offset,
    required Duration duration,
    required Curve curve,
    required bool hasGesture,
    required MapEventSource source,
  }) {
    if (newRotation == camera.rotation) {
      moveAnimatedRaw(
        newCenter,
        newZoom,
        duration: duration,
        curve: curve,
        hasGesture: hasGesture,
        source: source,
      );
      return;
    }
    // cancel all ongoing animation
    _animationController.stop();
    _resetAnimations();

    if (newCenter == camera.center && newZoom == camera.zoom) return;

    // create the new animation
    _moveAnimation = LatLngTween(begin: camera.center, end: newCenter)
        .chain(CurveTween(curve: curve))
        .animate(_animationController);
    _zoomAnimation = Tween<double>(begin: camera.zoom, end: newZoom)
        .chain(CurveTween(curve: curve))
        .animate(_animationController);
    _rotationAnimation = Tween<double>(begin: camera.rotation, end: newRotation)
        .chain(CurveTween(curve: curve))
        .animate(_animationController);

    _animationController.duration = duration;
    _animationHasGesture = hasGesture;
    _animationOffset = offset;

    // start the animation from its start
    _animationController.forward(from: 0);
  }

  /// Internal method, allows access to every parameter.
  void rotateAnimatedRaw(
    double newRotation, {
    required Offset offset,
    required Duration duration,
    required Curve curve,
    required bool hasGesture,
    required MapEventSource source,
  }) {
    // cancel all ongoing animation
    _animationController.stop();
    _resetAnimations();

    if (newRotation == camera.rotation) return;

    // create the new animation
    _rotationAnimation = Tween<double>(begin: camera.rotation, end: newRotation)
        .chain(CurveTween(curve: curve))
        .animate(_animationController);

    _animationController.duration = duration;
    _animationHasGesture = hasGesture;
    _animationOffset = offset;

    // start the animation from its start
    _animationController.forward(from: 0);
  }

  /// Internal method, stops all ongoing animations of the [MapControllerImpl].
  void stopAnimationRaw({bool canceled = true}) {
    if (isAnimating) _animationController.stop(canceled: canceled);
  }

  bool get isAnimating => _animationController.isAnimating;

  void _resetAnimations() {
    _moveAnimation = null;
    _rotationAnimation = null;
    _zoomAnimation = null;
    _flingAnimation = null;
  }

  /// Internal method, allows access to every parameter.
  void flingAnimatedRaw({
    required double velocity,
    required Offset direction,
    required Offset begin,
    Offset offset = Offset.zero,
    double mass = 1,
    double stiffness = 1000,
    double ratio = 5,
    required bool hasGesture,
  }) {
    // cancel all ongoing animation
    _animationController.stop();
    _resetAnimations();

    _animationHasGesture = hasGesture;
    _animationOffset = offset;
    _flingMapCenterStartPoint = camera.project(camera.center);

    final distance =
        (Offset.zero & Size(camera.nonRotatedSize.x, camera.nonRotatedSize.y))
            .shortestSide;

    _flingAnimation = Tween<Offset>(
      begin: begin,
      end: begin - direction * distance,
    ).animate(_animationController);

    _animationController.value = 0;
    _animationController.fling(
      velocity: velocity,
      springDescription: SpringDescription.withDampingRatio(
        mass: mass,
        stiffness: stiffness,
        ratio: ratio,
      ),
    );
  }

  /// Internal method, allows access to every parameter.
  void moveAnimatedRaw(
    LatLng newCenter,
    double newZoom, {
    Offset offset = Offset.zero,
    required Duration duration,
    required Curve curve,
    required bool hasGesture,
    required MapEventSource source,
  }) {
    // cancel all ongoing animation
    _animationController.stop();
    _resetAnimations();

    if (newCenter == camera.center && newZoom == camera.zoom) return;

    // create the new animation
    _moveAnimation = LatLngTween(begin: camera.center, end: newCenter)
        .chain(CurveTween(curve: curve))
        .animate(_animationController);
    _zoomAnimation = Tween<double>(begin: camera.zoom, end: newZoom)
        .chain(CurveTween(curve: curve))
        .animate(_animationController);

    _animationController.duration = duration;
    _animationHasGesture = hasGesture;
    _animationOffset = offset;

    // start the animation from its start
    _animationController.forward(from: 0);
  }

  /// Emit an [MapEvent] to the event system.
  void emitMapEvent(MapEvent event) {
    options.onMapEvent?.call(event);
    _mapEventSink.add(event);
  }

  /// Callback that gets called by the [AnimationController] and updates
  /// the [MapCamera].
  void _handleAnimation() {
    // fling animation
    if (_flingAnimation != null) {
      final newCenterPoint = _flingMapCenterStartPoint +
          _flingAnimation!.value.toPoint().rotate(camera.rotationRad);
      moveRaw(
        camera.unproject(newCenterPoint),
        camera.zoom,
        hasGesture: _animationHasGesture,
        source: MapEventSource.flingAnimationController,
        offset: _animationOffset,
      );
      return;
    }

    // animated movement
    if (_moveAnimation != null) {
      if (_rotationAnimation != null) {
        moveAndRotateRaw(
          _moveAnimation?.value ?? camera.center,
          _zoomAnimation?.value ?? camera.zoom,
          _rotationAnimation!.value,
          hasGesture: _animationHasGesture,
          source: MapEventSource.mapController,
          offset: _animationOffset,
        );
      } else {
        moveRaw(
          _moveAnimation!.value,
          _zoomAnimation?.value ?? camera.zoom,
          hasGesture: _animationHasGesture,
          source: MapEventSource.mapController,
          offset: _animationOffset,
        );
      }
      return;
    }

    // animated rotation
    if (_rotationAnimation != null) {
      rotateRaw(
        _rotationAnimation!.value,
        hasGesture: _animationHasGesture,
        source: MapEventSource.mapController,
      );
    }
  }

  @override
  void dispose() {
    _mapEventStreamController.close();
    value.animationController?.dispose();
    super.dispose();
  }
}

/// The state for the [MapControllerImpl] [ValueNotifier].
@immutable
class _MapControllerState {
  final MapCamera? camera;
  final MapOptions? options;
  final AnimationController? animationController;

  const _MapControllerState({
    required this.options,
    required this.camera,
    required this.animationController,
  });

  /// Copy the [_MapControllerState] and set [MapCamera] to some new value.
  _MapControllerState withMapCamera(MapCamera camera) => _MapControllerState(
        options: options,
        camera: camera,
        animationController: animationController,
      );
}

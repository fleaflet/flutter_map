import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/gestures/latlng_tween.dart';
import 'package:flutter_map/src/map/flutter_map_state.dart';
import 'package:flutter_map/src/map/flutter_map_state_container.dart';
import 'package:latlong2/latlong.dart';

abstract class MapGestureMixin extends State<FlutterMap>
    with TickerProviderStateMixin {
  static const int _kMinFlingVelocity = 800;

  var _dragMode = false;
  var _gestureWinner = MultiFingerGesture.none;

  var _pointerCounter = 0;

  bool _isListeningForInterruptions = false;

  void onPointerDown(PointerDownEvent event) {
    ++_pointerCounter;
    if (mapState.options.onPointerDown != null) {
      final latlng = _offsetToCrs(event.localPosition);
      mapState.options.onPointerDown!(event, latlng);
    }
  }

  void onPointerUp(PointerUpEvent event) {
    --_pointerCounter;
    if (mapState.options.onPointerUp != null) {
      final latlng = _offsetToCrs(event.localPosition);
      mapState.options.onPointerUp!(event, latlng);
    }
  }

  void onPointerCancel(PointerCancelEvent event) {
    --_pointerCounter;
    if (mapState.options.onPointerCancel != null) {
      final latlng = _offsetToCrs(event.localPosition);
      mapState.options.onPointerCancel!(event, latlng);
    }
  }

  void onPointerHover(PointerHoverEvent event) {
    if (mapState.options.onPointerHover != null) {
      final latlng = _offsetToCrs(event.localPosition);
      mapState.options.onPointerHover!(event, latlng);
    }
  }

  void onPointerSignal(PointerSignalEvent pointerSignal) {
    // Handle mouse scroll events if the enableScrollWheel parameter is enabled
    if (pointerSignal is PointerScrollEvent &&
        mapState.options.enableScrollWheel &&
        pointerSignal.scrollDelta.dy != 0) {
      // Prevent scrolling of parent/child widgets simultaneously. See
      // [PointerSignalResolver] documentation for more information.
      GestureBinding.instance.pointerSignalResolver.register(pointerSignal,
          (pointerSignal) {
        pointerSignal as PointerScrollEvent;

        final minZoom = mapState.options.minZoom ?? 0.0;
        final maxZoom = mapState.options.maxZoom ?? double.infinity;
        final newZoom = (mapState.zoom -
                pointerSignal.scrollDelta.dy *
                    mapState.options.scrollWheelVelocity)
            .clamp(minZoom, maxZoom);
        // Calculate offset of mouse cursor from viewport center
        final List<dynamic> newCenterZoom = _getNewEventCenterZoomPosition(
            _offsetToPoint(pointerSignal.localPosition), newZoom);

        // Move to new center and zoom level
        mapStateContainer.move(
            newCenterZoom[0] as LatLng, newCenterZoom[1] as double,
            source: MapEventSource.scrollWheel);
      });
    }
  }

  var _rotationStarted = false;
  var _pinchZoomStarted = false;
  var _pinchMoveStarted = false;
  var _dragStarted = false;
  var _flingAnimationStarted = false;

  // Helps to reset ScaleUpdateDetails.scale back to 1.0 when a multi finger
  // gesture wins
  late double _scaleCorrector;

  late double _lastRotation;
  late double _lastScale;
  late Offset _lastFocalLocal;

  late LatLng _mapCenterStart;
  late double _mapZoomStart;
  late Offset _focalStartLocal;
  late LatLng _focalStartLatLng;

  late final AnimationController _flingController;
  late Animation<Offset> _flingAnimation;

  late final AnimationController _doubleTapController;
  late Animation<double> _doubleTapZoomAnimation;
  late Animation<LatLng> _doubleTapCenterAnimation;

  int _tapUpCounter = 0;
  Timer? _doubleTapHoldMaxDelay;

  @override
  FlutterMap get widget;

  FlutterMapStateContainer get mapStateContainer;
  FlutterMapState get mapState;

  MapController get mapController;

  MapOptions get options;

  @override
  void initState() {
    super.initState();
    _flingController = AnimationController(vsync: this)
      ..addListener(_handleFlingAnimation)
      ..addStatusListener(_flingAnimationStatusListener);
    _doubleTapController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200))
      ..addListener(_handleDoubleTapZoomAnimation)
      ..addStatusListener(_doubleTapZoomStatusListener);
  }

  @override
  void didUpdateWidget(FlutterMap oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldFlags = oldWidget.options.interactiveFlags;
    final flags = options.interactiveFlags;

    final oldGestures =
        _getMultiFingerGestureFlags(mapOptions: oldWidget.options);
    final gestures = _getMultiFingerGestureFlags();

    if (flags != oldFlags || gestures != oldGestures) {
      var emitMapEventMoveEnd = false;

      if (!InteractiveFlag.hasFlag(flags, InteractiveFlag.flingAnimation)) {
        closeFlingAnimationController(MapEventSource.interactiveFlagsChanged);
      }
      if (!InteractiveFlag.hasFlag(flags, InteractiveFlag.doubleTapZoom)) {
        closeDoubleTapController(MapEventSource.interactiveFlagsChanged);
      }

      if (_rotationStarted &&
          !(InteractiveFlag.hasFlag(flags, InteractiveFlag.rotate) &&
              MultiFingerGesture.hasFlag(
                  gestures, MultiFingerGesture.rotate))) {
        _rotationStarted = false;

        if (_gestureWinner == MultiFingerGesture.rotate) {
          _gestureWinner = MultiFingerGesture.none;
        }

        mapStateContainer.emitMapEvent(
          MapEventRotateEnd(
            mapState: mapState,
            source: MapEventSource.interactiveFlagsChanged,
          ),
        );
      }

      if (_pinchZoomStarted &&
          !(InteractiveFlag.hasFlag(flags, InteractiveFlag.pinchZoom) &&
              MultiFingerGesture.hasFlag(
                  gestures, MultiFingerGesture.pinchZoom))) {
        _pinchZoomStarted = false;
        emitMapEventMoveEnd = true;

        if (_gestureWinner == MultiFingerGesture.pinchZoom) {
          _gestureWinner = MultiFingerGesture.none;
        }
      }

      if (_pinchMoveStarted &&
          !(InteractiveFlag.hasFlag(flags, InteractiveFlag.pinchMove) &&
              MultiFingerGesture.hasFlag(
                  gestures, MultiFingerGesture.pinchMove))) {
        _pinchMoveStarted = false;
        emitMapEventMoveEnd = true;

        if (_gestureWinner == MultiFingerGesture.pinchMove) {
          _gestureWinner = MultiFingerGesture.none;
        }
      }

      if (_dragStarted &&
          !InteractiveFlag.hasFlag(flags, InteractiveFlag.drag)) {
        _dragStarted = false;
        emitMapEventMoveEnd = true;
      }

      if (emitMapEventMoveEnd) {
        mapStateContainer.emitMapEvent(
          MapEventRotateEnd(
            mapState: mapState,
            source: MapEventSource.interactiveFlagsChanged,
          ),
        );
      }
    }
  }

  void _yieldMultiFingerGestureWinner(
      int gestureWinner, bool resetStartVariables) {
    _gestureWinner = gestureWinner;

    if (resetStartVariables) {
      // note: here we could reset to current values instead of last values
      _scaleCorrector = 1.0 - _lastScale;
    }
  }

  int _getMultiFingerGestureFlags(
      {int? gestureWinner, MapOptions? mapOptions}) {
    gestureWinner ??= _gestureWinner;
    mapOptions ??= options;

    if (mapOptions.enableMultiFingerGestureRace) {
      if (gestureWinner == MultiFingerGesture.pinchZoom) {
        return mapOptions.pinchZoomWinGestures;
      } else if (gestureWinner == MultiFingerGesture.rotate) {
        return mapOptions.rotationWinGestures;
      } else if (gestureWinner == MultiFingerGesture.pinchMove) {
        return mapOptions.pinchMoveWinGestures;
      }

      return MultiFingerGesture.none;
    } else {
      return MultiFingerGesture.all;
    }
  }

  void closeFlingAnimationController(MapEventSource source) {
    _flingAnimationStarted = false;
    if (_flingController.isAnimating) {
      _flingController.stop();

      _stopListeningForAnimationInterruptions();

      mapStateContainer.emitMapEvent(
        MapEventFlingAnimationEnd(
          mapState: mapState,
          source: source,
        ),
      );
    }
  }

  void closeDoubleTapController(MapEventSource source) {
    if (_doubleTapController.isAnimating) {
      _doubleTapController.stop();

      _stopListeningForAnimationInterruptions();

      mapStateContainer.emitMapEvent(
        MapEventDoubleTapZoomEnd(
          mapState: mapState,
          source: source,
        ),
      );
    }
  }

  void handleScaleStart(ScaleStartDetails details) {
    _dragMode = _pointerCounter == 1;

    final eventSource = _dragMode
        ? MapEventSource.dragStart
        : MapEventSource.multiFingerGestureStart;
    closeFlingAnimationController(eventSource);
    closeDoubleTapController(eventSource);

    _gestureWinner = MultiFingerGesture.none;

    _mapZoomStart = mapStateContainer.zoom;
    _mapCenterStart = mapStateContainer.center;
    _focalStartLocal = _lastFocalLocal = details.localFocalPoint;
    _focalStartLatLng = _offsetToCrs(_focalStartLocal);

    _dragStarted = false;
    _pinchZoomStarted = false;
    _pinchMoveStarted = false;
    _rotationStarted = false;

    _lastRotation = 0.0;
    _scaleCorrector = 0.0;
    _lastScale = 1.0;
  }

  void handleScaleUpdate(ScaleUpdateDetails details) {
    if (_tapUpCounter == 1) {
      _handleDoubleTapHold(details);
      return;
    }

    final eventSource =
        _dragMode ? MapEventSource.onDrag : MapEventSource.onMultiFinger;

    final flags = options.interactiveFlags;
    final focalOffset = details.localFocalPoint;

    final currentRotation = radianToDeg(details.rotation);

    if (_dragMode) {
      if (InteractiveFlag.hasFlag(flags, InteractiveFlag.drag)) {
        if (!_dragStarted) {
          // We could emit start event at [handleScaleStart], however it is
          // possible drag will be disabled during ongoing drag then
          // [didUpdateWidget] will emit MapEventMoveEnd and if drag is enabled
          // again then this will emit the start event again.
          _dragStarted = true;
          mapStateContainer.emitMapEvent(
            MapEventMoveStart(
              mapState: mapState,
              source: eventSource,
            ),
          );
        }

        final oldCenterPt =
            mapState.project(mapStateContainer.center, mapStateContainer.zoom);
        final localDistanceOffset =
            _rotateOffset(_lastFocalLocal - focalOffset);

        final newCenterPt = oldCenterPt + _offsetToPoint(localDistanceOffset);
        final newCenter =
            mapState.unproject(newCenterPt, mapStateContainer.zoom);

        mapStateContainer.move(
          newCenter,
          mapStateContainer.zoom,
          hasGesture: true,
          source: eventSource,
        );
      }
    } else {
      final hasIntPinchMove =
          InteractiveFlag.hasFlag(flags, InteractiveFlag.pinchMove);
      final hasIntPinchZoom =
          InteractiveFlag.hasFlag(flags, InteractiveFlag.pinchZoom);
      final hasIntRotate =
          InteractiveFlag.hasFlag(flags, InteractiveFlag.rotate);

      if (hasIntPinchMove || hasIntPinchZoom || hasIntRotate) {
        final hasGestureRace = options.enableMultiFingerGestureRace;

        if (hasGestureRace && _gestureWinner == MultiFingerGesture.none) {
          if (hasIntPinchZoom &&
              (_getZoomForScale(_mapZoomStart, details.scale) - _mapZoomStart)
                      .abs() >=
                  options.pinchZoomThreshold) {
            if (options.debugMultiFingerGestureWinner) {
              debugPrint('Multi Finger Gesture winner: Pinch Zoom');
            }
            _yieldMultiFingerGestureWinner(MultiFingerGesture.pinchZoom, true);
          } else if (hasIntRotate &&
              currentRotation.abs() >= options.rotationThreshold) {
            if (options.debugMultiFingerGestureWinner) {
              debugPrint('Multi Finger Gesture winner: Rotate');
            }
            _yieldMultiFingerGestureWinner(MultiFingerGesture.rotate, true);
          } else if (hasIntPinchMove &&
              (_focalStartLocal - focalOffset).distance >=
                  options.pinchMoveThreshold) {
            if (options.debugMultiFingerGestureWinner) {
              debugPrint('Multi Finger Gesture winner: Pinch Move');
            }
            _yieldMultiFingerGestureWinner(MultiFingerGesture.pinchMove, true);
          }
        }

        if (!hasGestureRace || _gestureWinner != MultiFingerGesture.none) {
          final gestures = _getMultiFingerGestureFlags();

          final hasGesturePinchMove = MultiFingerGesture.hasFlag(
              gestures, MultiFingerGesture.pinchMove);
          final hasGesturePinchZoom = MultiFingerGesture.hasFlag(
              gestures, MultiFingerGesture.pinchZoom);
          final hasGestureRotate =
              MultiFingerGesture.hasFlag(gestures, MultiFingerGesture.rotate);

          final hasMove = hasIntPinchMove && hasGesturePinchMove;
          final hasZoom = hasIntPinchZoom && hasGesturePinchZoom;
          final hasRotate = hasIntRotate && hasGestureRotate;

          var mapMoved = false;
          var mapRotated = false;
          if (hasMove || hasZoom) {
            double newZoom;
            // checking details.scale to prevent situation whew details comes
            // with zero scale
            if (hasZoom && details.scale > 0.0) {
              newZoom = _getZoomForScale(
                  _mapZoomStart, details.scale + _scaleCorrector);

              if (!_pinchZoomStarted) {
                if (newZoom != _mapZoomStart) {
                  _pinchZoomStarted = true;

                  if (!_pinchMoveStarted) {
                    // emit MoveStart event only if pinchMove hasn't started
                    mapStateContainer.emitMapEvent(
                      MapEventMoveStart(
                        mapState: mapState,
                        source: eventSource,
                      ),
                    );
                  }
                }
              }
            } else {
              newZoom = mapStateContainer.zoom;
            }

            LatLng newCenter;
            if (hasMove) {
              if (!_pinchMoveStarted && _lastFocalLocal != focalOffset) {
                _pinchMoveStarted = true;

                if (!_pinchZoomStarted) {
                  // emit MoveStart event only if pinchZoom hasn't started
                  mapStateContainer.emitMapEvent(
                    MapEventMoveStart(
                      mapState: mapState,
                      source: eventSource,
                    ),
                  );
                }
              }

              if (_pinchZoomStarted || _pinchMoveStarted) {
                final oldCenterPt =
                    mapState.project(mapStateContainer.center, newZoom);
                final newFocalLatLong = _offsetToCrs(_focalStartLocal, newZoom);
                final newFocalPt = mapState.project(newFocalLatLong, newZoom);
                final oldFocalPt = mapState.project(_focalStartLatLng, newZoom);
                final zoomDifference = oldFocalPt - newFocalPt;
                final moveDifference =
                    _rotateOffset(_focalStartLocal - _lastFocalLocal);

                final newCenterPt = oldCenterPt +
                    zoomDifference +
                    _offsetToPoint(moveDifference);
                newCenter = mapState.unproject(newCenterPt, newZoom);
              } else {
                newCenter = mapStateContainer.center;
              }
            } else {
              newCenter = mapStateContainer.center;
            }

            if (_pinchZoomStarted || _pinchMoveStarted) {
              mapMoved = mapStateContainer.move(
                newCenter,
                newZoom,
                hasGesture: true,
                source: eventSource,
              );
            }
          }

          if (hasRotate) {
            if (!_rotationStarted && currentRotation != 0.0) {
              _rotationStarted = true;
              mapStateContainer.emitMapEvent(
                MapEventRotateStart(
                  mapState: mapState,
                  source: eventSource,
                ),
              );
            }

            if (_rotationStarted) {
              final rotationDiff = currentRotation - _lastRotation;
              final oldCenterPt = mapState.project(mapStateContainer.center);
              final rotationCenter =
                  mapState.project(_offsetToCrs(_lastFocalLocal));
              final vector = oldCenterPt - rotationCenter;
              final rotatedVector = vector.rotate(degToRadian(rotationDiff));
              final newCenter = rotationCenter + rotatedVector;
              mapMoved = mapStateContainer.move(
                      mapState.unproject(newCenter), mapStateContainer.zoom,
                      source: eventSource) ||
                  mapMoved;
              mapRotated = mapStateContainer.rotate(
                mapStateContainer.rotation + rotationDiff,
                hasGesture: true,
                source: eventSource,
              );
            }
          }

          if (mapMoved || mapRotated) mapStateContainer.setState(() {});
        }
      }
    }

    _lastRotation = currentRotation;
    _lastScale = details.scale;
    _lastFocalLocal = focalOffset;
  }

  void handleScaleEnd(ScaleEndDetails details) {
    _resetDoubleTapHold();

    final eventSource =
        _dragMode ? MapEventSource.dragEnd : MapEventSource.multiFingerEnd;

    if (_rotationStarted) {
      _rotationStarted = false;
      mapStateContainer.emitMapEvent(
        MapEventRotateEnd(
          mapState: mapState,
          source: eventSource,
        ),
      );
    }

    if (_dragStarted || _pinchZoomStarted || _pinchMoveStarted) {
      _dragStarted = _pinchZoomStarted = _pinchMoveStarted = false;
      mapStateContainer.emitMapEvent(
        MapEventMoveEnd(
          mapState: mapState,
          source: eventSource,
        ),
      );
    }

    final hasFling = InteractiveFlag.hasFlag(
        options.interactiveFlags, InteractiveFlag.flingAnimation);

    final magnitude = details.velocity.pixelsPerSecond.distance;
    if (magnitude < _kMinFlingVelocity || !hasFling) {
      if (hasFling) {
        mapStateContainer.emitMapEvent(
          MapEventFlingAnimationNotStarted(
            mapState: mapState,
            source: eventSource,
          ),
        );
      }

      return;
    }

    final direction = details.velocity.pixelsPerSecond / magnitude;
    final distance = (Offset.zero &
            Size(mapState.nonrotatedSize.x, mapState.nonrotatedSize.y))
        .shortestSide;

    final flingOffset = _focalStartLocal - _lastFocalLocal;
    _flingAnimation = Tween<Offset>(
      begin: flingOffset,
      end: flingOffset - direction * distance,
    ).animate(_flingController);

    _flingController
      ..value = 0.0
      ..fling(
          velocity: magnitude / 1000.0,
          springDescription: SpringDescription.withDampingRatio(
            mass: 1,
            stiffness: 1000,
            ratio: 5,
          ));
  }

  void handleTap(TapPosition position) {
    closeFlingAnimationController(MapEventSource.tap);
    closeDoubleTapController(MapEventSource.tap);

    final relativePosition = position.relative;
    if (relativePosition == null) return;

    final latlng = _offsetToCrs(relativePosition);
    final onTap = options.onTap;
    if (onTap != null) {
      // emit the event
      onTap(position, latlng);
    }

    mapStateContainer.emitMapEvent(
      MapEventTap(
        tapPosition: latlng,
        mapState: mapState,
        source: MapEventSource.tap,
      ),
    );
  }

  void handleSecondaryTap(TapPosition position) {
    closeFlingAnimationController(MapEventSource.secondaryTap);
    closeDoubleTapController(MapEventSource.secondaryTap);

    final relativePosition = position.relative;
    if (relativePosition == null) return;

    final latlng = _offsetToCrs(relativePosition);
    final onSecondaryTap = options.onSecondaryTap;
    if (onSecondaryTap != null) {
      // emit the event
      onSecondaryTap(position, latlng);
    }

    mapStateContainer.emitMapEvent(
      MapEventSecondaryTap(
        tapPosition: latlng,
        mapState: mapState,
        source: MapEventSource.secondaryTap,
      ),
    );
  }

  void handleLongPress(TapPosition position) {
    _resetDoubleTapHold();

    closeFlingAnimationController(MapEventSource.longPress);
    closeDoubleTapController(MapEventSource.longPress);

    final latlng = _offsetToCrs(position.relative!);
    if (options.onLongPress != null) {
      // emit the event
      options.onLongPress!(position, latlng);
    }

    mapStateContainer.emitMapEvent(
      MapEventLongPress(
        tapPosition: latlng,
        mapState: mapState,
        source: MapEventSource.longPress,
      ),
    );
  }

  LatLng _offsetToCrs(Offset offset, [double? zoom]) {
    final focalStartPt = mapState.project(
        mapStateContainer.center, zoom ?? mapStateContainer.zoom);
    final point = (_offsetToPoint(offset) - (mapState.nonrotatedSize / 2.0))
        .rotate(mapState.rotationRad);

    final newCenterPt = focalStartPt + point;
    return mapState.unproject(newCenterPt, zoom ?? mapStateContainer.zoom);
  }

  void handleDoubleTap(TapPosition tapPosition) {
    _resetDoubleTapHold();

    closeFlingAnimationController(MapEventSource.doubleTap);
    closeDoubleTapController(MapEventSource.doubleTap);

    if (InteractiveFlag.hasFlag(
        options.interactiveFlags, InteractiveFlag.doubleTapZoom)) {
      final centerZoom = _getNewEventCenterZoomPosition(
          _offsetToPoint(tapPosition.relative!),
          _getZoomForScale(mapStateContainer.zoom, 2));
      _startDoubleTapAnimation(
          centerZoom[1] as double, centerZoom[0] as LatLng);
    }
  }

  // If we double click in the corner of a map, calculate the new
  // center of the whole map after a zoom, to retain that offset position
  // so that the same event LatLng is still under the cursor.

  List<dynamic> _getNewEventCenterZoomPosition(
      CustomPoint cursorPos, double newZoom) {
    // Calculate offset of mouse cursor from viewport center
    final viewCenter = mapState.nonrotatedSize / 2;
    final offset = (cursorPos - viewCenter).rotate(mapState.rotationRad);
    // Match new center coordinate to mouse cursor position
    final scale =
        mapStateContainer.getZoomScale(newZoom, mapStateContainer.zoom);
    final newOffset = offset * (1.0 - 1.0 / scale);
    final mapCenter = mapState.project(mapStateContainer.center);
    final newCenter = mapState.unproject(mapCenter + newOffset);
    return <dynamic>[newCenter, newZoom];
  }

  void _startDoubleTapAnimation(double newZoom, LatLng newCenter) {
    _doubleTapZoomAnimation =
        Tween<double>(begin: mapStateContainer.zoom, end: newZoom)
            .chain(CurveTween(curve: Curves.linear))
            .animate(_doubleTapController);
    _doubleTapCenterAnimation =
        LatLngTween(begin: mapStateContainer.center, end: newCenter)
            .chain(CurveTween(curve: Curves.linear))
            .animate(_doubleTapController);
    _doubleTapController.forward(from: 0);
  }

  void _doubleTapZoomStatusListener(AnimationStatus status) {
    if (status == AnimationStatus.forward) {
      mapStateContainer.emitMapEvent(
        MapEventDoubleTapZoomStart(
            mapState: mapState,
            source: MapEventSource.doubleTapZoomAnimationController),
      );
      _startListeningForAnimationInterruptions();
    } else if (status == AnimationStatus.completed) {
      _stopListeningForAnimationInterruptions();
      mapStateContainer.emitMapEvent(
        MapEventDoubleTapZoomEnd(
            mapState: mapState,
            source: MapEventSource.doubleTapZoomAnimationController),
      );
    }
  }

  void _handleDoubleTapZoomAnimation() {
    mapStateContainer.move(
      _doubleTapCenterAnimation.value,
      _doubleTapZoomAnimation.value,
      hasGesture: true,
      source: MapEventSource.doubleTapZoomAnimationController,
    );
  }

  void handleOnTapUp(TapUpDetails details) {
    _doubleTapHoldMaxDelay?.cancel();

    if (++_tapUpCounter == 1) {
      _doubleTapHoldMaxDelay =
          Timer(const Duration(milliseconds: 350), _resetDoubleTapHold);
    }
  }

  void _handleDoubleTapHold(ScaleUpdateDetails details) {
    _doubleTapHoldMaxDelay?.cancel();

    final flags = options.interactiveFlags;
    if (InteractiveFlag.hasFlag(flags, InteractiveFlag.pinchZoom)) {
      final zoom = mapStateContainer.zoom;
      final focalOffset = details.localFocalPoint;
      final verticalOffset = (_focalStartLocal - focalOffset).dy;
      final newZoom = _mapZoomStart - verticalOffset / 360 * zoom;
      final min = options.minZoom ?? 0.0;
      final max = options.maxZoom ?? double.infinity;
      final actualZoom = math.max(min, math.min(max, newZoom));

      mapStateContainer.move(
        mapStateContainer.center,
        actualZoom,
        hasGesture: true,
        source: MapEventSource.doubleTapHold,
      );
    }
  }

  void _resetDoubleTapHold() {
    _doubleTapHoldMaxDelay?.cancel();
    _tapUpCounter = 0;
  }

  void _flingAnimationStatusListener(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _flingAnimationStarted = false;
      _stopListeningForAnimationInterruptions();
      mapStateContainer.emitMapEvent(
        MapEventFlingAnimationEnd(
          mapState: mapState,
          source: MapEventSource.flingAnimationController,
        ),
      );
    }
  }

  void _handleFlingAnimation() {
    if (!_flingAnimationStarted) {
      _flingAnimationStarted = true;
      mapStateContainer.emitMapEvent(
        MapEventFlingAnimationStart(
          mapState: mapState,
          source: MapEventSource.flingAnimationController,
        ),
      );
      _startListeningForAnimationInterruptions();
    }

    final newCenterPoint = mapState.project(_mapCenterStart) +
        _offsetToPoint(_flingAnimation.value).rotate(mapState.rotationRad);
    final newCenter = mapState.unproject(newCenterPoint);

    mapStateContainer.move(
      newCenter,
      mapStateContainer.zoom,
      hasGesture: true,
      source: MapEventSource.flingAnimationController,
    );
  }

  void _startListeningForAnimationInterruptions() {
    _isListeningForInterruptions = true;
  }

  void _stopListeningForAnimationInterruptions() {
    _isListeningForInterruptions = false;
  }

  void handleAnimationInterruptions(MapEvent event) {
    if (_isListeningForInterruptions == false) {
      //Do not handle animation interruptions if not listening
      return;
    }
    closeDoubleTapController(event.source);
    closeFlingAnimationController(event.source);
  }

  CustomPoint<double> _offsetToPoint(Offset offset) {
    return CustomPoint(offset.dx, offset.dy);
  }

  double _getZoomForScale(double startZoom, double scale) {
    final resultZoom =
        scale == 1.0 ? startZoom : startZoom + math.log(scale) / math.ln2;
    return mapStateContainer.fitZoomToBounds(resultZoom);
  }

  Offset _rotateOffset(Offset offset) {
    final radians = mapState.rotationRad;
    if (radians != 0.0) {
      final cos = math.cos(radians);
      final sin = math.sin(radians);
      final nx = (cos * offset.dx) + (sin * offset.dy);
      final ny = (cos * offset.dy) - (sin * offset.dx);

      return Offset(nx, ny);
    }

    return offset;
  }

  @override
  void dispose() {
    _flingController.dispose();
    _doubleTapController.dispose();
    super.dispose();
  }
}

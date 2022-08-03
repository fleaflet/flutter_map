import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/gestures/gestures.dart';
import 'package:flutter_map/src/map/map.dart';
import 'package:flutter_map/src/map/map_state_widget.dart';
import 'package:positioned_tap_detector_2/positioned_tap_detector_2.dart';

class FlutterMapState extends MapGestureMixin
    with AutomaticKeepAliveClientMixin {

  late StreamSubscription<MapEvent> _rebuildStream;

  final _positionedTapController = PositionedTapController();
  final MapController _localController = MapControllerImpl();

  @override
  MapOptions get options => widget.options;

  @override
  late final MapState mapState;

  @override
  MapController get mapController => widget.mapController ?? _localController;

  @override
  void didUpdateWidget(FlutterMap oldWidget) {
    super.didUpdateWidget(oldWidget);

    mapState.options = options;
  }

  @override
  void initState() {
    super.initState();
    mapState = MapState(options, (degree) {
      if (mounted) setState(() {});
    }, mapController.mapEventSink);
    mapController.state = mapState;

    // Whenever there is a map event (move, rotate, etc); 
    // setstate to trigger rebuilding children.
    // It should be fine to trigger setState multiple times as long
    // as it is within the same frame. (ex move and rotate events).
    _rebuildStream = mapController.mapEventStream.listen((event) {
      if(mounted) setState(() {});
    });

    // Callback onMapCreated if not null
    if (options.onMapCreated != null) {
      options.onMapCreated!(mapController);
    }
  }

  @override
  void dispose() {
    mapState.dispose();
    _localController.dispose();
    _rebuildStream.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      final hasLateSize = mapState.hasLateSize(constraints);

      mapState.setOriginalSize(constraints.maxWidth, constraints.maxHeight);

      // It's possible on first call to LayoutBuilder, it may not know a size
      // which will cause methods like fitBounds to break. These methods
      // could be called in initIfLateSize()
      if (hasLateSize) {
        mapState.initIfLateSize();
      }
      final size = mapState.size;

      final scaleGestureTeam = GestureArenaTeam();

      RawGestureDetector scaleGestureDetector({required Widget child}) =>
          RawGestureDetector(
            gestures: <Type, GestureRecognizerFactory>{
              ScaleGestureRecognizer:
                  GestureRecognizerFactoryWithHandlers<ScaleGestureRecognizer>(
                      () => ScaleGestureRecognizer(),
                      (ScaleGestureRecognizer instance) {
                scaleGestureTeam.captain = instance;
                instance.team ??= scaleGestureTeam;
                instance
                  ..onStart = handleScaleStart
                  ..onUpdate = handleScaleUpdate
                  ..onEnd = handleScaleEnd;
              }),
              VerticalDragGestureRecognizer:
                  GestureRecognizerFactoryWithHandlers<
                          VerticalDragGestureRecognizer>(
                      () => VerticalDragGestureRecognizer(),
                      (VerticalDragGestureRecognizer instance) {
                instance.team ??= scaleGestureTeam;
                // these empty lambdas are necessary to activate this gesture recognizer
                instance.onUpdate = (_) {};
              }),
              HorizontalDragGestureRecognizer:
                  GestureRecognizerFactoryWithHandlers<
                          HorizontalDragGestureRecognizer>(
                      () => HorizontalDragGestureRecognizer(),
                      (HorizontalDragGestureRecognizer instance) {
                instance.team ??= scaleGestureTeam;
                instance.onUpdate = (_) {};
              })
            },
            child: child,
          );

      return MapStateInheritedWidget(
        mapState: mapState,
        child: Listener(
          onPointerDown: onPointerDown,
          onPointerUp: onPointerUp,
          onPointerCancel: onPointerCancel,
          onPointerHover: onPointerHover,
          onPointerSignal: onPointerSignal,
          child: PositionedTapDetector2(
            controller: _positionedTapController,
            onTap: handleTap,
            onLongPress: handleLongPress,
            onDoubleTap: handleDoubleTap,
            child: options.allowPanningOnScrollingParent
                ? GestureDetector(
                    onTap: _positionedTapController.onTap,
                    onLongPress: _positionedTapController.onLongPress,
                    onTapDown: _positionedTapController.onTapDown,
                    onTapUp: handleOnTapUp,
                    child: scaleGestureDetector(child: _buildMap(size)),
                  )
                : GestureDetector(
                    onScaleStart: handleScaleStart,
                    onScaleUpdate: handleScaleUpdate,
                    onScaleEnd: handleScaleEnd,
                    onTap: _positionedTapController.onTap,
                    onLongPress: _positionedTapController.onLongPress,
                    onTapDown: _positionedTapController.onTapDown,
                    onTapUp: handleOnTapUp,
                    child: _buildMap(size)),
          ),
        ),
      );
    });
  }

  Widget _buildMap(CustomPoint<double> size) {
    return ClipRect(
      child: Stack(
        children: [
          OverflowBox(
            minWidth: size.x,
            maxWidth: size.x,
            minHeight: size.y,
            maxHeight: size.y,
            child: Transform.rotate(
              angle: mapState.rotationRad,
              child: Stack(
                children: widget.children,
              ),
            ),
          ),
          Stack(
            children: widget.nonRotatedChildren,
          ),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => options.keepAlive;
}

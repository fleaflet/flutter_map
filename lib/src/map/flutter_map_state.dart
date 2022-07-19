import 'dart:async';

import 'package:async/async.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/gestures/gestures.dart';
import 'package:flutter_map/src/map/map.dart';
import 'package:flutter_map/src/map/map_state_widget.dart';
import 'package:positioned_tap_detector_2/positioned_tap_detector_2.dart';

class FlutterMapState extends MapGestureMixin
    with AutomaticKeepAliveClientMixin {
  final List<StreamGroup<void>> groups = <StreamGroup<void>>[];
  final _positionedTapController = PositionedTapController();

  @override
  MapOptions get options => widget.options;

  @override
  late final MapState mapState;

  @override
  MapController get mapController => widget.mapController;

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

    // Callback onMapCreated if not null
    if (options.onMapCreated != null) {
      options.onMapCreated!(mapController);
    }
  }

  void _disposeStreamGroups() {
    for (final group in groups) {
      group.close();
    }

    groups.clear();
  }

  @override
  void dispose() {
    _disposeStreamGroups();
    mapState.dispose();
    mapController.dispose();

    super.dispose();
  }

  Stream<void> _merge(LayerOptions options) {
    if (options.rebuild == null) return mapState.onMoved;

    final group = StreamGroup<void>();
    group.add(mapState.onMoved);
    group.add(options.rebuild!);
    groups.add(group);
    return group.stream;
  }

  @override
  Widget build(BuildContext context) {
    _disposeStreamGroups();
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
                children: [
                  if (widget.children.isNotEmpty) ...widget.children,
                  if (widget.layers.isNotEmpty)
                    ...widget.layers.map(
                      (layer) => _createLayer(layer, options.plugins),
                    )
                ],
              ),
            ),
          ),
          Stack(
            children: [
              if (widget.nonRotatedChildren.isNotEmpty)
                ...widget.nonRotatedChildren,
              if (widget.nonRotatedLayers.isNotEmpty)
                ...widget.nonRotatedLayers.map(
                  (layer) => _createLayer(layer, options.plugins),
                )
            ],
          ),
        ],
      ),
    );
  }

  Widget _createLayer(LayerOptions options, List<MapPlugin> plugins) {
    for (final plugin in plugins) {
      if (plugin.supportsLayer(options)) {
        return plugin.createLayer(options, mapState, _merge(options));
      }
    }
    if (options is TileLayerOptions) {
      return TileLayer(
          options: options, mapState: mapState, stream: _merge(options));
    }
    if (options is MarkerLayerOptions) {
      return MarkerLayer(options, mapState, _merge(options));
    }
    if (options is PolylineLayerOptions) {
      return PolylineLayer(options, mapState, _merge(options));
    }
    if (options is PolygonLayerOptions) {
      return PolygonLayer(options, mapState, _merge(options));
    }
    if (options is CircleLayerOptions) {
      return CircleLayer(options, mapState, _merge(options));
    }
    if (options is GroupLayerOptions) {
      return GroupLayer(options, mapState, _merge(options));
    }
    if (options is OverlayImageLayerOptions) {
      return OverlayImageLayer(options, mapState, _merge(options));
    }
    throw (StateError("""
Can't find correct layer for $options. Perhaps when you create your FlutterMap you need something like this:

    options: new MapOptions(plugins: [MyFlutterMapPlugin()])"""));
  }

  @override
  bool get wantKeepAlive => options.keepAlive;
}

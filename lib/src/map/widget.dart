// ignore_for_file: deprecated_member_use_from_same_package

import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_map/src/gestures/flutter_map_interactive_viewer.dart';
import 'package:flutter_map/src/gestures/map_events.dart';
import 'package:flutter_map/src/layer/attribution_layer/rich.dart';
import 'package:flutter_map/src/layer/attribution_layer/simple.dart';
import 'package:flutter_map/src/layer/general/translucent_pointer.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_layer.dart';
import 'package:flutter_map/src/map/camera/camera.dart';
import 'package:flutter_map/src/map/camera/camera_fit.dart';
import 'package:flutter_map/src/map/inherited_model.dart';
import 'package:flutter_map/src/map/internal_controller.dart';
import 'package:flutter_map/src/map/map_controller.dart';
import 'package:flutter_map/src/map/map_controller_impl.dart';
import 'package:flutter_map/src/map/options.dart';

part '../layer/general/overlay_layer.dart';

/// Renders an interactive geographical map as a widget
///
/// See the online documentation for more information about set-up,
/// configuration, and usage.
@immutable
class FlutterMap extends StatefulWidget {
  /// Renders an interactive geographical map as a widget
  ///
  /// See the online documentation for more information about set-up,
  /// configuration, and usage.
  const FlutterMap({
    super.key,
    required this.options,
    this.children = const [],
    @Deprecated(
      'Prefer `children`. '
      'This property has been removed to simplify the way layers are used. '
      'This property is deprecated since v6.',
    )
    this.nonRotatedChildren = const [],
    this.mapController,
  });

  /// Renders a simple geographical map as a widget
  ///
  /// Has limited customization options, and lacks the ability to add feature
  /// layers. Prefer [FlutterMap]'s standard constructor if these are required.
  ///
  /// Provide a [RichAttributionWidget] or [SimpleAttributionWidget] to the
  /// [attribution] argument.
  ///
  /// See the online documentation for more information about set-up,
  /// configuration, and usage.
  FlutterMap.simple({
    super.key,
    required this.options,
    required String urlTemplate,
    required String userAgentPackageName,
    required AttributionWidget attribution,
  })  : children = [
          TileLayer(
            urlTemplate: urlTemplate,
            userAgentPackageName: userAgentPackageName,
          ),
          attribution,
        ],
        mapController = null,
        nonRotatedChildren = [];

  /// Layers/widgets to be painted onto the map, in a [Stack]-like fashion
  final List<Widget> children;

  /// Same as [children], except these are overlaid onto the map
  ///
  /// See [OverlayLayer] for information.
  @Deprecated(
    'Prefer `children`. '
    'This property has been removed to simplify the way layers are used. '
    'This property is deprecated since v6.',
  )
  final List<Widget> nonRotatedChildren;

  /// Configure this map
  final MapOptions options;

  /// Programmatically interact with this map
  final MapController? mapController;

  @override
  State<FlutterMap> createState() => FlutterMapStateContainer();
}

class FlutterMapStateContainer extends State<FlutterMap> {
  bool _initialCameraFitApplied = false;

  late final FlutterMapInternalController _flutterMapInternalController;
  late MapControllerImpl _mapController;
  late bool _mapControllerCreatedInternally;

  @override
  void initState() {
    super.initState();
    _flutterMapInternalController =
        FlutterMapInternalController(widget.options);
    _initializeAndLinkMapController();

    WidgetsBinding.instance
        .addPostFrameCallback((_) => widget.options.onMapReady?.call());
  }

  @override
  void didUpdateWidget(FlutterMap oldWidget) {
    if (oldWidget.options != widget.options) {
      _flutterMapInternalController.setOptions(widget.options);
    }
    if (oldWidget.mapController != widget.mapController) {
      _initializeAndLinkMapController();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    if (_mapControllerCreatedInternally) _mapController.dispose();
    _flutterMapInternalController.dispose();
    super.dispose();
  }

  void _initializeAndLinkMapController() {
    _mapController =
        (widget.mapController ?? MapController()) as MapControllerImpl;
    _mapControllerCreatedInternally = widget.mapController == null;
    _flutterMapInternalController.linkMapController(_mapController);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _updateAndEmitSizeIfConstraintsChanged(constraints);
        _applyInitialCameraFit(constraints);

        return FlutterMapInteractiveViewer(
          controller: _flutterMapInternalController,
          builder: (context, options, camera) => FlutterMapInheritedModel(
            controller: _mapController,
            options: options,
            camera: camera,
            child: ClipRect(
              child: ColoredBox(
                color: options.backgroundColor,
                child: _LayersStack(
                  camera: camera,
                  options: options,
                  children: widget.children..addAll(widget.nonRotatedChildren),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _applyInitialCameraFit(BoxConstraints constraints) {
    // If an initial camera fit was provided apply it to the map state once the
    // the parent constraints are available.

    if (!_initialCameraFitApplied &&
        (widget.options.bounds != null ||
            widget.options.initialCameraFit != null) &&
        _parentConstraintsAreSet(context, constraints)) {
      _initialCameraFitApplied = true;

      final CameraFit cameraFit;

      if (widget.options.bounds != null) {
        // Create the camera fit from the deprecated option.
        final fitBoundsOptions = widget.options.boundsOptions;
        cameraFit = fitBoundsOptions.inside
            ? CameraFit.insideBounds(
                bounds: widget.options.bounds!,
                padding: fitBoundsOptions.padding,
                maxZoom: fitBoundsOptions.maxZoom,
                forceIntegerZoomLevel: fitBoundsOptions.forceIntegerZoomLevel,
              )
            : CameraFit.bounds(
                bounds: widget.options.bounds!,
                padding: fitBoundsOptions.padding,
                maxZoom: fitBoundsOptions.maxZoom,
                forceIntegerZoomLevel: fitBoundsOptions.forceIntegerZoomLevel,
              );
      } else {
        cameraFit = widget.options.initialCameraFit!;
      }

      _flutterMapInternalController.fitCamera(
        cameraFit,
        offset: Offset.zero,
      );
    }
  }

  void _updateAndEmitSizeIfConstraintsChanged(BoxConstraints constraints) {
    final nonRotatedSize = Point<double>(
      constraints.maxWidth,
      constraints.maxHeight,
    );
    final oldCamera = _flutterMapInternalController.camera;
    if (_flutterMapInternalController
        .setNonRotatedSizeWithoutEmittingEvent(nonRotatedSize)) {
      final newMapCamera = _flutterMapInternalController.camera;

      // Avoid emitting the event during build otherwise if the user calls
      // setState in the onMapEvent callback it will throw.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _flutterMapInternalController.nonRotatedSizeChange(
            MapEventSource.nonRotatedSizeChange,
            oldCamera,
            newMapCamera,
          );
        }
      });
    }
  }

  /// During Flutter startup the native platform resolution is not immediately
  /// available which can cause constraints to be zero before they are updated
  /// in a subsequent build to the actual constraints. This check allows us to
  /// differentiate zero constraints caused by missing platform resolution vs
  /// zero constraints which were actually provided by the parent widget.
  bool _parentConstraintsAreSet(
          BuildContext context, BoxConstraints constraints) =>
      constraints.maxWidth != 0 || MediaQuery.sizeOf(context) != Size.zero;
}

class _LayersStack extends StatefulWidget {
  const _LayersStack({
    required this.camera,
    required this.options,
    required this.children,
  });

  final MapCamera camera;
  final MapOptions options;
  final List<Widget> children;

  @override
  State<_LayersStack> createState() => _LayersStackState();
}

class _LayersStackState extends State<_LayersStack> {
  List<Widget> children = [];

  Iterable<Widget> _prepareChildren() sync* {
    final stackChildren = <Widget>[];

    Widget prepareRotateStack() {
      final box = OverflowBox(
        minWidth: widget.camera.size.x,
        maxWidth: widget.camera.size.x,
        minHeight: widget.camera.size.y,
        maxHeight: widget.camera.size.y,
        child: Transform.rotate(
          angle: widget.camera.rotationRad,
          child: Stack(children: List.from(stackChildren)),
        ),
      );
      stackChildren.clear();
      return box;
    }

    for (final Widget child in widget.children) {
      if (child is OverlayLayerStatefulMixin ||
          child is OverlayLayerStatelessMixin) {
        if (stackChildren.isNotEmpty) yield prepareRotateStack();
        final overlayChild = _OverlayLayerDetectorAncestor(child: child);
        yield widget.options.applyPointerTranslucencyToLayers
            ? TranslucentPointer(child: overlayChild)
            : overlayChild;
      } else {
        stackChildren.add(
          widget.options.applyPointerTranslucencyToLayers
              ? TranslucentPointer(child: child)
              : child,
        );
      }
    }
    if (stackChildren.isNotEmpty) yield prepareRotateStack();
  }

  @override
  void initState() {
    super.initState();
    children = _prepareChildren().toList();
  }

  @override
  void didUpdateWidget(covariant _LayersStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.children != oldWidget.children ||
        widget.camera != oldWidget.camera ||
        widget.options.applyPointerTranslucencyToLayers !=
            oldWidget.options.applyPointerTranslucencyToLayers) {
      children = _prepareChildren().toList();
    }
  }

  @override
  Widget build(BuildContext context) => Stack(children: children);
}

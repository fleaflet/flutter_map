import 'package:flutter/widgets.dart';
import 'package:flutter_map/src/gestures/flutter_map_interactive_viewer.dart';
import 'package:flutter_map/src/gestures/map_events.dart';
import 'package:flutter_map/src/map/inherited_model.dart';
import 'package:flutter_map/src/map/internal_controller.dart';
import 'package:flutter_map/src/map/map_controller.dart';
import 'package:flutter_map/src/map/map_controller_impl.dart';
import 'package:flutter_map/src/map/options.dart';
import 'package:flutter_map/src/misc/camera_fit.dart';
import 'package:flutter_map/src/misc/point.dart';

/// Renders an interactive geographical map as a widget
///
/// See the online documentation for more information about set-up,
/// configuration, and usage.
class FlutterMap extends StatefulWidget {
  /// Renders an interactive geographical map as a widget
  ///
  /// See the online documentation for more information about set-up,
  /// configuration, and usage.
  const FlutterMap({
    super.key,
    required this.options,
    this.children = const [],
    this.nonRotatedChildren = const [],
    this.mapController,
  });

  /// Layers/widgets to be painted onto the map, in a [Stack]-like fashion
  final List<Widget> children;

  /// Same as [children], except these are unnaffected by map rotation
  final List<Widget> nonRotatedChildren;

  /// Configure this map
  final MapOptions options;

  /// Programatically interact with this map
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
      builder: (BuildContext context, BoxConstraints constraints) {
        _updateAndEmitSizeIfConstraintsChanged(constraints);
        _applyInitialCameraFit(constraints);

        return FlutterMapInteractiveViewer(
          controller: _flutterMapInternalController,
          builder: (context, options, camera) => FlutterMapInheritedModel(
            controller: _mapController,
            options: options,
            camera: camera,
            child: ClipRect(
              child: Stack(
                children: [
                  OverflowBox(
                    minWidth: camera.size.x,
                    maxWidth: camera.size.x,
                    minHeight: camera.size.y,
                    maxHeight: camera.size.y,
                    child: Transform.rotate(
                      angle: camera.rotationRad,
                      child: Stack(children: widget.children),
                    ),
                  ),
                  ...widget.nonRotatedChildren,
                ],
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
        cameraFit = CameraFit.bounds(
          bounds: widget.options.bounds!,
          padding: fitBoundsOptions.padding,
          maxZoom: fitBoundsOptions.maxZoom,
          inside: fitBoundsOptions.inside,
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
    final nonRotatedSize = CustomPoint<double>(
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

  // During Flutter startup the native platform resolution is not immediately
  // available which can cause constraints to be zero before they are updated
  // in a subsequent build to the actual constraints. This check allows us to
  // differentiate zero constraints caused by missing platform resolution vs
  // zero constraints which were actually provided by the parent widget.
  bool _parentConstraintsAreSet(
          BuildContext context, BoxConstraints constraints) =>
      constraints.maxWidth != 0 || MediaQuery.sizeOf(context) != Size.zero;
}

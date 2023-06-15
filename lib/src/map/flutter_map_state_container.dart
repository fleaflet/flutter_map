import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/gestures/flutter_map_interactive_viewer.dart';
import 'package:flutter_map/src/map/flutter_map_inherited_model.dart';
import 'package:flutter_map/src/map/flutter_map_internal_controller.dart';
import 'package:flutter_map/src/map/map_controller_impl.dart';

class FlutterMapStateContainer extends State<FlutterMap> {
  bool _initialFrameFitApplied = false;

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
    _flutterMapInternalController.setOptions(widget.options);
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
        _applyInitialFrameFit(constraints);

        return FlutterMapInteractiveViewer(
          controller: _flutterMapInternalController,
          builder: (context, mapState) => FlutterMapInheritedModel(
            controller: _mapController,
            options: mapState.options,
            frame: mapState.mapFrame,
            child: ClipRect(
              child: Stack(
                children: [
                  OverflowBox(
                    minWidth: mapState.mapFrame.size.x,
                    maxWidth: mapState.mapFrame.size.x,
                    minHeight: mapState.mapFrame.size.y,
                    maxHeight: mapState.mapFrame.size.y,
                    child: Transform.rotate(
                      angle: mapState.mapFrame.rotationRad,
                      child: Stack(children: widget.children),
                    ),
                  ),
                  Stack(children: widget.nonRotatedChildren),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _applyInitialFrameFit(BoxConstraints constraints) {
    // If an initial frame fit was provided apply it to the map state once the
    // the parent constraints are available.

    if (!_initialFrameFitApplied &&
        (widget.options.bounds != null ||
            widget.options.initialFrameFit != null) &&
        _parentConstraintsAreSet(context, constraints)) {
      _initialFrameFitApplied = true;

      final FrameFit frameFit;

      if (widget.options.bounds != null) {
        // Create the frame fit from the deprecated option.
        final fitBoundsOptions = widget.options.boundsOptions;
        frameFit = FrameFit.bounds(
          bounds: widget.options.bounds!,
          padding: fitBoundsOptions.padding,
          maxZoom: fitBoundsOptions.maxZoom,
          inside: fitBoundsOptions.inside,
          forceIntegerZoomLevel: fitBoundsOptions.forceIntegerZoomLevel,
        );
      } else {
        frameFit = widget.options.initialFrameFit!;
      }

      _flutterMapInternalController.fitFrame(
        frameFit,
        offset: Offset.zero,
      );
    }
  }

  void _updateAndEmitSizeIfConstraintsChanged(BoxConstraints constraints) {
    final nonRotatedSize = CustomPoint<double>(
      constraints.maxWidth,
      constraints.maxHeight,
    );
    final oldMapFrame = _flutterMapInternalController.mapFrame;
    if (_flutterMapInternalController
        .setNonRotatedSizeWithoutEmittingEvent(nonRotatedSize)) {
      final newMapFrame = _flutterMapInternalController.mapFrame;

      // Avoid emitting the event during build otherwise if the user calls
      // setState in the onMapEvent callback it will throw.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _flutterMapInternalController.nonRotatedSizeChange(
            MapEventSource.nonRotatedSizeChange,
            oldMapFrame,
            newMapFrame,
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

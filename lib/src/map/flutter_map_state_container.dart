import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/gestures/flutter_map_interactive_viewer.dart';
import 'package:flutter_map/src/gestures/flutter_map_state_controller.dart';
import 'package:flutter_map/src/map/flutter_map_state_inherited_widget.dart';
import 'package:flutter_map/src/map/map_controller_impl.dart';

class FlutterMapStateContainer extends State<FlutterMap> {
  bool _hasFitInitialBounds = false;

  late final FlutterMapStateController _flutterMapStateController;
  late MapControllerImpl _mapController;
  late bool _mapControllerCreatedInternally;

  @override
  void initState() {
    super.initState();
    _flutterMapStateController = FlutterMapStateController(widget.options);
    _initializeAndLinkMapController();

    WidgetsBinding.instance
        .addPostFrameCallback((_) => widget.options.onMapReady?.call());
  }

  @override
  void didUpdateWidget(FlutterMap oldWidget) {
    _flutterMapStateController.setOptions(widget.options);
    if (oldWidget.mapController != widget.mapController) {
      _initializeAndLinkMapController();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    if (_mapControllerCreatedInternally) _mapController.dispose();
    _flutterMapStateController.dispose();
    super.dispose();
  }

  void _initializeAndLinkMapController() {
    _mapController =
        (widget.mapController ?? MapController()) as MapControllerImpl;
    _mapControllerCreatedInternally = widget.mapController == null;
    _flutterMapStateController.linkMapController(_mapController);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        _updateAndEmitSizeIfConstraintsChanged(constraints);
        _setInitialFitBounds(constraints);

        return FlutterMapInteractiveViewer(
          controller: _flutterMapStateController,
          options: widget.options,
          builder: (context, mapState) => MapStateInheritedWidget(
            mapController: _mapController,
            mapState: mapState,
            child: ClipRect(
              child: Stack(
                children: [
                  OverflowBox(
                    minWidth: mapState.size.x,
                    maxWidth: mapState.size.x,
                    minHeight: mapState.size.y,
                    maxHeight: mapState.size.y,
                    child: Transform.rotate(
                      angle: mapState.rotationRad,
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

  void _setInitialFitBounds(BoxConstraints constraints) {
    // If bounds were provided set the initial center/zoom to match those
    // bounds once the parent constraints are available.
    if (widget.options.bounds != null &&
        !_hasFitInitialBounds &&
        _parentConstraintsAreSet(context, constraints)) {
      _hasFitInitialBounds = true;

      _flutterMapStateController.fitBounds(
        widget.options.bounds!,
        widget.options.boundsOptions,
        offset: Offset.zero,
      );
    }
  }

  void _updateAndEmitSizeIfConstraintsChanged(BoxConstraints constraints) {
    final nonRotatedSize = CustomPoint<double>(
      constraints.maxWidth,
      constraints.maxHeight,
    );
    final oldMapState = _flutterMapStateController.value;
    if (_flutterMapStateController
        .setNonRotatedSizeWithoutEmittingEvent(nonRotatedSize)) {
      final newMapState = _flutterMapStateController.value;

      // Avoid emitting the event during build otherwise if the user calls
      // setState in the onMapEvent callback it will throw.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _flutterMapStateController.nonRotatedSizeChange(
            MapEventSource.nonRotatedSizeChange,
            oldMapState,
            newMapState,
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

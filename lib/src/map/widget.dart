import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/gestures/map_interactive_viewer.dart';
import 'package:flutter_map/src/map/inherited_model.dart';

/// An interactive geographical map
///
/// See the online documentation for more information about set-up,
/// configuration, and usage.
@immutable
class FlutterMap extends StatefulWidget {
  /// Creates an interactive geographical map
  ///
  /// See the properties and online documentation for more information about
  /// set-up, configuration, and usage.
  const FlutterMap({
    super.key,
    this.mapController,
    this.options = const MapOptions(),
    required this.children,
  });

  /// Widgets to be placed onto the map in a [Stack]-like fashion
  ///
  /// Widgets that use [MobileLayerTransformer] will be 'mobile', will move and
  /// rotate with the map. Other widgets will be 'static' (and should usually use
  /// [Align] or another method to position themselves). Widgets/layers may or
  /// may not identify which type they are in their documentation, but it should
  /// be relatively self-explanatory from their purpose.
  final List<Widget> children;

  /// Configure this map's permanent rules and initial state
  ///
  /// See the online documentation for more information.
  final MapOptions options;

  /// Programmatically interact with this map
  ///
  /// See the online documentation for more information.
  final MapController? mapController;

  @override
  State<FlutterMap> createState() => _FlutterMapStateContainer();
}

class _FlutterMapStateContainer extends State<FlutterMap>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  bool _initialCameraFitApplied = false;
  bool _mapReadyScheduled = false;

  late MapControllerImpl _mapController;

  bool get _controllerCreatedInternally => widget.mapController == null;

  @override
  void initState() {
    super.initState();
    _setMapController();
  }

  @override
  void didUpdateWidget(FlutterMap oldWidget) {
    if (oldWidget.mapController != widget.mapController) {
      _setMapController();
    }
    if (oldWidget.options != widget.options) {
      _mapController.options = widget.options;
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    if (_controllerCreatedInternally) _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final backgroundColor = widget.options.backgroundColor;

    final widgets = ClipRect(
      child: Stack(
        children: [
          Positioned.fill(child: ColoredBox(color: backgroundColor)),
          if (widget.options.backgroundGridOptions case final options?
              when backgroundColor.a != 0)
            Positioned.fill(child: PlaceholderGridLayer(gridOptions: options)),
          ...widget.children,
        ],
      ),
    );

    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) {
          _scheduleMapReady();
          _updateAndEmitSizeIfConstraintsChanged(constraints);

          return MapInteractiveViewer(
            controller: _mapController,
            builder: (context, options, camera) {
              return MapInheritedModel(
                controller: _mapController,
                options: options,
                camera: camera,
                child: widgets,
              );
            },
          );
        },
      ),
    );
  }

  void _applyInitialCameraFit(BoxConstraints constraints) {
    // If an initial camera fit was provided apply it to the map state once the
    // the parent constraints are available.

    if (!_initialCameraFitApplied &&
        widget.options.initialCameraFit != null &&
        _parentConstraintsAreSet(context, constraints) &&
        // `_parentConstraintsAreSet` can return true while `constraints` is
        // still zero-sized (e.g. on the first build of a not-yet-measured
        // parent, while `MediaQuery` already reports a non-zero screen
        // size). Fitting against a zero size produces a degenerate camera,
        // so wait for a real, non-zero size instead of latching
        // `_initialCameraFitApplied` against it.
        constraints.maxWidth > 0 &&
        constraints.maxHeight > 0) {
      _initialCameraFitApplied = true;

      _mapController.fitCamera(widget.options.initialCameraFit!);
    }
  }

  /// Schedules [MapOptions.onMapReady] for the end of the frame in which the
  /// map is first laid out.
  ///
  /// The [MapInteractiveViewer], which the controller needs for camera
  /// movements, is created during layout. A map that is built but not laid
  /// out - for example on a route that another opaque route covers from the
  /// first frame - has no viewer yet, so the map is only ready once it is laid
  /// out.
  ///
  /// Called before [_updateAndEmitSizeIfConstraintsChanged], so `onMapReady`
  /// keeps running before the first size change event and the initial camera
  /// fit.
  void _scheduleMapReady() {
    if (_mapReadyScheduled) return;
    _mapReadyScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.options.onMapReady?.call();
    });
  }

  void _updateAndEmitSizeIfConstraintsChanged(BoxConstraints constraints) {
    final nonRotatedSize = Size(constraints.maxWidth, constraints.maxHeight);
    final oldCamera = _mapController.camera;
    if (_mapController.setNonRotatedSizeWithoutEmittingEvent(nonRotatedSize)) {
      final newMapCamera = _mapController.camera;

      // Avoid emitting the event during build otherwise if the user calls
      // setState in the onMapEvent callback it will throw.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _mapController.nonRotatedSizeChange(
            MapEventSource.nonRotatedSizeChange,
            oldCamera,
            newMapCamera,
          );

          _applyInitialCameraFit(constraints);
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
    BuildContext context,
    BoxConstraints constraints,
  ) => constraints.maxWidth != 0 || MediaQuery.sizeOf(context) != Size.zero;

  @override
  bool get wantKeepAlive => widget.options.keepAlive;

  void _setMapController() {
    if (_controllerCreatedInternally) {
      _mapController = MapControllerImpl(options: widget.options, vsync: this);
    } else {
      _mapController = widget.mapController! as MapControllerImpl;
      _mapController.vsync = this;
      _mapController.options = widget.options;
    }
  }
}

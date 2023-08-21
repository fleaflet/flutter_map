import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_map/src/gestures/flutter_map_interactive_viewer.dart';
import 'package:flutter_map/src/gestures/map_events.dart';
import 'package:flutter_map/src/layer/attribution_layer/shared.dart';
import 'package:flutter_map/src/layer/general/translucent_pointer.dart';
import 'package:flutter_map/src/layer/overlay_image_layer.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_layer.dart';
import 'package:flutter_map/src/map/camera/camera.dart';
import 'package:flutter_map/src/map/camera/camera_fit.dart';
import 'package:flutter_map/src/map/controller/impl.dart';
import 'package:flutter_map/src/map/controller/internal.dart';
import 'package:flutter_map/src/map/controller/map_controller.dart';
import 'package:flutter_map/src/map/inherited_model.dart';
import 'package:flutter_map/src/map/options.dart';

part '../layer/general/anchored_layer.dart';
part 'layers_stack.dart';

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
    required this.options,
    required this.children,
    this.overlaidAnchoredChildren = const [],
  });

  /// Creates an interactive geographical map
  ///
  /// This constructor is a shortcut intended for only the most simple of maps.
  /// It does not support customization of the underlying [TileLayer], and lacks
  /// the ability to add feature layers (except for an attribution layer) or
  /// attach a [MapController]. Use the standard constructor if these are
  /// required.
  ///
  /// See the properties and online documentation for more information about
  /// set-up, configuration, and usage.
  ///
  /// ---
  ///
  /// Provide a standard slippy map URL template to the [urlTemplate] argument,
  /// with `{x}`, `{y}`, and `{z}` placeholders. Subdomain support is not
  /// supported through this simple constructor.
  ///
  /// Provide the application's correct package name, such as 'com.example.app',
  /// to the [userAgentPackageName] argument, to allow the tile server to
  /// identify your application. For more information, see
  /// [TileLayer.tileProvider]'s documentation.
  ///
  /// It is recommended to provide a [RichAttributionWidget] or
  /// [SimpleAttributionWidget] to the [attribution] argument. For more
  /// information, see their documentation.
  FlutterMap.simple({
    super.key,
    required this.options,
    required String urlTemplate,
    required String userAgentPackageName,
    AttributionWidget? attribution,
  })  : children = [
          TileLayer(
            urlTemplate: urlTemplate,
            userAgentPackageName: userAgentPackageName,
          ),
          if (attribution != null) attribution,
        ],
        mapController = null,
        overlaidAnchoredChildren = [];

  /// Layer widgets to be placed onto the map in a [Stack]-like fashion
  ///
  /// These may be any widgets, be that prebuilt layers, [AnchoredLayer]s, or
  /// custom widgets.
  ///
  /// ---
  ///
  /// Note that using [AnchoredLayer]s at the end of this list is equivalent to
  /// using them in [overlaidAnchoredChildren] instead.
  ///
  /// When inserting [AnchoredLayer]s inbetween children (ie. not at the end),
  /// there is likely to be a very small performance penalty.
  ///
  /// {@macro anchored_layer_warning}
  final List<Widget> children;

  /// Same as [children], except these are [AnchoredLayer]s only
  ///
  /// These may be any widgets, be that prebuilt layers or custom widgets, but
  /// they must also be [AnchoredLayer]s by way of mixin or being wrapped in an
  /// [AnchoredLayer].
  ///
  /// These are overlaid above all normal [children] layers in the order of
  /// specification. To use an [AnchoredLayer] in a non-overlaid position
  /// instead, insert it directly into [children].
  ///
  /// See [AnchoredLayer] for more information.
  ///
  /// Not to be confused with [OverlayImageLayer].
  ///
  /// ---
  ///
  /// {@macro anchored_layer_warning}
  final List<AnchoredLayer> overlaidAnchoredChildren;

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

class _FlutterMapStateContainer extends State<FlutterMap> {
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
                  children: widget.children
                    ..addAll(widget.overlaidAnchoredChildren),
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

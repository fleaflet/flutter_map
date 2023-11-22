import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/src/gestures/flutter_map_interactive_viewer.dart';
import 'package:flutter_map/src/gestures/map_events.dart';
import 'package:flutter_map/src/layer/general/mobile_layer_transformer.dart';
import 'package:flutter_map/src/layer/general/translucent_pointer.dart';
import 'package:flutter_map/src/map/controller/impl.dart';
import 'package:flutter_map/src/map/controller/internal.dart';
import 'package:flutter_map/src/map/controller/map_controller.dart';
import 'package:flutter_map/src/map/inherited_model.dart';
import 'package:flutter_map/src/map/options/options.dart';
import 'package:logger/logger.dart';

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
  });

  /// Widgets to be placed onto the map in a [Stack]-like fashion
  ///
  /// Widgets that use [MobileLayerTransformer] will be 'mobile', will move and
  /// rotate with the map. Other widgets will be 'static' (and should usually use
  /// [Align] or another method to position themselves). Widgets/layers may or
  /// may not identify which type they are in their documentation, but it should
  /// be relatively self-explanatory from their purpose.
  ///
  /// [TranslucentPointer] will be wrapped around each child by default, unless
  /// [MapOptions.applyPointerTranslucencyToLayers] is `false`.
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
    with AutomaticKeepAliveClientMixin {
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

    if (kDebugMode && kIsWeb && !isCanvasKit) {
      Logger(printer: PrettyPrinter(methodCount: 0)).w(
        '\x1B[1m\x1B[3mflutter_map\x1B[0m\nAvoid using HTML rendering on the web '
        'platform. Prefer CanvasKit.\nSee '
        'https://docs.fleaflet.dev/getting-started/installation#web for more '
        'info.',
      );
    }
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
    super.build(context);

    final widgets = ClipRect(
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: ColoredBox(color: widget.options.backgroundColor),
          ),
          ...widget.children.map(
            (child) => TranslucentPointer(
              translucent: widget.options.applyPointerTranslucencyToLayers,
              child: child,
            ),
          ),
        ],
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        _updateAndEmitSizeIfConstraintsChanged(constraints);

        return FlutterMapInteractiveViewer(
          controller: _flutterMapInternalController,
          builder: (context, options, camera) {
            return FlutterMapInheritedModel(
              controller: _mapController,
              options: options,
              camera: camera,
              child: widgets,
            );
          },
        );
      },
    );
  }

  void _applyInitialCameraFit(BoxConstraints constraints) {
    // If an initial camera fit was provided apply it to the map state once the
    // the parent constraints are available.

    if (!_initialCameraFitApplied &&
        widget.options.initialCameraFit != null &&
        _parentConstraintsAreSet(context, constraints)) {
      _initialCameraFitApplied = true;

      _flutterMapInternalController.fitCamera(
        widget.options.initialCameraFit!,
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
          BuildContext context, BoxConstraints constraints) =>
      constraints.maxWidth != 0 || MediaQuery.sizeOf(context) != Size.zero;

  @override
  bool get wantKeepAlive => widget.options.keepAlive;
}

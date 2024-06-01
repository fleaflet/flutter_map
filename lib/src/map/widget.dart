import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/gestures/map_interactive_viewer.dart';
import 'package:flutter_map/src/map/inherited_model.dart';
import 'package:latlong2/latlong.dart';
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
    this.options =
        const MapOptions(initialCenter: LatLng(0, 0), initialZoom: 0),
    required this.children,
    this.awaitingConstraintsChild,
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

  /// Widget to display whilst waiting for Flutter to return valid platform
  /// size constraints
  ///
  /// During Flutter startup the native platform resolution is not immediately
  /// available (https://github.com/flutter/flutter/issues/25827), which can
  /// cause constraints to be zero before they are updated in a subsequent build
  /// to the actual constraints.
  ///
  /// Because the constraints are heavily relied on to provide an accurate
  /// [MapCamera], particularly when using [MapOptions.initialCameraFit], this
  /// widget is displayed until they become available. The map internals and
  /// [MapController] are only setup after constraints are available, which then
  /// allows the map to be displayed.
  ///
  /// This behaviour may not be apparent in debug mode, but is very likely to
  /// occur in release and profile modes, where the Flutter engine may start the
  /// app before the platform constraints are available.
  ///
  /// This widget may be shown for any length of time: it may also not be shown
  /// at all if the platform size constraints are already available when the
  /// map is first built (such as if it is not visible on startup).
  ///
  /// It is not safe to use any of the 3 inherited state aspects (eg.
  /// [MapController] & [MapCamera]).
  ///
  /// By default, a plain background of color [MapOptions.backgroundColor] is
  /// shown.
  final Widget? awaitingConstraintsChild;

  @override
  State<FlutterMap> createState() => _FlutterMapStateContainer();
}

class _FlutterMapStateContainer extends State<FlutterMap>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  bool _hasPerformedInitialSetup = false;

  late MapControllerImpl _mapController;
  late final _controllerCreatedInternally = widget.mapController == null;

  late final _child = MapInteractiveViewer(
    controller: _mapController,
    builder: (context, options, camera) {
      return MapInheritedModel(
        controller: _mapController,
        options: options,
        camera: camera,
        child: ClipRect(
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: ColoredBox(color: widget.options.backgroundColor),
              ),
              // ignore: deprecated_member_use_from_same_package
              ...widget.options.applyPointerTranslucencyToLayers
                  ? widget.children
                      .map((child) => TranslucentPointer(child: child))
                  : widget.children,
            ],
          ),
        ),
      );
    },
  );

  @override
  void initState() {
    super.initState();

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
    super.didUpdateWidget(oldWidget);

    if (oldWidget.mapController != widget.mapController) {
      _setMapController();
    }
    if (oldWidget.options != widget.options) {
      _mapController.options = widget.options;
    }
  }

  @override
  void dispose() {
    if (_controllerCreatedInternally) _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth <= 0 &&
              MediaQuery.sizeOf(context) == Size.zero) {
            return widget.awaitingConstraintsChild ??
                ColoredBox(color: widget.options.backgroundColor);
          }

          if (!_hasPerformedInitialSetup) _setMapController();

          _mapController.setNonRotatedSizeWithoutEmittingEvent(
            Point(
              constraints.maxWidth,
              constraints.maxHeight,
            ),
          );

          if (!_hasPerformedInitialSetup) {
            _performInitialCameraSetup();
            _hasPerformedInitialSetup = true;
          }

          return _child;
        },
      ),
    );
  }

  void _setMapController() {
    if (_controllerCreatedInternally) {
      _mapController = MapControllerImpl(options: widget.options, vsync: this);
    } else {
      _mapController = widget.mapController! as MapControllerImpl;
      _mapController.vsync = this;
      _mapController.options = widget.options;
    }

    if (!_hasPerformedInitialSetup) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => widget.options.onMapReady?.call());
    }
  }

  void _performInitialCameraSetup() {
    if (widget.options.initialCameraFit != null) {
      final fitted = widget.options.initialCameraFit!.fit(
        // At this point, the camera is at (0, 0, 0), but the rotation & size are
        // accurate, which are the only things that matter
        _mapController.camera,
      );

      _mapController.moveRaw(
        fitted.center,
        fitted.zoom,
        hasGesture: false,
        source: MapEventSource.initialCameraSetup,
      );
    } else {
      _mapController.moveRaw(
        widget.options.initialCenter!,
        widget.options.initialZoom!,
        hasGesture: false,
        source: MapEventSource.initialCameraSetup,
      );
    }
  }

  @override
  bool get wantKeepAlive => widget.options.keepAlive;
}

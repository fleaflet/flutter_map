import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/src/geo/crs.dart';
import 'package:flutter_map/src/geo/latlng_bounds.dart';
import 'package:flutter_map/src/gestures/interactive_flag.dart';
import 'package:flutter_map/src/gestures/map_events.dart';
import 'package:flutter_map/src/gestures/multi_finger_gesture.dart';
import 'package:flutter_map/src/gestures/positioned_tap_detector_2.dart';
import 'package:flutter_map/src/map/camera/camera_constraint.dart';
import 'package:flutter_map/src/map/camera/camera_fit.dart';
import 'package:flutter_map/src/map/inherited_model.dart';
import 'package:flutter_map/src/map/options/interaction.dart';
import 'package:flutter_map/src/misc/fit_bounds_options.dart';
import 'package:flutter_map/src/misc/position.dart';
import 'package:latlong2/latlong.dart';

typedef MapEventCallback = void Function(MapEvent);

typedef TapCallback = void Function(TapPosition tapPosition, LatLng point);
typedef LongPressCallback = void Function(
  TapPosition tapPosition,
  LatLng point,
);
typedef PointerDownCallback = void Function(
  PointerDownEvent event,
  LatLng point,
);
typedef PointerUpCallback = void Function(PointerUpEvent event, LatLng point);
typedef PointerCancelCallback = void Function(
  PointerCancelEvent event,
  LatLng point,
);
typedef PointerHoverCallback = void Function(
  PointerHoverEvent event,
  LatLng point,
);

@immutable
class MapOptions {
  /// The Coordinate Reference System, defaults to [Epsg3857].
  final Crs crs;

  /// The center when the map is first loaded. If [initialCameraFit] is defined
  /// this has no effect.
  final LatLng initialCenter;

  /// The zoom when the map is first loaded. If [initialCameraFit] is defined
  /// this has no effect.
  final double initialZoom;

  /// The rotation when the map is first loaded.
  final double initialRotation;

  /// Defines the visible bounds when the map is first loaded. Takes precedence
  /// over [initialCenter]/[initialZoom].
  final CameraFit? initialCameraFit;

  final LatLngBounds? bounds;
  final FitBoundsOptions boundsOptions;

  final bool? _debugMultiFingerGestureWinner;
  final bool? _enableMultiFingerGestureRace;
  final double? _rotationThreshold;
  final int? _rotationWinGestures;
  final double? _pinchZoomThreshold;
  final int? _pinchZoomWinGestures;
  final double? _pinchMoveThreshold;
  final int? _pinchMoveWinGestures;
  final bool? _enableScrollWheel;
  final double? _scrollWheelVelocity;

  final double? minZoom;
  final double? maxZoom;

  final Color backgroundColor;

  /// see [InteractiveFlag] for custom settings
  final int? _interactiveFlags;

  final TapCallback? onTap;
  final TapCallback? onSecondaryTap;
  final LongPressCallback? onLongPress;
  final PointerDownCallback? onPointerDown;
  final PointerUpCallback? onPointerUp;
  final PointerCancelCallback? onPointerCancel;
  final PointerHoverCallback? onPointerHover;
  final PositionCallback? onPositionChanged;
  final MapEventCallback? onMapEvent;

  /// Define limits for viewing the map.
  final CameraConstraint? _cameraConstraint;

  /// OnMapReady is called after the map runs it's initState.
  /// At that point the map has assigned its state to the controller
  /// Only use this if your map isn't built immediately (like inside FutureBuilder)
  /// and you need to access the controller as soon as the map is built.
  /// Otherwise you can use WidgetsBinding.instance.addPostFrameCallback
  /// In initState to controll the map before the next frame.
  final void Function()? onMapReady;

  final LatLngBounds? maxBounds;

  /// Flag to enable the built in keep alive functionality
  ///
  /// If the map is within a complex layout, such as a [ListView] or [PageView],
  /// the map will reset to it's inital position after it appears back into view.
  /// To ensure this doesn't happen, enable this flag to prevent the [FlutterMap]
  /// widget from rebuilding.
  final bool keepAlive;

  final InteractionOptions? _interactionOptions;

  const MapOptions({
    this.crs = const Epsg3857(),
    @Deprecated(
      'Prefer `initialCenter` instead. '
      'This option has been renamed to clarify its meaning. '
      'This option is deprecated since v6.',
    )
    LatLng? center,
    LatLng initialCenter = const LatLng(50.5, 30.51),
    @Deprecated(
      'Prefer `initialZoom` instead. '
      'This option has been renamed to clarify its meaning. '
      'This option is deprecated since v6.',
    )
    double? zoom,
    double initialZoom = 13.0,
    @Deprecated(
      'Prefer `initialRotation` instead. '
      'This option has been renamed to clarify its meaning. '
      'This option is deprecated since v6.',
    )
    double? rotation,
    double initialRotation = 0.0,
    @Deprecated(
      'Prefer `initialCameraFit` instead. '
      'This option is now part of `initalCameraFit`. '
      'This option is deprecated since v6.',
    )
    this.bounds,
    @Deprecated(
      'Prefer `initialCameraFit` instead. '
      'This option is now part of `initalCameraFit`. '
      'This option is deprecated since v6.',
    )
    this.boundsOptions = const FitBoundsOptions(),
    this.initialCameraFit,
    CameraConstraint? cameraConstraint,
    InteractionOptions? interactionOptions,
    @Deprecated(
      'Prefer setting this in `interactionOptions`. '
      'This option is now part of `interactionOptions` to group all interaction related options. '
      'This option is deprecated since v6.',
    )
    int? interactiveFlags,
    @Deprecated(
      'Prefer setting this in `interactionOptions`. '
      'This option is now part of `interactionOptions` to group all interaction related options. '
      'This option is deprecated since v6.',
    )
    bool? debugMultiFingerGestureWinner,
    @Deprecated(
      'Prefer setting this in `interactionOptions`. '
      'This option is now part of `interactionOptions` to group all interaction related options. '
      'This option is deprecated since v6.',
    )
    bool? enableMultiFingerGestureRace,
    @Deprecated(
      'Prefer setting this in `interactionOptions`. '
      'This option is now part of `interactionOptions` to group all interaction related options. '
      'This option is deprecated since v6.',
    )
    double? rotationThreshold,
    @Deprecated(
      'Prefer setting this in `interactionOptions`. '
      'This option is now part of `interactionOptions` to group all interaction related options. '
      'This option is deprecated since v6.',
    )
    int? rotationWinGestures,
    @Deprecated(
      'Prefer setting this in `interactionOptions`. '
      'This option is now part of `interactionOptions` to group all interaction related options. '
      'This option is deprecated since v6.',
    )
    double? pinchZoomThreshold,
    @Deprecated(
      'Prefer setting this in `interactionOptions`. '
      'This option is now part of `interactionOptions` to group all interaction related options. '
      'This option is deprecated since v6.',
    )
    int? pinchZoomWinGestures,
    @Deprecated(
      'Prefer setting this in `interactionOptions`. '
      'This option is now part of `interactionOptions` to group all interaction related options. '
      'This option is deprecated since v6.',
    )
    double? pinchMoveThreshold,
    @Deprecated(
      'Prefer setting this in `interactionOptions`. '
      'This option is now part of `interactionOptions` to group all interaction related options. '
      'This option is deprecated since v6.',
    )
    int? pinchMoveWinGestures,
    @Deprecated(
      'Prefer setting this in `interactionOptions`. '
      'This option is now part of `interactionOptions` to group all interaction related options. '
      'This option is deprecated since v6.',
    )
    bool? enableScrollWheel,
    @Deprecated(
      'Prefer setting this in `interactionOptions`. '
      'This option is now part of `interactionOptions` to group all interaction related options. '
      'This option is deprecated since v6.',
    )
    double? scrollWheelVelocity,
    this.minZoom,
    this.maxZoom,
    this.backgroundColor = const Color(0xFFE0E0E0),
    this.onTap,
    this.onSecondaryTap,
    this.onLongPress,
    this.onPointerDown,
    this.onPointerUp,
    this.onPointerCancel,
    this.onPointerHover,
    this.onPositionChanged,
    this.onMapEvent,
    this.onMapReady,
    @Deprecated(
      'Prefer `cameraConstraint` instead. '
      'This option is now replaced by `cameraConstraint` which provides more flexibile limiting of the map position. '
      'This option is deprecated since v6.',
    )
    this.maxBounds,
    this.keepAlive = false,
  })  : _interactionOptions = interactionOptions,
        _interactiveFlags = interactiveFlags,
        _debugMultiFingerGestureWinner = debugMultiFingerGestureWinner,
        _enableMultiFingerGestureRace = enableMultiFingerGestureRace,
        _rotationThreshold = rotationThreshold,
        _rotationWinGestures = rotationWinGestures,
        _pinchZoomThreshold = pinchZoomThreshold,
        _pinchZoomWinGestures = pinchZoomWinGestures,
        _pinchMoveThreshold = pinchMoveThreshold,
        _pinchMoveWinGestures = pinchMoveWinGestures,
        _enableScrollWheel = enableScrollWheel,
        _scrollWheelVelocity = scrollWheelVelocity,
        initialCenter = center ?? initialCenter,
        initialZoom = zoom ?? initialZoom,
        initialRotation = rotation ?? initialRotation,
        _cameraConstraint = cameraConstraint;

  /// The options of the closest [FlutterMap] ancestor. If this is called from a
  /// context with no [FlutterMap] ancestor, null is returned.
  static MapOptions? maybeOf(BuildContext context) =>
      FlutterMapInheritedModel.maybeOptionsOf(context);

  /// The options of the closest [FlutterMap] ancestor. If this is called from a
  /// context with no [FlutterMap] ancestor a [StateError] will be thrown.
  static MapOptions of(BuildContext context) =>
      maybeOf(context) ??
      (throw StateError(
          '`MapOptions.of()` should not be called outside a `FlutterMap` and its descendants'));

  InteractionOptions get interactionOptions =>
      _interactionOptions ??
      InteractionOptions(
        flags: _interactiveFlags ?? InteractiveFlag.all,
        debugMultiFingerGestureWinner: _debugMultiFingerGestureWinner ?? false,
        enableMultiFingerGestureRace: _enableMultiFingerGestureRace ?? false,
        rotationThreshold: _rotationThreshold ?? 20.0,
        rotationWinGestures: _rotationWinGestures ?? MultiFingerGesture.rotate,
        pinchZoomThreshold: _pinchZoomThreshold ?? 0.5,
        pinchZoomWinGestures: _pinchZoomWinGestures ??
            MultiFingerGesture.pinchZoom | MultiFingerGesture.pinchMove,
        pinchMoveThreshold: _pinchMoveThreshold ?? 40.0,
        pinchMoveWinGestures: _pinchMoveWinGestures ??
            MultiFingerGesture.pinchZoom | MultiFingerGesture.pinchMove,
        enableScrollWheel: _enableScrollWheel ?? true,
        scrollWheelVelocity: _scrollWheelVelocity ?? 0.005,
      );

  /// Note that this getter exists to make sure that the deprecated [maxBounds]
  /// option is consistently used. Making this a getter allows the constructor
  /// to remain const.
  CameraConstraint get cameraConstraint =>
      _cameraConstraint ??
      (maxBounds != null
          ? CameraConstraint.contain(bounds: maxBounds!)
          : const CameraConstraint.unconstrained());

  @override
  bool operator ==(Object other) =>
      other is MapOptions &&
      crs == other.crs &&
      initialCenter == other.initialCenter &&
      initialZoom == other.initialZoom &&
      initialRotation == other.initialRotation &&
      initialCameraFit == other.initialCameraFit &&
      bounds == other.bounds &&
      boundsOptions == other.boundsOptions &&
      minZoom == other.minZoom &&
      maxZoom == other.maxZoom &&
      backgroundColor == other.backgroundColor &&
      onTap == other.onTap &&
      onSecondaryTap == other.onSecondaryTap &&
      onLongPress == other.onLongPress &&
      onPointerDown == other.onPointerDown &&
      onPointerUp == other.onPointerUp &&
      onPointerCancel == other.onPointerCancel &&
      onPointerHover == other.onPointerHover &&
      onPositionChanged == other.onPositionChanged &&
      onMapEvent == other.onMapEvent &&
      cameraConstraint == other.cameraConstraint &&
      onMapReady == other.onMapReady &&
      maxBounds == other.maxBounds &&
      keepAlive == other.keepAlive &&
      interactionOptions == other.interactionOptions;

  @override
  int get hashCode => Object.hashAll([
        crs,
        initialCenter,
        initialZoom,
        initialRotation,
        initialCameraFit,
        bounds,
        boundsOptions,
        minZoom,
        maxZoom,
        backgroundColor,
        onTap,
        onSecondaryTap,
        onLongPress,
        onPointerDown,
        onPointerUp,
        onPointerCancel,
        onPointerHover,
        onPositionChanged,
        onMapEvent,
        cameraConstraint,
        onMapReady,
        keepAlive,
        maxBounds,
        interactionOptions,
      ]);
}

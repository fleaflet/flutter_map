import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/src/geo/crs.dart';
import 'package:flutter_map/src/geo/latlng_bounds.dart';
import 'package:flutter_map/src/gestures/interactive_flag.dart';
import 'package:flutter_map/src/gestures/map_events.dart';
import 'package:flutter_map/src/gestures/multi_finger_gesture.dart';
import 'package:flutter_map/src/map/flutter_map_state_inherited_widget.dart';
import 'package:flutter_map/src/misc/fit_bounds_options.dart';
import 'package:flutter_map/src/misc/frame_constraint.dart';
import 'package:flutter_map/src/misc/frame_fit.dart';
import 'package:flutter_map/src/misc/position.dart';
import 'package:flutter_map/src/misc/private/positioned_tap_detector_2.dart';
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

class MapOptions {
  /// The Coordinate Reference System, defaults to [Epsg3857].
  final Crs crs;

  /// The center when the map is first loaded. If [initialFrameFit] is defined
  /// this has no effect.
  final LatLng initialCenter;

  /// The zoom when the map is first loaded. If [initialFrameFit] is defined
  /// this has no effect.
  final double initialZoom;

  /// The rotation when the map is first loaded.
  final double initialRotation;

  /// Defines the visible bounds when the map is first loaded. Takes precedence
  /// over [initialCenter]/[initialZoom].
  final FrameFit? initialFrameFit;

  final LatLngBounds? bounds;
  final FitBoundsOptions boundsOptions;

  /// Prints multi finger gesture winner Helps to fine adjust
  /// [rotationThreshold] and [pinchZoomThreshold] and [pinchMoveThreshold]
  /// Note: only takes effect if [enableMultiFingerGestureRace] is true
  final bool debugMultiFingerGestureWinner;

  /// If true then [rotationThreshold] and [pinchZoomThreshold] and
  /// [pinchMoveThreshold] will race If multiple gestures win at the same time
  /// then precedence: [pinchZoomWinGestures] > [rotationWinGestures] >
  /// [pinchMoveWinGestures]
  final bool enableMultiFingerGestureRace;

  /// Rotation threshold in degree default is 20.0 Map starts to rotate when
  /// [rotationThreshold] has been achieved or another multi finger gesture wins
  /// which allows [MultiFingerGesture.rotate] Note: if [interactiveFlags]
  /// doesn't contain [InteractiveFlag.rotate] or [enableMultiFingerGestureRace]
  /// is false then rotate cannot win
  final double rotationThreshold;

  /// When [rotationThreshold] wins over [pinchZoomThreshold] and
  /// [pinchMoveThreshold] then [rotationWinGestures] gestures will be used. By
  /// default only [MultiFingerGesture.rotate] gesture will take effect see
  /// [MultiFingerGesture] for custom settings
  final int rotationWinGestures;

  /// Pinch Zoom threshold default is 0.5 Map starts to zoom when
  /// [pinchZoomThreshold] has been achieved or another multi finger gesture
  /// wins which allows [MultiFingerGesture.pinchZoom] Note: if
  /// [interactiveFlags] doesn't contain [InteractiveFlag.pinchZoom] or
  /// [enableMultiFingerGestureRace] is false then zoom cannot win
  final double pinchZoomThreshold;

  /// When [pinchZoomThreshold] wins over [rotationThreshold] and
  /// [pinchMoveThreshold] then [pinchZoomWinGestures] gestures will be used. By
  /// default [MultiFingerGesture.pinchZoom] and [MultiFingerGesture.pinchMove]
  /// gestures will take effect see [MultiFingerGesture] for custom settings
  final int pinchZoomWinGestures;

  /// Pinch Move threshold default is 40.0 (note: this doesn't take any effect
  /// on drag) Map starts to move when [pinchMoveThreshold] has been achieved or
  /// another multi finger gesture wins which allows
  /// [MultiFingerGesture.pinchMove] Note: if [interactiveFlags] doesn't contain
  /// [InteractiveFlag.pinchMove] or [enableMultiFingerGestureRace] is false
  /// then pinch move cannot win
  final double pinchMoveThreshold;

  /// When [pinchMoveThreshold] wins over [rotationThreshold] and
  /// [pinchZoomThreshold] then [pinchMoveWinGestures] gestures will be used. By
  /// default [MultiFingerGesture.pinchMove] and [MultiFingerGesture.pinchZoom]
  /// gestures will take effect see [MultiFingerGesture] for custom settings
  final int pinchMoveWinGestures;

  /// If true then the map will scroll when the user uses the scroll wheel on
  /// his mouse. This is supported on web and desktop, but might also work well
  /// on Android. A [Listener] is used to capture the onPointerSignal events.
  final bool enableScrollWheel;
  final double scrollWheelVelocity;

  final double? minZoom;
  final double? maxZoom;

  /// see [InteractiveFlag] for custom settings
  final int interactiveFlags;

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
  final FrameConstraint frameConstraint;

  /// OnMapReady is called after the map runs it's initState.
  /// At that point the map has assigned its state to the controller
  /// Only use this if your map isn't built immediately (like inside FutureBuilder)
  /// and you need to access the controller as soon as the map is built.
  /// Otherwise you can use WidgetsBinding.instance.addPostFrameCallback
  /// In initState to controll the map before the next frame
  final void Function()? onMapReady;

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
    @Deprecated('Use initialCenter instead') LatLng? center,
    LatLng initialCenter = const LatLng(50.5, 30.51),
    @Deprecated('Use initialZoom instead') double? zoom,
    double initialZoom = 13.0,
    @Deprecated('Use initialRotation instead') double? rotation,
    double initialRotation = 0.0,
    @Deprecated('Use initialFrameFit instead') this.bounds,
    @Deprecated('Use initialFrameFit instead')
    this.boundsOptions = const FitBoundsOptions(),
    this.initialFrameFit,
    this.frameConstraint = const FrameConstraint.unconstrained(),
    @Deprecated('Should be set in interactionOptions instead')
    this.debugMultiFingerGestureWinner = false,
    @Deprecated('Should be set in interactionOptions instead')
    this.enableMultiFingerGestureRace = false,
    @Deprecated('Should be set in interactionOptions instead')
    this.rotationThreshold = 20.0,
    @Deprecated('Should be set in interactionOptions instead')
    this.rotationWinGestures = MultiFingerGesture.rotate,
    @Deprecated('Should be set in interactionOptions instead')
    this.pinchZoomThreshold = 0.5,
    @Deprecated('Should be set in interactionOptions instead')
    this.pinchZoomWinGestures =
        MultiFingerGesture.pinchZoom | MultiFingerGesture.pinchMove,
    @Deprecated('Should be set in interactionOptions instead')
    this.pinchMoveThreshold = 40.0,
    @Deprecated('Should be set in interactionOptions instead')
    this.pinchMoveWinGestures =
        MultiFingerGesture.pinchZoom | MultiFingerGesture.pinchMove,
    @Deprecated('Should be set in interactionOptions instead')
    this.enableScrollWheel = true,
    @Deprecated('Should be set in interactionOptions instead')
    this.scrollWheelVelocity = 0.005,
    this.minZoom,
    this.maxZoom,
    @Deprecated('Should be set in interactionOptions instead')
    this.interactiveFlags = InteractiveFlag.all,
    InteractionOptions? interactionOptions,
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
    this.keepAlive = false,
  })  : _interactionOptions = interactionOptions,
        initialCenter = center ?? initialCenter,
        initialZoom = zoom ?? initialZoom,
        initialRotation = rotation ?? initialRotation,
        assert(rotationThreshold >= 0.0),
        assert(pinchZoomThreshold >= 0.0),
        assert(pinchMoveThreshold >= 0.0);

  static MapOptions? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<MapStateInheritedWidget>()
      ?.options;

  static MapOptions of(BuildContext context) =>
      maybeOf(context) ??
      (throw StateError(
          '`MapOptions.of()` should not be called outside a `FlutterMap` and its descendants'));

  InteractionOptions get interactionOptions =>
      _interactionOptions ??
      InteractionOptions(
        flags: interactiveFlags,
        debugMultiFingerGestureWinner: debugMultiFingerGestureWinner,
        enableMultiFingerGestureRace: enableMultiFingerGestureRace,
        rotationThreshold: rotationThreshold,
        rotationWinGestures: rotationWinGestures,
        pinchZoomThreshold: pinchZoomThreshold,
        pinchZoomWinGestures: pinchZoomWinGestures,
        pinchMoveThreshold: pinchMoveThreshold,
        pinchMoveWinGestures: pinchMoveWinGestures,
        enableScrollWheel: enableScrollWheel,
        scrollWheelVelocity: scrollWheelVelocity,
      );
}

final class InteractionOptions {
  /// See [InteractiveFlag] for custom settings
  final int flags;

  /// Prints multi finger gesture winner Helps to fine adjust
  /// [rotationThreshold] and [pinchZoomThreshold] and [pinchMoveThreshold]
  /// Note: only takes effect if [enableMultiFingerGestureRace] is true
  final bool debugMultiFingerGestureWinner;

  /// If true then [rotationThreshold] and [pinchZoomThreshold] and
  /// [pinchMoveThreshold] will race If multiple gestures win at the same time
  /// then precedence: [pinchZoomWinGestures] > [rotationWinGestures] >
  /// [pinchMoveWinGestures]
  final bool enableMultiFingerGestureRace;

  /// Rotation threshold in degree default is 20.0 Map starts to rotate when
  /// [rotationThreshold] has been achieved or another multi finger gesture wins
  /// which allows [MultiFingerGesture.rotate] Note: if [interactiveFlags]
  /// doesn't contain [InteractiveFlag.rotate] or [enableMultiFingerGestureRace]
  /// is false then rotate cannot win
  final double rotationThreshold;

  /// When [rotationThreshold] wins over [pinchZoomThreshold] and
  /// [pinchMoveThreshold] then [rotationWinGestures] gestures will be used. By
  /// default only [MultiFingerGesture.rotate] gesture will take effect see
  /// [MultiFingerGesture] for custom settings
  final int rotationWinGestures;

  /// Pinch Zoom threshold default is 0.5 Map starts to zoom when
  /// [pinchZoomThreshold] has been achieved or another multi finger gesture
  /// wins which allows [MultiFingerGesture.pinchZoom] Note: if
  /// [interactiveFlags] doesn't contain [InteractiveFlag.pinchZoom] or
  /// [enableMultiFingerGestureRace] is false then zoom cannot win
  final double pinchZoomThreshold;

  /// When [pinchZoomThreshold] wins over [rotationThreshold] and
  /// [pinchMoveThreshold] then [pinchZoomWinGestures] gestures will be used. By
  /// default [MultiFingerGesture.pinchZoom] and [MultiFingerGesture.pinchMove]
  /// gestures will take effect see [MultiFingerGesture] for custom settings
  final int pinchZoomWinGestures;

  /// Pinch Move threshold default is 40.0 (note: this doesn't take any effect
  /// on drag) Map starts to move when [pinchMoveThreshold] has been achieved or
  /// another multi finger gesture wins which allows
  /// [MultiFingerGesture.pinchMove] Note: if [interactiveFlags] doesn't contain
  /// [InteractiveFlag.pinchMove] or [enableMultiFingerGestureRace] is false
  /// then pinch move cannot win
  final double pinchMoveThreshold;

  /// When [pinchMoveThreshold] wins over [rotationThreshold] and
  /// [pinchZoomThreshold] then [pinchMoveWinGestures] gestures will be used. By
  /// default [MultiFingerGesture.pinchMove] and [MultiFingerGesture.pinchZoom]
  /// gestures will take effect see [MultiFingerGesture] for custom settings
  final int pinchMoveWinGestures;

  /// If true then the map will scroll when the user uses the scroll wheel on
  /// his mouse. This is supported on web and desktop, but might also work well
  /// on Android. A [Listener] is used to capture the onPointerSignal events.
  final bool enableScrollWheel;
  final double scrollWheelVelocity;

  const InteractionOptions({
    required this.flags,
    this.debugMultiFingerGestureWinner = false,
    this.enableMultiFingerGestureRace = false,
    this.rotationThreshold = 20.0,
    this.rotationWinGestures = MultiFingerGesture.rotate,
    this.pinchZoomThreshold = 0.5,
    this.pinchZoomWinGestures =
        MultiFingerGesture.pinchZoom | MultiFingerGesture.pinchMove,
    this.pinchMoveThreshold = 40.0,
    this.pinchMoveWinGestures =
        MultiFingerGesture.pinchZoom | MultiFingerGesture.pinchMove,
    this.enableScrollWheel = true,
    this.scrollWheelVelocity = 0.005,
  });

  bool get dragEnabled => InteractiveFlag.hasDrag(flags);
  bool get flingEnabled => InteractiveFlag.hasFlingAnimation(flags);
  bool get doubleTapZoomEnabled => InteractiveFlag.hasDoubleTapZoom(flags);
  bool get rotateEnabled => InteractiveFlag.hasRotate(flags);
  bool get pinchZoomEnabled => InteractiveFlag.hasPinchZoom(flags);
  bool get pinchMoveEnabled => InteractiveFlag.hasPinchMove(flags);

  @override
  bool operator ==(Object other) =>
      other is InteractionOptions &&
      flags == other.flags &&
      debugMultiFingerGestureWinner == other.debugMultiFingerGestureWinner &&
      enableMultiFingerGestureRace == other.enableMultiFingerGestureRace &&
      rotationThreshold == other.rotationThreshold &&
      rotationWinGestures == other.rotationWinGestures &&
      pinchZoomThreshold == other.pinchZoomThreshold &&
      pinchZoomWinGestures == other.pinchZoomWinGestures &&
      pinchMoveThreshold == other.pinchMoveThreshold &&
      pinchMoveWinGestures == other.pinchMoveWinGestures &&
      enableScrollWheel == other.enableScrollWheel &&
      scrollWheelVelocity == other.scrollWheelVelocity;

  @override
  int get hashCode => Object.hash(
        flags,
        debugMultiFingerGestureWinner,
        enableMultiFingerGestureRace,
        rotationThreshold,
        rotationWinGestures,
        pinchZoomThreshold,
        pinchZoomWinGestures,
        pinchMoveThreshold,
        pinchMoveWinGestures,
        enableScrollWheel,
        scrollWheelVelocity,
      );
}

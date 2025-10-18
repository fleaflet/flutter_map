import 'package:flutter/animation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:meta/meta.dart';

/// All interactive options for [FlutterMap]
@immutable
class InteractionOptions {
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
  /// which allows [MultiFingerGesture.rotate].
  ///
  /// Note: if [flags] doesn't contain [InteractiveFlag.rotate] or
  /// [enableMultiFingerGestureRace] is false then rotate cannot win.
  final double rotationThreshold;

  /// When [rotationThreshold] wins over [pinchZoomThreshold] and
  /// [pinchMoveThreshold] then [rotationWinGestures] gestures will be used. By
  /// default only [MultiFingerGesture.rotate] gesture will take effect see
  /// [MultiFingerGesture] for custom settings
  final int rotationWinGestures;

  /// Pinch Zoom threshold default is 0.5 Map starts to zoom when
  /// [pinchZoomThreshold] has been achieved or another multi finger gesture
  /// wins which allows [MultiFingerGesture.pinchZoom]
  ///
  /// Note: if [flags] doesn't contain [InteractiveFlag.pinchZoom] or
  /// [enableMultiFingerGestureRace] is false then zoom cannot win.
  final double pinchZoomThreshold;

  /// When [pinchZoomThreshold] wins over [rotationThreshold] and
  /// [pinchMoveThreshold] then [pinchZoomWinGestures] gestures will be used. By
  /// default [MultiFingerGesture.pinchZoom] and [MultiFingerGesture.pinchMove]
  /// gestures will take effect see [MultiFingerGesture] for custom settings
  final int pinchZoomWinGestures;

  /// Pinch Move threshold default is 40.0 (note: this doesn't take any effect
  /// on drag) Map starts to move when [pinchMoveThreshold] has been achieved or
  /// another multi finger gesture wins which allows
  /// [MultiFingerGesture.pinchMove].
  ///
  /// Note: if [flags] doesn't contain
  /// [InteractiveFlag.pinchMove] or [enableMultiFingerGestureRace] is false
  /// then pinch move cannot win
  final double pinchMoveThreshold;

  /// When [pinchMoveThreshold] wins over [rotationThreshold] and
  /// [pinchZoomThreshold] then [pinchMoveWinGestures] gestures will be used. By
  /// default [MultiFingerGesture.pinchMove] and [MultiFingerGesture.pinchZoom]
  /// gestures will take effect see [MultiFingerGesture] for custom settings
  final int pinchMoveWinGestures;

  /// The used velocity how fast the map should zoom in or out by scrolling
  /// with the scroll wheel of a mouse.
  final double scrollWheelVelocity;

  /// Calculates the zoom difference to apply to the initial zoom level when a
  /// user is performing a double-tap drag zoom gesture
  ///
  /// `verticalOffset` is the vertical distance between the user's initial
  /// pointer-down position and their current dragged position. `camera` may be
  /// used, for example, to factor in the current zoom level.
  ///
  /// The default calculator is [defaultDoubleTapDragZoomChangeCalculator].
  final double Function(double verticalOffset, MapCamera camera)
      doubleTapDragZoomChangeCalculator;

  /// The duration of the animation played when double-tap zooming
  ///
  /// Defaults to 200ms.
  final Duration doubleTapZoomDuration;

  /// The curve of the animation played when double-tap zooming
  ///
  /// Defaults to [Curves.fastOutSlowIn].
  final Curve doubleTapZoomCurve;

  /// The damping ratio for the fling animation spring simulation
  ///
  /// This controls how the fling animation decelerates after a drag gesture.
  /// Lower values result in less damping (more momentum, bouncier).
  /// Higher values result in more damping (stops quicker, less bouncy).
  ///
  /// Defaults to 2.0.
  final double flingAnimationDampingRatio;

  /// Options to configure cursor/keyboard rotation
  ///
  /// Cursor/keyboard rotation is designed for desktop platforms, and allows the
  /// cursor to be used to set the rotation of the map whilst a keyboard key is
  /// held down (as triggered by [CursorKeyboardRotationOptions.isKeyTrigger]).
  ///
  /// By default, rotation is triggered if any key in
  /// [CursorKeyboardRotationOptions.defaultTriggerKeys] is held (any of the
  /// "Control" keys).
  ///
  /// To disable cursor/keyboard rotation, use the
  /// [CursorKeyboardRotationOptions.disabled] constructor.
  final CursorKeyboardRotationOptions cursorKeyboardRotationOptions;

  /// Options to configure how keyboard keys may be used to control the map
  ///
  /// See [CursorKeyboardRotationOptions] for options to control the keyboard
  /// and mouse cursor being used together to rotate the map.
  ///
  /// By default, keyboard movement using the arrow keys is enabled.
  final KeyboardOptions keyboardOptions;

  /// Create a new [InteractionOptions] instance to be used
  /// in [MapOptions.interactionOptions].
  const InteractionOptions({
    this.flags = InteractiveFlag.all,
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
    this.scrollWheelVelocity = 0.005,
    this.doubleTapDragZoomChangeCalculator =
        defaultDoubleTapDragZoomChangeCalculator,
    this.doubleTapZoomDuration = const Duration(milliseconds: 200),
    this.doubleTapZoomCurve = Curves.fastOutSlowIn,
    this.flingAnimationDampingRatio = 5.0,
    this.cursorKeyboardRotationOptions = const CursorKeyboardRotationOptions(),
    this.keyboardOptions = const KeyboardOptions(),
  })  : assert(
          rotationThreshold >= 0.0,
          '`rotationThreshold` must be positive',
        ),
        assert(
          pinchZoomThreshold >= 0.0,
          '`pinchZoomThreshold` must be positive',
        ),
        assert(
          pinchMoveThreshold >= 0.0,
          '`pinchMoveThreshold` must be positive',
        ),
        assert(
          flingAnimationDampingRatio > 0.0,
          '`flingAnimationDampingRatio` must be positive',
        );

  /// Default calculator function for [doubleTapDragZoomChangeCalculator]
  ///
  /// Uses a constant of 1/360, and changes the zoom speed based on the current
  /// zoom level.
  static double defaultDoubleTapDragZoomChangeCalculator(
    double verticalOffset,
    MapCamera camera,
  ) =>
      (1 / 360) * camera.zoom * verticalOffset;

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
      scrollWheelVelocity == other.scrollWheelVelocity &&
      doubleTapDragZoomChangeCalculator ==
          other.doubleTapDragZoomChangeCalculator &&
      doubleTapZoomDuration == other.doubleTapZoomDuration &&
      doubleTapZoomCurve == other.doubleTapZoomCurve &&
      flingAnimationDampingRatio == other.flingAnimationDampingRatio &&
      keyboardOptions == other.keyboardOptions;

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
        scrollWheelVelocity,
        doubleTapDragZoomChangeCalculator,
        doubleTapZoomDuration,
        doubleTapZoomCurve,
        flingAnimationDampingRatio,
        keyboardOptions,
      );
}

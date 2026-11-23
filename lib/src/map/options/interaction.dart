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

  /// Whether to race multi-finger gestures instead of allowing multiple
  /// gestures to be recognised at the same time.
  ///
  /// Which gestures win is decided by [rotationThreshold],
  /// [pinchZoomThreshold], and [pinchMoveThreshold].
  ///
  /// If multiple gestures win at the same time, then precedence is:
  /// [pinchZoomWinGestures] > [rotationWinGestures] > [pinchMoveWinGestures].
  ///
  /// Defaults to `false`.
  final bool enableMultiFingerGestureRace;

  /// Required angle of rotation (in degrees) of multi-finger gesture for map
  /// to rotate.
  ///
  /// Prevents unintentional rotation of the map when zooming and panning.
  ///
  /// If [enableMultiFingerGestureRace] is enabled, then this will win over
  /// other gestures once past this threshold.
  ///
  /// Defaults to 20 degrees.
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

  /// The multipler applied to the scroll offset to calculate the zoom offset,
  /// when smooth zooming is disabled.
  ///
  /// ---
  ///
  /// Since v8.4, this has been deprecated in favour of
  /// [SnapScrollZoomOptions.zoomRate]. The new scroll zoom options allow for
  /// the new smooth scrolling functionality to also be customised.
  ///
  /// To improve the end-user experience for more users, maps will use smooth
  /// scrolling since v8.4 by default - **unless this property has been changed
  /// from its default of 0.005** and the [scrollZoomOptions] have not been
  /// changed from their default, in which case it is respected and the snap
  /// behaviour will be used.
  ///
  /// To migrate, this argument should be removed (left to default), and the
  /// desired value instead used by setting [scrollZoomOptions] to
  /// [ScrollZoomOptions.snap] and setting the argument in the constructor.
  ///
  /// Defaults to `1 / 200`. Overriden by [SnapScrollZoomOptions.zoomRate]
  /// if set.
  @Deprecated(
    'Prefer `SnapScrollZoomOptions.zoomRate`. See documentation on this '
    'property for more information. Will be removed in an upcoming major '
    'release.',
  )
  final double scrollWheelVelocity;

  /// Options to configure scroll wheel/trackpad zoom behavior.
  ///
  /// By default, scroll wheel zoom uses smooth animated zooming.
  final ScrollZoomOptions scrollZoomOptions;

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
  /// Defaults to 5.0.
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
    @Deprecated(
      'Prefer `SnapScrollZoomOptions.zoomRate`. See documentation on this '
      'property for more information. Will be removed in an upcoming major '
      'release.',
    )
    this.scrollWheelVelocity = 0.005,
    this.scrollZoomOptions = const ScrollZoomOptions.smooth(),
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
      scrollZoomOptions == other.scrollZoomOptions &&
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
        scrollZoomOptions,
        doubleTapDragZoomChangeCalculator,
        doubleTapZoomDuration,
        doubleTapZoomCurve,
        flingAnimationDampingRatio,
        keyboardOptions,
      );
}

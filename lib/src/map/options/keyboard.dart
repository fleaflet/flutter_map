import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';

/// Options to configure how keyboard keys may be used to control the map
///
/// When a key is pushed down, an animation starts, consisting of a curved
/// portion which takes the animation to its maximum velocity, an indefinitely
/// long animation at maximum velocity, then ended on the key up with another
/// curved portion. If a key is pressed and released quickly, it might trigger a
/// short animation called a 'leap', which has the middle indefinite portion
/// ommitted.
///
/// See [CursorKeyboardRotationOptions] for options to control the keyboard and
/// mouse cursor being used together to rotate the map.
@immutable
class KeyboardOptions {
  /// Whether to allow arrow keys to pan the map (in their respective
  /// directions)
  ///
  /// This is enabled by default.
  final bool enableArrowKeysPanning;

  /// Whether to allow the W, A, S, D keys (*) to pan the map (in the directions
  /// UP, LEFT, DOWN, RIGHT respectively)
  ///
  /// WASD are only the physical and logical keys on QWERTY keyboards. On non-
  /// QWERTY keyboards, such as AZERTY, the keys in the same position as on the
  /// QWERTY keyboard is used (ie. ZQSD on AZERTY).
  ///
  /// If enabled, it is recommended to enable [enableArrowKeysPanning] to
  /// provide panning functionality easily for left handed users.
  final bool enableWASDPanning;

  /// Whether to allow the Q & E keys (*) to rotate the map (Q rotates
  /// anticlockwise, E rotates clockwise)
  ///
  /// QE are only the physical and logical keys on QWERTY keyboards. On non-
  /// QWERTY keyboards, such as AZERTY, the keys in the same position as on the
  /// QWERTY keyboard is used (ie. AE on AZERTY).
  final bool enableQERotating;

  /// Whether to allow the R & F keys to zoom the map (R zooms IN (increases
  /// zoom level), F zooms OUT (decreases zoom level))
  ///
  /// RF are only the physical and logical keys on QWERTY keyboards. On non-
  /// QWERTY keyboards, such as AZERTY, the keys in the same position as on the
  /// QWERTY keyboard is used (ie. RF on AZERTY).
  final bool enableRFZooming;

  /// The maximum offset to apply per frame to the camera's center during a pan
  /// animation, given the current camera zoom level
  ///
  /// Measured in screen space. It is not required to make use of the camera
  /// zoom level. Negative numbers will flip the standard pan keys.
  ///
  /// Defaults to `12 * math.log(0.1 * z + 1) + 1`, where `z` is the zoom level.
  final double Function(double zoom)? maxPanVelocity;

  /// The maximum zoom level difference to apply per frame to the camera's zoom
  /// level during a zoom animation
  ///
  /// Measured in zoom levels. Negative numbers will flip the standard zoom
  /// keys.
  ///
  /// Defaults to 0.03.
  final double maxZoomVelocity;

  /// The maximum angular difference to apply per frame to the camera's rotation
  /// during a rotation animation
  ///
  /// Measured in degrees. Negative numbers will flip the standard rotation
  /// keys.
  ///
  /// Defaults to 3.
  final double maxRotateVelocity;

  /// Duration of the curved ([Curves.easeIn]) portion of the animation occuring
  /// after a key down event (and after a key up event if
  /// [animationCurveReverseDuration] is `null`)
  ///
  /// Defaults to 450ms.
  final Duration animationCurveDuration;

  /// Duration of the curved (reverse [Curves.easeIn]) portion of the animation
  /// occuring after a key up event
  ///
  /// Defaults to 600ms. Set to `null` to use [animationCurveDuration].
  final Duration? animationCurveReverseDuration;

  /// Curve of the curved portion of the animation occuring after key down and
  /// key up events
  ///
  /// Defaults to [Curves.easeInOut].
  final Curve animationCurveCurve;

  /// Maximum duration between the key down and key up events of an animation
  /// which will trigger a 'leap'
  ///
  /// 'Leaping' allows the animation to reach its maximum velocity then animate
  /// back to zero velocity, even when the animation key is not being held.
  /// In other words, leaping occurs when one of the trigger keys is pressed -
  /// not held - and pans/zooms/rotates the map a small amount.
  ///
  /// The leap lasts for [animationCurveDuration] +
  /// [animationCurveReverseDuration].
  ///
  /// Defaults to 100ms. Set to `null` to disable.
  final Duration? performLeapTriggerDuration;

  /// Custom [FocusNode] to be used instead of internal node
  ///
  /// May cause unexpected behaviour.
  final FocusNode? focusNode;

  /// Whether to request focus as soon as the map widget appears (and to enable
  /// keyboard controls)
  ///
  /// Defaults to `true`.
  final bool autofocus;

  /// Create options which specify how the map may be controlled by keyboard
  /// keys
  ///
  /// Only [enableArrowKeysPanning] is `true` by default.
  ///
  /// Use [KeyboardOptions.disabled] to disable the keyboard keys.
  const KeyboardOptions({
    this.enableArrowKeysPanning = true,
    this.enableWASDPanning = false,
    this.enableQERotating = false,
    this.enableRFZooming = false,
    this.maxPanVelocity,
    this.maxZoomVelocity = 0.03,
    this.maxRotateVelocity = 3,
    this.animationCurveDuration = const Duration(milliseconds: 450),
    this.animationCurveReverseDuration = const Duration(milliseconds: 600),
    this.animationCurveCurve = Curves.easeInOut,
    this.performLeapTriggerDuration = const Duration(milliseconds: 100),
    this.focusNode,
    this.autofocus = true,
  });

  /// Disable keyboard control of the map
  ///
  /// [CursorKeyboardRotationOptions] may still be active, and is not disabled
  /// if this is disabled.
  const KeyboardOptions.disabled()
      : this(
          enableArrowKeysPanning: false,
          autofocus: false,
        );

  @override
  int get hashCode => Object.hash(
        enableArrowKeysPanning,
        enableWASDPanning,
        enableQERotating,
        enableRFZooming,
        maxPanVelocity,
        maxZoomVelocity,
        maxRotateVelocity,
        animationCurveDuration,
        animationCurveReverseDuration,
        animationCurveCurve,
        performLeapTriggerDuration,
        focusNode,
        autofocus,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KeyboardOptions &&
          enableArrowKeysPanning == other.enableArrowKeysPanning &&
          enableWASDPanning == other.enableWASDPanning &&
          enableQERotating == other.enableQERotating &&
          enableRFZooming == other.enableRFZooming &&
          maxPanVelocity == other.maxPanVelocity &&
          maxZoomVelocity == other.maxZoomVelocity &&
          maxRotateVelocity == other.maxRotateVelocity &&
          animationCurveDuration == other.animationCurveDuration &&
          animationCurveReverseDuration ==
              other.animationCurveReverseDuration &&
          animationCurveCurve == other.animationCurveCurve &&
          performLeapTriggerDuration == other.performLeapTriggerDuration &&
          focusNode == other.focusNode &&
          autofocus == other.autofocus);
}

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';

/// Options to configure how keyboard keys may be used to control the map
///
/// When a key is pushed down, an animation starts, consisting of a curved
/// portion which takes the animation to its maximum velocity, an indefinitely
/// long animation at maximum velocity, then ended on the key up with another
/// curved portion.
///
/// If a key is pressed and released quickly, it might trigger a short animation
/// called a 'leap'. The leap consists of a part of the curved portion, and also
/// scales the velocity of the concerned gesture.
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
  /// Defaults to `5 * math.log(0.15 * z + 1) + 1`, where `z` is the zoom level.
  final double Function(double zoom)? maxPanVelocity;

  /// The amount to scale the panning offset velocity by during a leap animation
  ///
  /// The larger the number, the larger the movement during a leap. To change
  /// the duration of a leap, see [leapMaxOfCurveComponent].
  ///
  /// This may cause the pan velocity to exceed [maxPanVelocity].
  ///
  /// Defaults to 3.
  final double panLeapVelocityMultiplier;

  /// The maximum zoom level difference to apply per frame to the camera's zoom
  /// level during a zoom animation
  ///
  /// Measured in zoom levels. Negative numbers will flip the standard zoom
  /// keys.
  ///
  /// Defaults to 0.03.
  final double maxZoomVelocity;

  /// The amount to scale the zooming velocity by during a leap animation
  ///
  /// The larger the number, the larger the zoom difference during a leap. To
  /// change the duration of a leap, see [leapMaxOfCurveComponent].
  ///
  /// This may cause the pan velocity to exceed [maxZoomVelocity].
  ///
  /// Defaults to 3.
  final double zoomLeapVelocityMultiplier;

  /// The maximum angular difference to apply per frame to the camera's rotation
  /// during a rotation animation
  ///
  /// Measured in degrees. Negative numbers will flip the standard rotation
  /// keys.
  ///
  /// Defaults to 3.
  final double maxRotateVelocity;

  /// The amount to scale the rotation velocity by during a leap animation
  ///
  /// The larger the number, the larger the rotation difference during a leap.
  /// To change the duration of a leap, see [leapMaxOfCurveComponent].
  ///
  /// This may cause the pan velocity to exceed [maxRotateVelocity].
  ///
  /// Defaults to 3.
  final double rotateLeapVelocityMultiplier;

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
  /// To customize the leap itself, see the [leapMaxOfCurveComponent] &
  /// `...LeapVelocityMultiplier` properties.
  ///
  /// Defaults to 100ms. Set to `null` to disable leaping.
  final Duration? performLeapTriggerDuration;

  /// The percentage (0.0 - 1.0) of the curve animation component that is driven
  /// to (from 0), then in reverse from (to 0)
  ///
  /// Reducing means the leap occurs quicker (assuming a consistent curve
  /// animation duration). Also see `...LeapVelocityMultiplier` properties to
  /// change the distance of the leap assuming a consistent leap duration.
  ///
  /// For example, if set to 1, then the leap will take [animationCurveDuration]
  /// + [animationCurveReverseDuration] to complete.
  ///
  /// Defaults to 0.6. Must be greater than 0 and less than or equal to 1. To
  /// disable leaping, or change the maximum length of the key press that will
  /// trigger a leap, see [performLeapTriggerDuration].
  final double leapMaxOfCurveComponent;

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
    this.panLeapVelocityMultiplier = 3,
    this.maxZoomVelocity = 0.03,
    this.zoomLeapVelocityMultiplier = 3,
    this.maxRotateVelocity = 3,
    this.rotateLeapVelocityMultiplier = 3,
    this.animationCurveDuration = const Duration(milliseconds: 450),
    this.animationCurveReverseDuration = const Duration(milliseconds: 600),
    this.animationCurveCurve = Curves.easeInOut,
    this.performLeapTriggerDuration = const Duration(milliseconds: 100),
    this.leapMaxOfCurveComponent = 0.6,
    this.focusNode,
    this.autofocus = true,
  }) : assert(
          leapMaxOfCurveComponent > 0 && leapMaxOfCurveComponent <= 1,
          '`leapMaxOfCurveComponent` must be between 0 (exclusive) and 1 '
          '(inclusive)',
        );

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
        panLeapVelocityMultiplier,
        maxZoomVelocity,
        zoomLeapVelocityMultiplier,
        maxRotateVelocity,
        rotateLeapVelocityMultiplier,
        animationCurveDuration,
        animationCurveReverseDuration,
        animationCurveCurve,
        performLeapTriggerDuration,
        leapMaxOfCurveComponent,
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
          panLeapVelocityMultiplier == other.panLeapVelocityMultiplier &&
          maxZoomVelocity == other.maxZoomVelocity &&
          zoomLeapVelocityMultiplier == other.zoomLeapVelocityMultiplier &&
          maxRotateVelocity == other.maxRotateVelocity &&
          rotateLeapVelocityMultiplier == other.rotateLeapVelocityMultiplier &&
          animationCurveDuration == other.animationCurveDuration &&
          animationCurveReverseDuration ==
              other.animationCurveReverseDuration &&
          animationCurveCurve == other.animationCurveCurve &&
          performLeapTriggerDuration == other.performLeapTriggerDuration &&
          leapMaxOfCurveComponent == other.leapMaxOfCurveComponent &&
          focusNode == other.focusNode &&
          autofocus == other.autofocus);
}

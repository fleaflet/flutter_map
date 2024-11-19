import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:meta/meta.dart';

/// A callback function which takes as input the number of times the concerned
/// keyboard key has been pressed down & repeated ([KeyDownEvent] &
/// [KeyRepeatEvent]) and outputs the transformation that should be applied
///
/// See the specific field in [KeyboardOptions] for the specific output meaning.
typedef KeyboardEffectSpeedCalculator = double Function(int repetitionCounter);

/// Options to configure how keyboard keys may be used to control the map
///
/// See [CursorKeyboardRotationOptions] for options to control the keyboard and
/// mouse cursor being used together to rotate the map.
@immutable
class KeyboardOptions {
  /// Whether to allow arrow keys to pan the map (in their respective directions)
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

  /// Whether to allow the Q & E keys (*) to rotate the map (Q rotates COUNTER-
  /// CLOCKWISE, E rotates CLOCKWISE)
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

  /// Calculates the transformation to apply to the camera's position, where
  /// the output is in logical pixels (the direction is automatically handled)
  ///
  /// See [KeyboardEffectSpeedCalculator] for information.
  ///
  /// Defaults to [defaultPanSpeedCalculator].
  final KeyboardEffectSpeedCalculator? panSpeedCalculator;

  /// Calculates the transformation to apply to the camera's position, where
  /// the output is in zoom levels (the direction is automatically handled)
  ///
  /// See [KeyboardEffectSpeedCalculator] for information.
  ///
  /// Defaults to [defaultZoomSpeedCalculator].
  final KeyboardEffectSpeedCalculator? zoomSpeedCalculator;

  /// Calculates the transformation to apply to the camera's position, where
  /// the output is in degrees (the direction is automatically handled)
  ///
  /// See [KeyboardEffectSpeedCalculator] for information.
  ///
  /// Defaults to [defaultRotateSpeedCalculator].
  final KeyboardEffectSpeedCalculator? rotateSpeedCalculator;

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
    this.panSpeedCalculator,
    this.zoomSpeedCalculator,
    this.rotateSpeedCalculator,
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

  /// The default [KeyboardOptions.panSpeedCalculator]
  static double defaultPanSpeedCalculator(int counter) => switch (counter) {
        1 => 2,
        <= 20 => 5,
        <= 25 => 10,
        <= 30 => 20,
        <= 50 => 30,
        <= 100 => 40,
        _ => 50,
      };

  /// The default [KeyboardOptions.rotateSpeedCalculator]
  static double defaultRotateSpeedCalculator(int counter) => switch (counter) {
        1 => 1,
        <= 20 => 5,
        _ => 10,
      };

  /// The default [KeyboardOptions.zoomSpeedCalculator]
  static double defaultZoomSpeedCalculator(int counter) => switch (counter) {
        1 => 0.01,
        <= 10 => 0.1,
        <= 50 => 0.2,
        _ => 0.5,
      };
}

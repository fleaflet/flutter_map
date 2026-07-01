import 'package:flutter_map/src/map/options/interaction.dart';
import 'package:meta/meta.dart';

/// Options to configure scroll zoom behavior.
///
/// Two behaviours are available:
///  * Smooth (default, available since v8.4)
///  * Snap
///
/// When smooth zooming (inspired by MapLibre GL JS), each mouse wheel tick
/// triggers a short eased animation to the new zoom level. Rapid successive
/// wheel ticks chain smoothly with velocity-continuous bezier curves.
///
/// When snapping, each mouse wheel tick jumps immediately to the new zoom level
/// on each wheel event.
///
/// Trackpad events are always applied directly regardless of this setting,
/// since trackpad hardware already provides fine-grained continuous input.
///
/// To use snapping, set [wheelSmoothZoomRate] to `null`: then, [snapZoomRate]
/// is the sensitivity used for both mouse and trackpad scroll events (since the
/// two methods are not differentiated when snapping). Otherwise,
/// [wheelSmoothZoomRate] and [trackpadSmoothZoomRate] are used seperately for
/// their respective devices.
///
/// Note that on some platforms, the trackpad behaves differently - for example,
/// scrolling may scroll on some, or pan on others.
@immutable
class ScrollZoomOptions {
  /// The multipler applied to the scroll offset to calculate the zoom offset,
  /// when smooth zooming is disabled.
  ///
  /// Closer to zero = lower zoom offset per scroll event.
  ///
  /// Smooth zooming is enabled by default. To disable, and use snapping zoom,
  /// set [wheelSmoothZoomRate] to `null`.
  ///
  /// Defaults to [InteractionOptions.scrollWheelVelocity], which defaults
  /// to `1 / 200`.
  ///
  /// Should not be explicitly set to `null`.
  final double? snapZoomRate;

  /// Controls zoom sensitivity for mouse wheel events, when smooth zooming
  /// is enabled (as by default).
  ///
  /// Closer to zero = lower zoom offset per wheel tick.
  ///
  /// When `null`, smooth scrolling is disabled, and snapping zooming (old
  /// behaviour) is used instead.
  ///
  /// Defaults to `1 / 350`.
  final double? wheelSmoothZoomRate;

  /// Controls zoom sensitivity for trackpad events, when smooth zooming is
  /// enabled (as by default).
  ///
  /// Closer to zero = lower zoom offset per trackpad gesture unit.
  ///
  /// Defaults to `1 / 100`.
  final double trackpadSmoothZoomRate;

  /// Duration of the easing animation for each mouse wheel tick, when smooth
  /// zooming is enabled (as by default).
  ///
  /// Each wheel tick triggers an animation of this duration. When multiple
  /// ticks arrive before the animation completes, the animations chain
  /// smoothly.
  ///
  /// Defaults to 200ms.
  final Duration animationDuration;

  /// Use smooth zooming, as by default.
  ///
  /// For more information, see [ScrollZoomOptions].
  const ScrollZoomOptions.smooth({
    this.wheelSmoothZoomRate = 1 / 350,
    this.trackpadSmoothZoomRate = 1 / 100,
    this.animationDuration = const Duration(milliseconds: 200),
  }) : snapZoomRate = 0.005;

  /// Use snap zooming.
  ///
  /// For more information, see [ScrollZoomOptions].
  const ScrollZoomOptions.snapping({
    this.snapZoomRate,
  })  : wheelSmoothZoomRate = null,
        trackpadSmoothZoomRate = 1 / 100,
        animationDuration = const Duration(milliseconds: 200);

  @override
  bool operator ==(Object other) =>
      other is ScrollZoomOptions &&
      snapZoomRate == other.snapZoomRate &&
      wheelSmoothZoomRate == other.wheelSmoothZoomRate &&
      trackpadSmoothZoomRate == other.trackpadSmoothZoomRate &&
      animationDuration == other.animationDuration;

  @override
  int get hashCode => Object.hash(
        snapZoomRate,
        wheelSmoothZoomRate,
        trackpadSmoothZoomRate,
        animationDuration,
      );
}

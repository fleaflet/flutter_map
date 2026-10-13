import 'package:flutter_map/src/map/options/interaction.dart';
import 'package:meta/meta.dart';

/// Options to configure scroll zoom behavior.
///
/// Two behaviours are available:
///  * Smooth (default, available since v8.4): [ScrollZoomOptions.smooth]
///  * Snap: [ScrollZoomOptions.snap]
///
/// Remember when customising zoom rates that the behaviour will differ between
/// platform and hardware, which is very difficult to disambiguate accurately to
/// use to inform the zoom rate. Therefore, values should be used which are
/// likely to work well for many users across many environments.
///
/// The behaviour difference only applies to mouse wheel inputs. Trackpad events
/// are always applied without smoothing regardless of the behaviour, since
/// trackpad hardware drivers usually already provide fine-grained continuous
/// input.
///
/// Note that on some platforms, the trackpad behaves differently - for example,
/// scrolling may scroll on some, or pan on others. This cannot be overcome
/// without changes to the Flutter engine.
@immutable
sealed class ScrollZoomOptions {
  const ScrollZoomOptions();

  /// Use and configure smooth scroll zooming.
  ///
  /// See [SmoothScrollZoomOptions] for more information.
  const factory ScrollZoomOptions.smooth({
    double wheelZoomRate,
    double trackpadZoomRate,
    Duration animationDuration,
  }) = SmoothScrollZoomOptions;

  /// Use and configure snap scroll zooming.
  ///
  /// See [SnapScrollZoomOptions] for more information.
  const factory ScrollZoomOptions.snap({double zoomRate}) =
      SnapScrollZoomOptions;
}

/// When smooth scroll zooming, each mouse wheel tick triggers a short eased
/// animation to the new zoom level. Rapid successive wheel ticks chain smoothly
/// with velocity-continuous bezier curves.
///
/// The algorithm to implement this is based off the MapLibre GL JS algorithm.
///
/// Although trackpad events are not smoothed, they are disambiguated from mouse
/// wheel events, and therefore a different sensitivity rate can be applied to
/// each input method.
///
/// ---
///
/// This is available since v8.4, and is the default behaviour - except in
/// certain edge cases before v9: see [InteractionOptions.scrollWheelVelocity]
/// for more information.
class SmoothScrollZoomOptions extends ScrollZoomOptions {
  /// Controls zoom sensitivity for mouse wheel events, when smooth zooming
  /// is enabled (as by default).
  ///
  /// Closer to zero = lower zoom offset per wheel tick.
  ///
  /// Defaults to `1 / 180`.
  final double wheelZoomRate;

  /// Controls zoom sensitivity for trackpad events, when smooth zooming is
  /// enabled (as by default).
  ///
  /// Closer to zero = lower zoom offset per trackpad gesture unit.
  ///
  /// Defaults to `1 / 100`.
  final double trackpadZoomRate;

  /// Duration of the easing animation for each mouse wheel tick, when smooth
  /// zooming is enabled (as by default).
  ///
  /// Each wheel tick triggers an animation of this duration. When multiple
  /// ticks arrive before the animation completes, the animations chain
  /// smoothly.
  ///
  /// Defaults to 200ms.
  final Duration animationDuration;

  /// Use and configure smooth scroll zooming.
  const SmoothScrollZoomOptions({
    this.wheelZoomRate = 1 / 180,
    this.trackpadZoomRate = 1 / 100,
    this.animationDuration = const Duration(milliseconds: 200),
  });

  @override
  bool operator ==(Object other) =>
      other is SmoothScrollZoomOptions &&
      wheelZoomRate == other.wheelZoomRate &&
      trackpadZoomRate == other.trackpadZoomRate &&
      animationDuration == other.animationDuration;

  @override
  int get hashCode => Object.hash(
        wheelZoomRate,
        trackpadZoomRate,
        animationDuration,
      );
}

/// When snap scroll zooming, each mouse wheel tick jumps immediately to the new
/// zoom level on each wheel event.
class SnapScrollZoomOptions extends ScrollZoomOptions {
  /// The multipler applied to the scroll offset to calculate the zoom offset,
  /// when smooth zooming is disabled.
  ///
  /// Closer to zero = lower zoom offset per scroll event.
  ///
  /// Defaults to `1 / 200`.
  final double zoomRate;

  /// Use and configure snap scroll zooming.
  const SnapScrollZoomOptions({
    this.zoomRate = 1 / 200,
  });

  @override
  bool operator ==(Object other) =>
      other is SnapScrollZoomOptions && zoomRate == other.zoomRate;

  @override
  int get hashCode => zoomRate.hashCode;
}

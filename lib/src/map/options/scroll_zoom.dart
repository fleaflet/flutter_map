import 'package:meta/meta.dart';

/// Options to configure scroll zoom behavior.
///
/// By default, scroll zoom uses smooth animated zooming inspired by
/// MapLibre GL JS. This can be disabled by setting [smoothZooming] to `false`,
/// which reverts to the old behavior of snapping immediately to the new
/// zoom level.
@immutable
class ScrollZoomOptions {
  /// Whether to use smooth animated zooming for mouse wheel events.
  ///
  /// When `true` (default), each mouse wheel tick triggers a short eased
  /// animation to the new zoom level. Rapid successive wheel ticks chain
  /// smoothly with velocity-continuous bezier curves.
  ///
  /// When `false`, zooming snaps immediately to the new zoom level on each
  /// wheel event, matching the pre-v8 behavior.
  ///
  /// Trackpad events are always applied directly regardless of this setting,
  /// since trackpad hardware already provides fine-grained continuous input.
  final bool smoothZooming;

  /// Controls zoom sensitivity for mouse wheel events in smooth mode.
  ///
  /// Lower values = slower zoom per wheel tick. Higher values = faster.
  ///
  /// Only used when [smoothZooming] is `true`.
  ///
  /// Defaults to `1 / 450`.
  final double wheelZoomRate;

  /// Controls zoom sensitivity for trackpad events.
  ///
  /// Lower values = slower zoom per trackpad gesture unit. Higher values =
  /// faster.
  ///
  /// Only used when [smoothZooming] is `true`.
  ///
  /// Defaults to `1 / 100`.
  final double trackpadZoomRate;

  /// Duration of the easing animation for each mouse wheel tick.
  ///
  /// Each wheel tick triggers an animation of this duration. When multiple
  /// ticks arrive before the animation completes, the animations chain
  /// smoothly.
  ///
  /// Only used when [smoothZooming] is `true`.
  ///
  /// Defaults to 200ms.
  final Duration animationDuration;

  /// Create scroll zoom options.
  const ScrollZoomOptions({
    this.smoothZooming = true,
    this.wheelZoomRate = 1 / 450,
    this.trackpadZoomRate = 1 / 100,
    this.animationDuration = const Duration(milliseconds: 200),
  })  : assert(wheelZoomRate > 0, '`wheelZoomRate` must be positive'),
        assert(trackpadZoomRate > 0, '`trackpadZoomRate` must be positive');

  /// Options that disable smooth zooming, reverting to the legacy snap
  /// behavior.
  const ScrollZoomOptions.snapping()
      : smoothZooming = false,
        wheelZoomRate = 1 / 450,
        trackpadZoomRate = 1 / 100,
        animationDuration = const Duration(milliseconds: 200);

  @override
  bool operator ==(Object other) =>
      other is ScrollZoomOptions &&
      smoothZooming == other.smoothZooming &&
      wheelZoomRate == other.wheelZoomRate &&
      trackpadZoomRate == other.trackpadZoomRate &&
      animationDuration == other.animationDuration;

  @override
  int get hashCode => Object.hash(
        smoothZooming,
        wheelZoomRate,
        trackpadZoomRate,
        animationDuration,
      );
}

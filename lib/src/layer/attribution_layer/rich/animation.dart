import 'package:flutter/widgets.dart';
import 'package:flutter_map/src/layer/attribution_layer/rich/widget.dart';

/// Animation provider interface for a [RichAttributionWidget]
///
/// The popup box's animation is handled/built by [popupAnimationBuilder] for
/// full flexibility.
///
/// The open/close button's animation is fixed to a fade animation provided by
/// [AnimatedSwitcher], but its curve and duration can still be customized
/// through [buttonDuration] and [buttonCurve].
///
/// Can be extensively customized by implementing a custom
/// [RichAttributionWidgetAnimation], or the prebuilt [FadeRAWA] and
/// [ScaleRAWA] animations can be used with limited customization.
@immutable
abstract interface class RichAttributionWidgetAnimation {
  /// The duration of the animation used when toggling the state of the
  /// open/close button
  ///
  /// The same duration is used between all three states, as described in
  /// [RichAttributionWidget]'s documentation.
  ///
  /// The animation used is always a fade provided by [AnimatedSwitcher].
  abstract final Duration buttonDuration;

  /// The curve of the animation used when toggling the state of the open/close
  /// button
  ///
  /// The same curve is used between all three states, as described in
  /// [RichAttributionWidget]'s documentation.
  ///
  /// The animation used is always a fade provided by [AnimatedSwitcher].
  abstract final Curve buttonCurve;

  /// Builder for the popup box animation
  ///
  /// Usually an [AnimatedWidget] controlled by [isExpanded], such as an
  /// [AnimatedOpacity] or [AnimatedScale], in which [child] is the child.
  ///
  /// The parent [RichAttributionWidget] is provided through [config], as it may
  /// contain some useful properties, such as [RichAttributionWidget.alignment].
  Widget popupAnimationBuilder({
    required BuildContext context,
    required bool isExpanded,
    required RichAttributionWidget config,
    required Widget child,
  });
}

/// Prebuilt animation provider for a [RichAttributionWidget]
///
/// Provides a scaling animation for the popup box, centered around
/// [RichAttributionWidget.alignment].
///
/// Allows further customisation of the popup box's animation duration and
/// curves, as well as the open/close button's.
@immutable
class ScaleRAWA implements RichAttributionWidgetAnimation {
  /// The duration of the animation used when toggling the state of the
  /// open/close button
  ///
  /// The same duration is used between all three states, as described in
  /// [RichAttributionWidget]'s documentation.
  ///
  /// The animation used is always a fade provided by [AnimatedSwitcher].
  @override
  final Duration buttonDuration;

  /// The curve of the animation used when toggling the state of the open/close
  /// button
  ///
  /// The same curve is used between all three states, as described in
  /// [RichAttributionWidget]'s documentation.
  ///
  /// The animation used is always a fade provided by [AnimatedSwitcher].
  @override
  final Curve buttonCurve;

  /// The duration of the animation used when toggling the visibility of the
  /// popup box
  final Duration popupDuration;

  /// The curve of the animation used when making the popup box visible
  final Curve popupCurveIn;

  /// The curve of the animation used when making the popup box invisible
  final Curve popupCurveOut;

  /// Prebuilt animation provider for a [RichAttributionWidget]
  ///
  /// Provides a scaling animation for the popup box, centered around
  /// [RichAttributionWidget.alignment].
  ///
  /// Allows further customisation of the popup box's animation duration and
  /// curves, as well as the open/close button's.
  const ScaleRAWA({
    this.popupDuration = const Duration(milliseconds: 200),
    this.popupCurveIn = Curves.easeIn,
    this.popupCurveOut = Curves.easeOut,
    this.buttonDuration = const Duration(milliseconds: 200),
    this.buttonCurve = Curves.easeInOut,
  });

  @override
  Widget popupAnimationBuilder({
    required BuildContext context,
    required bool isExpanded,
    required RichAttributionWidget config,
    required Widget child,
  }) =>
      AnimatedScale(
        scale: isExpanded ? 1 : 0,
        curve: isExpanded ? popupCurveOut : popupCurveIn,
        duration: buttonDuration,
        alignment: config.alignment.real,
        child: child,
      );
}

/// Prebuilt animation provider for a [RichAttributionWidget]
///
/// Provides a fading/opacity animation for the popup box.
///
/// Allows further customisation of the popup box's animation duration and
/// curves, as well as the open/close button's.
@immutable
class FadeRAWA implements RichAttributionWidgetAnimation {
  /// The duration of the animation used when toggling the state of the
  /// open/close button
  ///
  /// The same duration is used between all three states, as described in
  /// [RichAttributionWidget]'s documentation.
  ///
  /// The animation used is always a fade provided by [AnimatedSwitcher].
  @override
  final Duration buttonDuration;

  /// The curve of the animation used when toggling the state of the open/close
  /// button
  ///
  /// The same curve is used between all three states, as described in
  /// [RichAttributionWidget]'s documentation.
  ///
  /// The animation used is always a fade provided by [AnimatedSwitcher].
  @override
  final Curve buttonCurve;

  /// The duration of the animation used when toggling the visibility of the
  /// popup box
  final Duration popupDuration;

  /// The curve of the animation used when making the popup box visible
  final Curve popupCurveIn;

  /// The curve of the animation used when making the popup box invisible
  final Curve popupCurveOut;

  /// Prebuilt animation provider for a [RichAttributionWidget]
  ///
  /// Provides a fading/opacity animation for the popup box.
  ///
  /// Allows further customisation of the popup box's animation duration and
  /// curves, as well as the open/close button's.
  const FadeRAWA({
    this.popupDuration = const Duration(milliseconds: 200),
    this.popupCurveIn = Curves.easeIn,
    this.popupCurveOut = Curves.easeOut,
    this.buttonDuration = const Duration(milliseconds: 200),
    this.buttonCurve = Curves.easeInOut,
  });

  @override
  Widget popupAnimationBuilder({
    required BuildContext context,
    required bool isExpanded,
    required RichAttributionWidget config,
    required Widget child,
  }) =>
      AnimatedOpacity(
        opacity: isExpanded ? 1 : 0,
        curve: isExpanded ? popupCurveOut : popupCurveIn,
        duration: buttonDuration,
        child: IgnorePointer(
          ignoring: !isExpanded,
          child: child,
        ),
      );
}

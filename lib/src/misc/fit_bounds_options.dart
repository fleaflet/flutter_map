import 'package:flutter/widgets.dart';

@immutable
class FitBoundsOptions {
  final EdgeInsets padding;
  final double maxZoom;
  final bool inside;

  /// By default calculations will return fractional zoom levels.
  /// If this parameter is set to [true] fractional zoom levels will be round
  /// to the next suitable integer.
  final bool forceIntegerZoomLevel;

  @Deprecated(
    'Prefer `CameraFit.bounds` instead. '
    'This class has been renamed to clarify its meaning and is now a sublass of CameraFit to allow other fit types. '
    'This class is deprecated since v6.',
  )
  const FitBoundsOptions({
    this.padding = EdgeInsets.zero,
    this.maxZoom = 17.0,
    this.inside = false,
    this.forceIntegerZoomLevel = false,
  });
}

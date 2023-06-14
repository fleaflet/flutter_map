import 'package:flutter/widgets.dart';

class FitBoundsOptions {
  final EdgeInsets padding;
  final double maxZoom;
  final bool inside;

  /// By default calculations will return fractional zoom levels.
  /// If this parameter is set to [true] fractional zoom levels will be round
  /// to the next suitable integer.
  final bool forceIntegerZoomLevel;

  @Deprecated('Use FitFrame.bounds instead.')
  const FitBoundsOptions({
    this.padding = EdgeInsets.zero,
    this.maxZoom = 17.0,
    this.inside = false,
    this.forceIntegerZoomLevel = false,
  });
}

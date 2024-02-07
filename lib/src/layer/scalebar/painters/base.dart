part of '../scalebar.dart';

/// The base for a painter for a [Scalebar] widget
///
/// It is the [Scalebar]'s responsibility to calculate the scale and visual
/// sizing of the scale bar. It is the painter's responsibility to create the
/// visual information.
///
/// See also:
///  - [SimpleScalebarPainter] - a basic implementation
abstract base class ScalebarPainter extends CustomPainter {
  /// Internal parameter, do not use externally
  @protected
  abstract double scaleWidth;

  /// Internal parameter, do not use externally
  @protected
  abstract int scaleDistance;

  /// Generates a text representing distance based on a distance in meters
  final String Function(int distance) textGenerator;

  /// Style of the distance text
  final TextStyle? textStyle;

  final EdgeInsets padding;

  // TODO: Add alignment support

  ScalebarPainter({
    String Function(int dst)? textGenerator,
    this.textStyle = const TextStyle(color: Color(0xFF000000), fontSize: 14),
    this.padding = const EdgeInsets.all(12),
    // ignore: unnecessary_parenthesis
  }) : textGenerator = textGenerator ??= ((dst) =>
            dst > 999 ? '${(dst / 1000.0).toStringAsFixed(0)} km' : '$dst m');
}

part of '../scalebar.dart';

/// This painter is used in the [Scalebar] widget and ensures that all
/// [ScalebarPainter]s have a function to tell the widget what [Size]
/// it should have.
abstract class ScalebarPainter extends CustomPainter {
  /// The size of the [Scalebar] widget without any padding
  Size get widgetSize;
}

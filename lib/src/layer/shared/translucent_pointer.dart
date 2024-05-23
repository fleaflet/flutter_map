// ////////////////////////////////////////////////////////////////
// ///           Based on the work by Sander Kersten            ///
// ///    Migrated, and now maintained here for flexibility     ///
// /// https://github.com/spkersten/flutter_transparent_pointer ///
// ////////////////////////////////////////////////////////////////

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// A widget that is invisible for its parent during hit testing, but still
/// allows its subtree to receive pointer events
///
/// See also:
///
///  * [IgnorePointer], which is also invisible for its parent during hit
///    testing, but does not allow its subtree to receive pointer events.
///  * [AbsorbPointer], which is visible during hit testing, but prevents its
///    subtree from receiving pointer event. The opposite of this widget.
class TranslucentPointer extends SingleChildRenderObjectWidget {
  /// Creates a widget that is invisible for its parent during hit testing, but
  /// still allows its subtree to receive pointer events
  const TranslucentPointer({
    super.key,
    this.translucent = true,
    super.child,
  });

  /// Whether this widget is invisible to its parent during hit testing.
  ///
  /// Regardless of whether this render object is invisible to its parent during
  /// hit testing, it will still consume space during layout and be visible
  /// during painting.
  final bool translucent;

  @override
  RenderTranslucentPointer createRenderObject(BuildContext context) =>
      RenderTranslucentPointer(translucent: translucent);

  @override
  void updateRenderObject(
    BuildContext context,
    RenderTranslucentPointer renderObject,
  ) =>
      renderObject.translucent = translucent;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<bool>('translucent', translucent));
  }
}

/// A render object that is invisible to its parent during hit testing.
///
/// When [translucent] is true, this render object allows its subtree to receive
/// pointer events, whilst also not terminating hit testing at itself. It still
/// consumes space during layout and paints its child as usual. It just prevents
/// its children from being the termination of located events, because its render
/// object returns true from [hitTest].
///
/// See also:
///
///  * [RenderIgnorePointer], removing the subtree from considering entirely for
///    the purposes of hit testing.
///  * [RenderAbsorbPointer], which takes the pointer events but prevents any
///    nodes in the subtree from seeing them.
class RenderTranslucentPointer extends RenderProxyBox {
  /// Creates a render object that is invisible to its parent during hit testing
  RenderTranslucentPointer({
    RenderBox? child,
    bool translucent = true,
  })  : _translucent = translucent,
        super(child);

  /// Whether this widget is invisible to its parent during hit testing.
  ///
  /// Regardless of whether this render object is invisible to its parent during
  /// hit testing, it will still consume space during layout and be visible
  /// during painting.
  bool get translucent => _translucent;
  bool _translucent;

  set translucent(bool value) {
    if (value == _translucent) return;
    _translucent = value;
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    final hit = super.hitTest(result, position: position);
    return !translucent && hit;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<bool>('translucent', translucent));
  }
}

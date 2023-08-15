part of '../../map/widget.dart';

/// Provide an internal detection point for the overlay layer mixins
///
/// Although any other widget could be used as the detection point, this is
/// provided as close as possible to the mixin-ed widgets to reduce the number of
/// iterations `context.visitAncestorElements` requires to ascertain whether
/// the mixin is being used correctly.
class _OverlayLayerDetectorAncestor extends StatelessWidget {
  const _OverlayLayerDetectorAncestor({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => child;

  static Widget _buildDetector(BuildContext context) {
    context.visitAncestorElements((e) {
      if (e.widget is _OverlayLayerDetectorAncestor) return false;

      throw FlutterError(
        'The widget with `OverlayLayer*Mixin` (or `OverlayLayer`) must only be '
        'used as a top level widget in `FlutterMap.children`\n'
        'Failure to do so will mean that the layer behaves as a normal layer.\n'
        'To resolve this:\n'
        " * if you're using a provided layer beneath this widget, check if it "
        'already includes the appropriate mixin, in which case, remove this '
        'widget\n'
        " * if you're using a custom widget beneath this widget, ensure it is a "
        'top level widget in `FlutterMap.children`, and swap widgets if '
        'necessary\n',
      );
    });

    // The user shouldn't build the output of this method
    return Builder(
      builder: (_) => throw FlutterError(
        'Widgets that mixin `OverlayLayer*Mixin` must call '
        '`super.build(context)`, but must also ignore the return value',
      ),
    );
  }
}

/// Apply to a [StatelessWidget] to transform it into an overlay widget that is
/// anchored and does not move with the map
///
/// The widget mixing this in must always be a top level widget in
/// [FlutterMap.children], ie. it must not be a child of another widget. Failure
/// to do this will throw an error, as the behaviour will not be correct.
///
/// Always call `super.build(context)` from within the widget's `build` method.
/// Ignore its result, and build children as normal.
///
/// See also:
///
///  * [OverlayLayer], which mixes this onto a standard child widget
///  * [OverlayLayerStateMixin], which is the equivalent for [StatefulWidget]s
mixin OverlayLayerStatelessMixin on StatelessWidget {
  @override
  @mustCallSuper
  Widget build(BuildContext context) =>
      _OverlayLayerDetectorAncestor._buildDetector(context);
}

/// Apply to a [State] to transform it into an overlay widget that is anchored
/// and does not move with the map
///
/// Must be paired with an [OverlayLayerStatefulMixin] on the [StatefulWidget].
///
/// The widget mixing this in must always be a top level widget in
/// [FlutterMap.children], ie. it must not be a child of another widget. Failure
/// to do this will throw an error, as the behaviour will not be correct.
///
/// Always call `super.build(context)` from within the widget's `build` method.
/// Ignore its result, and build children as normal.
///
/// See also:
///
///  * [OverlayLayer], which mixes [OverlayLayerStatelessMixin] onto a
///    standard child widget
///  * [OverlayLayerStatelessMixin], which is the equivalent for
///    [StatelessWidget]s
mixin OverlayLayerStateMixin<
        T extends OverlayLayerStatefulMixin<OverlayLayerStateMixin<T>>>
    on State<T> {
  @override
  @mustCallSuper
  Widget build(BuildContext context) =>
      _OverlayLayerDetectorAncestor._buildDetector(context);
}

/// Apply to a [StatefulWidget] to transform it into an overlay widget that is
/// anchored and does not move with the map
///
/// Must be paired with an [OverlayLayerStateMixin] on the [State].
///
/// The widget mixing this in must always be a top level widget in
/// [FlutterMap.children], ie. it must not be a child of another widget. Failure
/// to do this will throw an error, as the behaviour will not be correct.
///
/// Always call `super.build(context)` from within the widget's `build` method.
/// Ignore its result, and build children as normal.
///
/// See also:
///
///  * [OverlayLayer], which mixes [OverlayLayerStatelessMixin] onto a
///    standard child widget
///  * [OverlayLayerStatelessMixin], which is the equivalent for
///    [StatelessWidget]s
mixin OverlayLayerStatefulMixin<T extends State<OverlayLayerStatefulMixin<T>>>
    on StatefulWidget {
  @override
  OverlayLayerStateMixin createState();
}

/// {@template overlay_layer}
/// Transforms the [child] widget into an overlay layer that is anchored and
/// does not move with the map
///
/// This widget must always be a top level widget in [FlutterMap.children], ie.
/// it must not be a child of another widget. Failure to do this will throw an
/// error, as the behaviour will not be correct.
///
/// Some layers include the appropriate mixins, if they are not intended to be
/// used in a non-overlay scenario, such as the [AttributionWidget]s. If this is
/// the case, those layers should document this behaviour, as applying an
/// additional [OverlayLayer] transformer will cause an erroneous result.
///
/// If you have control over the [child], prefer mixing in
/// [OverlayLayerStatelessMixin] or [OverlayLayerStatefulMixin] /
/// [OverlayLayerStateMixin] yourself, to avoid an extra widget in the tree.
/// {@endtemplate}
class OverlayLayer extends StatelessWidget with OverlayLayerStatelessMixin {
  /// {@macro overlay_layer}
  const OverlayLayer({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return child;
  }
}

part of '../../map/widget.dart';

/// A layer that is anchored to the map, that does not move with the other layers
///
/// There are multiple ways to add an anchored layer to the map, in order of
/// preference:
///
///  1. Apply [AnchoredLayerStatelessMixin] to a [StatelessWidget]
///  2. Apply [AnchoredLayerStatefulMixin] to a [StatefulWidget], and
///     [AnchoredLayerStateMixin] to its corresponding [State]
///  3. Wrap the widget with an [AnchoredLayerTransformer]
///
/// This layer may be used in both [FlutterMap.children] and
/// [FlutterMap.overlaidAnchoredChildren]. See documentation on those properties
/// for more information.
///
/// {@template anchored_layer_warning}
/// [AnchoredLayer]s must be on the top-level of [FlutterMap.children] or
/// [FlutterMap.overlaidAnchoredChildren]. They must also not be multiplied as an
/// ancestor or child: use only one. Failure to do this will throw an error, as
/// the anchored effect will not be correctly applied. See below for common
/// mistakes and their resolutions:
///
///  * If you have control over the widget, do not use [AnchoredLayerTransformer]
/// in its `build` method. Prefer using the appropriate mixin, or wrap the
/// transformer around every instance of the widget.
///  * If the widget already uses a mixin, do not use [AnchoredLayerTransformer]
/// in addition. These widgets are designed to be used as an anchored layer only,
/// and need no additional setup. These widgets should contain a notice in the
/// documentation.
/// {@endtemplate}
sealed class AnchoredLayer extends Widget {
  const AnchoredLayer._();
}

/// Provide an internal detection point for the [AnchoredLayer]s
///
/// Although any other widget could be used as the detection point, this is
/// provided as close as possible to the mixin-ed widgets to allow only one
/// `context.visitAncestorElements` iteration to determine whether usage is
/// correct.
///
/// ---
///
/// Explanation of how [AnchoredLayer]s work internally:
///
///  1. A [Widget] is converted to an [AnchoredLayer] by means of the mixins, or
///     the [AnchoredLayerTransformer] (which uses the mixins behind the scenes).
///  2. The mixin means the affected [Widget] must call the mixin's own `build`
///     method, which calls [_detectAncestor].
///  3. [_detectAncestor] performs a single lookup to the direct ancestor, to
///     check whether it is an [_AnchoredLayerDetectorAncestor], throwing if it
///     isn't, because it will not have the next step applied
///  4. When laying out the layers, [_LayersStack] avoids applying rotation to
///     any widget that has mixed-in one of the mixins, whilst the layer itself
///     doesn't follow the map movement - resulting in an 'anchored' layer.
class _AnchoredLayerDetectorAncestor extends StatelessWidget {
  const _AnchoredLayerDetectorAncestor({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => child;

  static Widget _detectAncestor(BuildContext context) {
    context.visitAncestorElements((e) {
      if (e.widget is _AnchoredLayerDetectorAncestor) return false;

      throw FlutterError.fromParts([
        ErrorSummary(
          '`AnchoredLayer` (such as `AnchoredLayerTransformer` or one of the '
          'mixins) was used incorrectly.',
        ),
        ErrorDescription(
          'Instead of `_AnchoredLayerDetectorAncestor`, the direct ancestor was '
          'of type `${e.widget.runtimeType}`.',
        ),
        ErrorHint(
          'Ensure that there is only one `AnchoredLayer`, and that it is a '
          'top-level widget of `children` or `overlaidAnchoredChildren`. Read '
          'the documentation on `AnchoredLayer` for more information.',
        )
      ]);
    });

    // The user shouldn't build the output of this method
    return Builder(
      builder: (_) => throw FlutterError(
        'Widgets that mixin `AnchoredLayer*Mixin` must call '
        '`super.build(context)`, but must also ignore the return value',
      ),
    );
  }
}

/// Transforms the [child] widget into an [AnchoredLayer]
///
/// Uses a [AnchoredLayerStatelessMixin] internally.
///
/// {@template anchored_layer_more_info}
/// See [AnchoredLayer] for more information about other methods to create an
/// anchored layer.
/// {@endtemplate}
///
/// ---
///
/// {@macro anchored_layer_warning}
class AnchoredLayerTransformer extends StatelessWidget
    with AnchoredLayerStatelessMixin
    implements AnchoredLayer {
  /// Transforms the [child] widget into an [AnchoredLayer]
  ///
  /// Uses a [AnchoredLayerStatelessMixin] internally.
  ///
  /// ---
  ///
  /// {@macro anchored_layer_warning}
  const AnchoredLayerTransformer({
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

/// Apply to a [StatelessWidget] to transform it into an [AnchoredLayer]
///
/// {@macro anchored_layer_call_super}
///
/// {@macro anchored_layer_more_info}
///
/// ---
///
/// {@macro anchored_layer_warning}
mixin AnchoredLayerStatelessMixin on StatelessWidget implements AnchoredLayer {
  @override
  @mustCallSuper
  Widget build(BuildContext context) =>
      _AnchoredLayerDetectorAncestor._detectAncestor(context);
}

/// Apply to a [StatefulWidget] to transform it into an [AnchoredLayer]
///
/// Must be paired with an [AnchoredLayerStateMixin] on the [State], and this
/// object's [createState] method must return an instance of
/// [AnchoredLayerStateMixin]. See [RichAttributionWidget] for an example of
/// this.
///
/// {@template anchored_layer_call_super}
/// Always call `super.build(context)` from within the widget's `build` method,
/// but ignore its result and build children as normal.
/// {@endtemplate}
///
/// {@macro anchored_layer_more_info}
///
/// ---
///
/// {@macro anchored_layer_warning}
mixin AnchoredLayerStatefulMixin<T extends State<AnchoredLayerStatefulMixin<T>>>
    on StatefulWidget implements AnchoredLayer {
  @override
  AnchoredLayerStateMixin createState();
}

/// Apply to a [State] to transform its corresponding [StatefulWidget] into an
/// [AnchoredLayer]
///
/// Must be paired with an [AnchoredLayerStatefulMixin] on the [State]. See
/// [RichAttributionWidget] for an example of this.
///
/// {@macro anchored_layer_call_super}
///
/// {@macro anchored_layer_more_info}
///
/// ---
///
/// {@macro anchored_layer_warning}
mixin AnchoredLayerStateMixin<
        T extends AnchoredLayerStatefulMixin<AnchoredLayerStateMixin<T>>>
    on State<T> {
  @override
  @mustCallSuper
  Widget build(BuildContext context) =>
      _AnchoredLayerDetectorAncestor._detectAncestor(context);
}

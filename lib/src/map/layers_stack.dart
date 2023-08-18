part of 'widget.dart';

class _LayersStack extends StatefulWidget {
  const _LayersStack({
    required this.camera,
    required this.options,
    required this.children,
  });

  final MapCamera camera;
  final MapOptions options;
  final List<Widget> children;

  @override
  State<_LayersStack> createState() => _LayersStackState();
}

class _LayersStackState extends State<_LayersStack> {
  List<Widget> children = [];

  Iterable<Widget> _prepareChildren() sync* {
    final stackChildren = <Widget>[];

    Widget prepareRotateStack() {
      final box = OverflowBox(
        minWidth: widget.camera.size.x,
        maxWidth: widget.camera.size.x,
        minHeight: widget.camera.size.y,
        maxHeight: widget.camera.size.y,
        child: Transform.rotate(
          angle: widget.camera.rotationRad,
          child: Stack(children: List.of(stackChildren)),
        ),
      );
      stackChildren.clear();
      return box;
    }

    for (final Widget child in widget.children) {
      if (child is AnchoredLayerStatefulMixin ||
          child is AnchoredLayerStatelessMixin) {
        if (stackChildren.isNotEmpty) yield prepareRotateStack();
        final overlayChild = _AnchoredLayerDetectorAncestor(child: child);
        yield widget.options.applyPointerTranslucencyToLayers
            ? TranslucentPointer(child: overlayChild)
            : overlayChild;
      } else {
        stackChildren.add(
          widget.options.applyPointerTranslucencyToLayers
              ? TranslucentPointer(child: child)
              : child,
        );
      }
    }
    if (stackChildren.isNotEmpty) yield prepareRotateStack();
  }

  @override
  void initState() {
    super.initState();
    children = _prepareChildren().toList();
  }

  @override
  void didUpdateWidget(covariant _LayersStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.children != oldWidget.children ||
        widget.camera != oldWidget.camera ||
        widget.options.applyPointerTranslucencyToLayers !=
            oldWidget.options.applyPointerTranslucencyToLayers) {
      children = _prepareChildren().toList();
    }
  }

  @override
  Widget build(BuildContext context) => Stack(children: children);
}

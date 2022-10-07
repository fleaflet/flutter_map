import 'package:flutter/material.dart';

class AttributionLayer extends StatefulWidget {
  const AttributionLayer.custom({
    super.key,
    required Widget Function(BuildContext context) customBuilder,
  })  : _customBuilder = customBuilder,
        attributions = null,
        alignment = Alignment.bottomRight,
        backgroundColor = const Color(0xCCFFFFFF),
        animationDuration = const Duration(milliseconds: 250),
        animationCurve = Curves.fastOutSlowIn;

  const AttributionLayer({
    super.key,
    this.attributions,
    this.alignment = Alignment.bottomRight,
    this.backgroundColor = const Color(0xCCFFFFFF),
    this.animationDuration = const Duration(milliseconds: 250),
    this.animationCurve = Curves.fastOutSlowIn,
  }) : _customBuilder = null;

  final Widget Function(BuildContext context)? _customBuilder;

  final Map<Text, void Function()>? attributions;
  final Alignment alignment;
  final Color backgroundColor;

  final Duration animationDuration;
  final Curve animationCurve;

  @override
  State<AttributionLayer> createState() => _AttributionLayerState();
}

class _AttributionLayerState extends State<AttributionLayer>
    with TickerProviderStateMixin {
  late final _animationController = AnimationController(
    duration: widget.animationDuration,
    vsync: this,
  );
  late final _animation = CurvedAnimation(
    parent: _animationController,
    curve: widget.animationCurve,
  );

  late final Map<Text, void Function()> _attributions = {
    ...widget.attributions ?? {},
    const Text('flutter_map & the authors'): () {},
  };

  @override
  Widget build(BuildContext context) => widget._customBuilder != null
      ? widget._customBuilder!(context)
      : Align(
          alignment: widget.alignment,
          child: ColoredBox(
            color: widget.backgroundColor,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
              child: GestureDetector(
                onTap: () {
                  if (_animation.status != AnimationStatus.completed) {
                    _animationController.forward();
                  } else {
                    _animationController.reverse();
                  }
                },
                child: IntrinsicWidth(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizeTransition(
                        sizeFactor: _animation,
                        axis: Axis.vertical,
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              ..._attributions.keys.toList(),
                              const Divider(),
                            ],
                          ),
                        ),
                      ),
                      const Text('Show Map Attributions'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
}

/*/// Attribution widget layer, usually placed in `nonRotatedChildren`
///
/// Can be anchored in a position of the map using [alignment], defaulting to [Alignment.bottomRight]. Then pass [attributionBuilder] to build your custom attribution widget.
///
/// Alternatively, use the constructor [defaultWidget] to get a more classic styled attibution box.
class AttributionLayer extends StatelessWidget {
  /// Function that returns a widget given a [BuildContext], displayed on the map
  final WidgetBuilder attributionBuilder;

  /// Anchor the widget in a position of the map, defaulting to [Alignment.bottomRight]
  final Alignment alignment;

  /// Attribution widget layer, usually placed in `nonRotatedChildren`
  ///
  /// Can be anchored in a position of the map using [alignment], defaulting to [Alignment.bottomRight]. Then pass [attributionBuilder] to build your custom attribution widget.
  ///
  /// Alternatively, use the constructor [defaultWidget] to get a more classic styled attibution box.
  const AttributionLayer({
    Key? key,
    required this.attributionBuilder,
    this.alignment = Alignment.bottomRight,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) =>
      Align(alignment: alignment, child: attributionBuilder(context));

  /// Quick constructor for a more classic styled attibution box
  ///
  /// Displayed as a padded translucent white box with the following text: 'flutter_map | © [source]'.
  ///
  /// Provide [onSourceTapped] to carry out a function when the box is tapped. If that isn't null, the source text will have [sourceTextStyle] styling - which defaults to a link styling.
  static Widget defaultWidget({
    required String source,
    void Function()? onSourceTapped,
    TextStyle sourceTextStyle = const TextStyle(color: Color(0xFF0078a8)),
    Alignment alignment = Alignment.bottomRight,
  }) =>
      Align(
        alignment: alignment,
        child: ColoredBox(
          color: const Color(0xCCFFFFFF),
          child: GestureDetector(
            onTap: onSourceTapped,
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('flutter_map | © '),
                  MouseRegion(
                    cursor: onSourceTapped == null
                        ? MouseCursor.defer
                        : SystemMouseCursors.click,
                    child: Text(
                      source,
                      style: onSourceTapped == null ? null : sourceTextStyle,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
*/
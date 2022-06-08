import 'package:flutter/widgets.dart';

/// Attribution widget layer, usually placed in `nonRotatedChildren`
///
/// Can be anchored in a position of the map using [alignment], defaulting to [Alignment.bottomRight]. Then pass [attributionBuilder] to build your custom attribution widget.
///
/// Alternatively, use the constructor [defaultWidget] to get a more classic styled attibution box.
class AttributionWidget extends StatelessWidget {
  /// Function that returns a widget given a [BuildContext], displayed on the map
  final WidgetBuilder attributionBuilder;

  /// Anchor the widget in a position of the map, defaulting to [Alignment.bottomRight]
  final Alignment alignment;

  /// Attribution widget layer, usually placed in `nonRotatedChildren`
  ///
  /// Can be anchored in a position of the map using [alignment], defaulting to [Alignment.bottomRight]. Then pass [attributionBuilder] to build your custom attribution widget.
  ///
  /// Alternatively, use the constructor [defaultWidget] to get a more classic styled attibution box.
  const AttributionWidget({
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

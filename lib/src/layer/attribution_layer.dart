import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// A simple attribution widget layer, usually placed in `nonRotatedChildren`
///
/// Can be anchored in a position of the map using [alignment], defaulting to [Alignment.bottomRight]. Then pass [attributionBuilder] to build your custom attribution widget.
///
/// Alternatively, use the constructor [defaultWidget] to get a more classic styled attribution box.
class AttributionWidget extends StatelessWidget {
  /// Function that returns a widget given a [BuildContext], displayed on the map
  final WidgetBuilder attributionBuilder;

  /// Anchor the widget in a position of the map, defaulting to [Alignment.bottomRight]
  final Alignment alignment;

  /// Attribution widget layer, usually placed in `nonRotatedChildren`
  ///
  /// Can be anchored in a position of the map using [alignment], defaulting to [Alignment.bottomRight]. Then pass [attributionBuilder] to build your custom attribution widget.
  ///
  /// Alternatively, use the constructor [defaultWidget] to get a more classic styled attribution box.
  const AttributionWidget({
    Key? key,
    required this.attributionBuilder,
    this.alignment = Alignment.bottomRight,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) =>
      Align(alignment: alignment, child: attributionBuilder(context));

  /// Quick constructor for a classic styled attribution box with a single source.
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
      AttributionWidget(
        alignment: alignment,
        attributionBuilder: (context) => ColoredBox(
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

/// Base class for attributions that render themselves as widgets
abstract class SourceAttribution extends StatelessWidget {
  final Future<bool>? Function()? onTap;

  const SourceAttribution({super.key, this.onTap});

  SourceAttribution.launchUri(Uri launchUri, {super.key})
      : onTap = (() => launchUrl(launchUri));

  Widget render(BuildContext context);

  @override
  @nonVirtual
  Widget build(BuildContext context) {
    if (onTap == null) {
      return render(context);
    } else {
      return GestureDetector(
        onTap: onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: render(context),
        ),
      );
    }
  }
}

/// A source attribution in the form of text
class TextSourceAttribution extends SourceAttribution {
  static const TextStyle _defaultTextStyle = TextStyle(
    color: Color(0xFF0000EE),
    decoration: TextDecoration.underline,
  );

  final String text;
  final TextStyle? textStyle;
  final bool prependCopyright;

  /// If [prependCopyright] is set to `true`, a copyright symbol will
  /// be prepended to the text. [textStyle] is optional and is
  /// only necessary if you want to change styling from the defaults.
  /// If no style is specified and an [onTap] function is
  /// provided, the text will have a classic hyperlink blue color.
  const TextSourceAttribution(
    this.text, {
    super.key,
    super.onTap,
    this.prependCopyright = true,
    TextStyle? textStyle,
  }) : textStyle = textStyle ?? (onTap == null ? null : _defaultTextStyle);

  /// A simplified constructor which launches [launchUri] on tap.
  TextSourceAttribution.launchUri(
    this.text, {
    super.key,
    required Uri launchUri,
    this.prependCopyright = true,
    TextStyle? textStyle,
  })  : textStyle = textStyle ?? _defaultTextStyle,
        super.launchUri(launchUri);

  @override
  Widget render(BuildContext context) => Text(
        '${prependCopyright ? '© ' : ''}$text',
        style: textStyle,
      );
}

class LogoSourceAttribution extends SourceAttribution {
  final Image image;

  const LogoSourceAttribution({
    super.key,
    required this.image,
    super.onTap,
  });

  LogoSourceAttribution.launchUri({
    super.key,
    required this.image,
    required Uri launchUri,
  }) : super.launchUri(launchUri);

  @override
  Widget render(BuildContext context) => image;
}

/// A rich attribution layer which makes it straightforward to attribute
/// multiple sources in a way that looks good across devices.
///
/// The widget consists of an info button which toggles display of the textual
/// source attributions on click/tap (hidden by default to save screen real
/// estate). Logo attributions are always visible.
class RichAttributionWidget extends StatefulWidget {
  final Widget _attributionColumn;
  final Alignment alignment;
  final List<LogoSourceAttribution> _logoSourceAttributions;

  RichAttributionWidget({
    super.key,
    required List<SourceAttribution> attributions,
    this.alignment = Alignment.bottomRight,
  })  : _attributionColumn = Padding(
          padding: const EdgeInsets.all(3),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...attributions
                  .where((e) => e is! LogoSourceAttribution)
                  .toList(),
              const SizedBox(height: 32),
            ],
          ),
        ),
        _logoSourceAttributions = attributions
            .whereType<LogoSourceAttribution>()
            .toList()
          ..add(
            LogoSourceAttribution.launchUri(
              image: Image.asset(
                'lib/assets/flutter_map_logo.png',
                package: 'flutter_map',
                height: 24,
                width: 24,
                cacheHeight: 24,
                cacheWidth: 24,
              ),
              launchUri: Uri.parse('https://github.com/fleaflet/flutter_map'),
            ),
          );

  @override
  State<StatefulWidget> createState() => RichAttributionWidgetState();
}

class RichAttributionWidgetState extends State<RichAttributionWidget> {
  bool _expanded = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) => Align(
        alignment: widget.alignment,
        child: Stack(
          alignment: widget.alignment,
          children: [
            AnimatedOpacity(
              opacity: _expanded ? 1 : 0,
              curve: Curves.easeInOut,
              duration: const Duration(milliseconds: 200),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(width: 0, style: BorderStyle.none),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: widget._attributionColumn,
                ),
              ),
            ),
            MouseRegion(
              onEnter: (_) => setState(() => _hovered = true),
              onExit: (_) => setState(() => _hovered = false),
              cursor: SystemMouseCursors.click,
              child: AnimatedOpacity(
                opacity: _hovered || _expanded ? 1 : 0.5,
                curve: Curves.easeInOut,
                duration: const Duration(milliseconds: 200),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ...widget._logoSourceAttributions.cast<Widget>(),
                      AnimatedSwitcher(
                        switchInCurve: Curves.easeInOut,
                        switchOutCurve: Curves.easeInOut,
                        duration: const Duration(milliseconds: 200),
                        child: _expanded
                            ? IconButton(
                                onPressed: () =>
                                    setState(() => _expanded = false),
                                icon: const Icon(Icons.cancel_outlined),
                              )
                            : IconButton(
                                onPressed: () =>
                                    setState(() => _expanded = true),
                                icon: const Icon(Icons.info_outline),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}

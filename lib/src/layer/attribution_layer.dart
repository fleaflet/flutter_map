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
  final void Function()? onTap;

  const SourceAttribution({super.key, this.onTap});

  SourceAttribution.launchUri(Uri launchUri, {super.key})
      : onTap = (() async {
          if (!await launchUrl(launchUri)) {
            debugPrint("Could not launch URL.");
          }
        });

  /// Method returning a widget that must be implemented by subclasses.
  ///
  /// NOTE: Subclasses should NOT override build but rather render, as
  /// the build method is responsible for adding tap detection if necessary.
  @required
  Widget render(BuildContext context);

  @override
  Widget build(BuildContext context) {
    if (onTap == null) {
      return render(context);
    } else {
      return GestureDetector(
          onTap: onTap,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: render(context),
          ));
    }
  }
}

/// A source attribution in the form of text
class TextSourceAttribution extends SourceAttribution {
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
    this.prependCopyright = true,
    super.onTap,
    this.textStyle,
  });

  /// A simplified constructor which launches [launchUri] on tap.
  TextSourceAttribution.launchUri(this.text,
      {super.key,
      required Uri launchUri,
      this.prependCopyright = true,
      this.textStyle})
      : super.launchUri(launchUri);

  @override
  Widget render(BuildContext context) {
    final String prefix;
    if (prependCopyright) {
      prefix = "© ";
    } else {
      prefix = "";
    }

    final TextStyle? style;
    if (textStyle == null && onTap != null) {
      // If no style is specified and there is a tap action, default to a
      // classic blue hyperlink color.
      style = const TextStyle(color: Color(0xFF0078a8));
    } else {
      style = textStyle;
    }

    return Text(
      "$prefix$text",
      style: style,
    );
  }
}

class LogoSourceAttribution extends SourceAttribution {
  final ImageProvider imageProvider;

  const LogoSourceAttribution(
      {super.key, required this.imageProvider, super.onTap});

  LogoSourceAttribution.asset(String assetName,
      {super.key, AssetBundle? assetBundle, String? package, super.onTap})
      : imageProvider = AssetImage(
          assetName,
          bundle: assetBundle,
          package: package,
        );

  LogoSourceAttribution.network(String url, {super.key, super.onTap})
      : imageProvider = NetworkImage(url);

  LogoSourceAttribution.networkWithLaunchUri(String url,
      {super.key, required Uri launchUri})
      : imageProvider = NetworkImage(url),
        super.launchUri(launchUri);

  @override
  Widget render(BuildContext context) =>
      Image(image: imageProvider, height: 24);
}

/// A rich attribution layer which makes it straightforward to attribute
/// multiple sources in a way that looks good across devices.
///
/// The widget consists of an info button which toggles display of the textual
/// source attributions on click/tap (hidden by default to save screen real
/// estate). Logo attributions are always visible.
class RichAttributionWidget extends StatefulWidget {
  final Widget attributionColumn;
  final Alignment alignment;
  final Iterable<LogoSourceAttribution> logoSourceAttributions;

  RichAttributionWidget({
    super.key,
    required List<SourceAttribution> attributions,
    this.alignment = Alignment.bottomRight,
  })  : attributionColumn = Padding(
          padding: const EdgeInsets.all(3),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: attributions
                .where((element) => element is! LogoSourceAttribution)
                .toList(),
          ),
        ),
        logoSourceAttributions =
            attributions.whereType<LogoSourceAttribution>().followedBy([
          LogoSourceAttribution.networkWithLaunchUri(
              "https://www.gitbook.com/cdn-cgi/image/width=40,height=40,fit=contain,dpr=2,format=auto/https%3A%2F%2F3512747269-files.gitbook.io%2F~%2Ffiles%2Fv0%2Fb%2Fgitbook-x-prod.appspot.com%2Fo%2Fspaces%252F71h39XIuA0UETMZNP1yW%252Ficon%252Fl1Sl5MTPazDxdLxZLRG2%252FIconV1.png%3Falt%3Dmedia%26token%3Dc946a6a0-e5ff-45a4-a247-79a9059ff8ea",
              launchUri: Uri.parse("https://github.com/fleaflet/flutter_map"))
        ]);

  @override
  State<StatefulWidget> createState() => RichAttributionWidgetState();
}

class RichAttributionWidgetState extends State<RichAttributionWidget> {
  bool _expand = false;

  void onPressed() {
    setState(() {
      _expand = !_expand;
    });
  }

  @override
  Widget build(BuildContext context) {
    final IconButton button =
        IconButton(onPressed: onPressed, icon: const Icon(Icons.info_outline));
    const boxColor = Color(0xCCFFFFFF);
    const insets = EdgeInsets.all(8);
    final directionality = Directionality.maybeOf(context) ?? TextDirection.ltr;

    final bottomRow = Row(
      mainAxisSize: MainAxisSize.min,
      children: widget.logoSourceAttributions
          .cast<Widget>()
          .followedBy([button]).toList(),
    );
    if (_expand) {
      return Align(
          alignment: widget.alignment,
          child: Container(
              decoration: BoxDecoration(
                  color: boxColor,
                  border: Border.all(width: 0, style: BorderStyle.none),
                  borderRadius: BorderRadius.circular(10)),
              margin: insets,
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  textDirection: directionality,
                  // Align the items in the column (ex: the info button) to the
                  // left if we are using an alignment toward the left edge
                  // of the screen; otherwise align them to the right.
                  crossAxisAlignment: widget.alignment.x < 0
                      ? (directionality == TextDirection.ltr
                          ? CrossAxisAlignment.start
                          : CrossAxisAlignment.end)
                      : (directionality == TextDirection.ltr
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start),
                  children: [widget.attributionColumn, bottomRow])));
    } else {
      return Align(
          alignment: widget.alignment,
          child: Container(
            margin: insets,
            child: bottomRow,
          ));
    }
  }
}

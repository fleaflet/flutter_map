import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:meta/meta.dart';

/// Position to anchor [RichAttributionWidget] to relative to the [FlutterMap]
///
/// Reflects standard [Alignment] through [real], but limits to the only
/// supported options.
enum AttributionAlignment {
  /// The bottom left corner
  bottomLeft(Alignment.bottomLeft),

  /// The bottom right corner
  bottomRight(Alignment.bottomRight);

  /// Position to anchor [RichAttributionWidget] to relative to the [FlutterMap]
  ///
  /// Reflects standard [Alignment] through [real], but limits to the only
  /// supported options.
  const AttributionAlignment(this.real);

  /// Reflects the standard [Alignment]
  @internal
  final Alignment real;
}

/// A simple, classic style, attribution widget, to be placed in
/// [FlutterMap.nonRotatedChildren]
///
/// Displayed as a padded translucent [backgroundColor] box with the following
/// text: 'flutter_map | © [source]', where [source] is wrapped with [onTap].
class SimpleAttributionWidget extends StatelessWidget {
  /// Attribution text, such as 'OpenStreetMap contributors'
  final Text source;

  /// Callback called when [source] is tapped/clicked
  final VoidCallback? onTap;

  /// Color of the box containing the [source] text
  final Color? backgroundColor;

  /// Anchor the widget in a position of the map
  final Alignment alignment;

  /// A simple, classic style, attribution widget, to be placed in
  /// [FlutterMap.nonRotatedChildren]
  ///
  /// Displayed as a padded translucent white box with the following text:
  /// 'flutter_map | © [source]'.
  const SimpleAttributionWidget({
    Key? key,
    required this.source,
    this.onTap,
    this.backgroundColor,
    this.alignment = Alignment.bottomRight,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => Align(
        alignment: alignment,
        child: ColoredBox(
          color: backgroundColor ?? Theme.of(context).colorScheme.background,
          child: GestureDetector(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('flutter_map | © '),
                  MouseRegion(
                    cursor: onTap == null
                        ? MouseCursor.defer
                        : SystemMouseCursors.click,
                    child: source,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

/// Base class for attributions that render themselves as widgets
///
/// Extended/implemented by [TextSourceAttribution] & [LogoSourceAttribution].
@internal
abstract class SourceAttribution extends StatelessWidget {
  final VoidCallback? _onTap;

  const SourceAttribution._({
    super.key,
    VoidCallback? onTap,
  }) : _onTap = onTap;

  Widget _render(BuildContext context);

  @override
  @nonVirtual
  Widget build(BuildContext context) {
    if (_onTap == null) return _render(context);

    return GestureDetector(
      onTap: _onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: _render(context),
      ),
    );
  }
}

/// A simple text attribution displayed in the popup box of a
/// [RichAttributionWidget]
class TextSourceAttribution extends SourceAttribution {
  /// Default style used to display the [text], only when
  /// [SourceAttribution._onTap] is not `null`
  static const defaultLinkTextStyle =
      TextStyle(decoration: TextDecoration.underline);

  /// The text to display as attribution, styled with [textStyle]
  final String text;

  /// Style used to display the [text]
  final TextStyle? textStyle;

  /// Whether to add the '©' character to the start of [text] automatically
  final bool prependCopyright;

  /// A simple text attribution displayed in the popup box of a
  /// [RichAttributionWidget]
  const TextSourceAttribution(
    this.text, {
    super.key,
    super.onTap,
    this.prependCopyright = true,
    TextStyle? textStyle,
  })  : textStyle = textStyle ?? (onTap == null ? null : defaultLinkTextStyle),
        super._();

  @override
  Widget _render(BuildContext context) => Text(
        '${prependCopyright ? '© ' : ''}$text',
        style: textStyle,
      );
}

/// An image attribution permanently displayed adjacent to the open/close icon of
/// a [RichAttributionWidget]
class LogoSourceAttribution extends SourceAttribution {
  /// The logo to display as attribution, usually an [Image.asset] or
  /// [Image.network]
  final Widget image;

  /// Optional text to display inside a [Tooltip] when the logo is hovered over,
  /// to provide extra clarity
  final String? tooltip;

  /// Height of the [image] (fitted into a [SizedBox])
  ///
  /// Should be the same as [RichAttributionWidget.permanentHeight], otherwise
  /// layout issues may occur.
  final double height;

  /// An image attribution permanently displayed adjacent to the open/close icon
  /// of a [RichAttributionWidget]
  const LogoSourceAttribution(
    this.image, {
    super.key,
    super.onTap,
    this.tooltip,
    this.height = 24,
  }) : super._();

  @override
  Widget _render(BuildContext context) {
    final sizedImage = SizedBox(height: height, child: image);
    if (tooltip == null) return sizedImage;
    return Tooltip(message: tooltip, child: sizedImage);
  }
}

/// A prebuilt attribution layer that supports both logos and text through
/// [SourceAttribution]s
///
/// [TextSourceAttribution]s are shown in a popup box (toggled by a tap/click on
/// the [openButton]/[closeButton]), unlike [LogoSourceAttribution], which are
/// visible permanently adjacent to the open/close button.
///
/// The popup box also closes automatically on any interaction with the map.
///
/// Shows a 'flutter_map' attribution logo and text, unless
/// [showFlutterMapAttribution] is `false`.
///
/// Can be further customized to a certain extent through the other properties.
class RichAttributionWidget extends StatefulWidget {
  /// List of attributions to display
  ///
  /// [TextSourceAttribution]s are shown in a popup box (toggled by a tap/click
  /// on the [openButton]/[closeButton]), unlike [LogoSourceAttribution], which
  /// are visible permanently adjacent to the open/close button.
  final List<SourceAttribution> attributions;

  /// The position in which to anchor this widget
  final AttributionAlignment alignment;

  /// The widget (usually an [IconButton]) to display when the popup box is
  /// closed, that opens the popup box via the `open` callback
  final Widget Function(BuildContext context, VoidCallback open)? openButton;

  /// The widget (usually an [IconButton]) to display when the popup box is open,
  /// that closes the popup box via the `close` callback
  final Widget Function(BuildContext context, VoidCallback close)? closeButton;

  /// The color to use as the popup box's background color, defaulting to the
  /// [Theme]s background color
  final Color? popupBackgroundColor;

  /// The radius of the edges of the popup box
  final BorderRadius? popupBorderRadius;

  /// The height of the permanent row in which is found the popup menu toggle
  /// button
  ///
  /// Also determines spacing between the items within the row.
  ///
  /// Also set [LogoSourceAttribution.height] to the same value, if adjusted.
  final double permanentHeight;

  /// Whether to add an additional attribution logo and text for 'flutter_map'
  final bool showFlutterMapAttribution;

  /// The curve to use when toggling the visibility of the popup box and the
  /// state of the open/close icons
  final Curve animationCurve;

  /// The length of the animation that toggles the visibility of the popup box
  /// and the state of the open/close icons
  final Duration animationDuration;

  /// If not [Duration.zero] (default), the popup box will be open by default and
  /// hidden this long after the map is initialised
  ///
  /// This is useful with certain sources/tile servers that make immediate
  /// attribution mandatory and are not attributed with a permanently visible
  /// [LogoSourceAttribution].
  final Duration popupInitialDisplayDuration;

  /// A prebuilt attribution layer that supports both logos and text through
  /// [SourceAttribution]s
  ///
  /// [TextSourceAttribution]s are shown in a popup box (toggled by a tap/click
  /// on the [openButton]/[closeButton]), unlike [LogoSourceAttribution]s, which
  /// are visible permanently in a row adjacent to the open/close button.
  ///
  /// The popup box also closes automatically on any interaction with the map.
  ///
  /// Shows a 'flutter_map' attribution logo and text, unless
  /// [showFlutterMapAttribution] is `false`.
  ///
  /// Can be further customized to a certain extent through the other properties.
  const RichAttributionWidget({
    super.key,
    required this.attributions,
    this.alignment = AttributionAlignment.bottomRight,
    this.openButton,
    this.closeButton,
    this.popupBackgroundColor,
    this.popupBorderRadius,
    this.permanentHeight = 24,
    this.showFlutterMapAttribution = true,
    this.animationCurve = Curves.easeInOut,
    this.animationDuration = const Duration(milliseconds: 150),
    this.popupInitialDisplayDuration = Duration.zero,
  });

  @override
  State<StatefulWidget> createState() => RichAttributionWidgetState();
}

class RichAttributionWidgetState extends State<RichAttributionWidget> {
  StreamSubscription<MapEvent>? mapEventSubscription;

  final persistentAttributionKey = GlobalKey();
  Size? persistentAttributionSize;

  late bool popupExpanded = widget.popupInitialDisplayDuration != Duration.zero;
  bool persistentHovered = false;

  @override
  void initState() {
    super.initState();

    if (popupExpanded) {
      Future.delayed(
        widget.popupInitialDisplayDuration,
        () => setState(() => popupExpanded = false),
      );
    }

    WidgetsBinding.instance.addPostFrameCallback(
      (_) => WidgetsBinding.instance.addPostFrameCallback(
        (_) => setState(
          () => persistentAttributionSize =
              (persistentAttributionKey.currentContext!.findRenderObject()
                      as RenderBox)
                  .size,
        ),
      ),
    );
  }

  @override
  void dispose() {
    mapEventSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final persistentAttributionItems = [
      ...widget.attributions
          .whereType<LogoSourceAttribution>()
          .cast<Widget>()
          .separate(SizedBox(width: widget.permanentHeight / 1.5)),
      if (widget.showFlutterMapAttribution)
        LogoSourceAttribution(
          Image.asset(
            'lib/assets/flutter_map_logo.png',
            package: 'flutter_map',
          ),
          tooltip: 'flutter_map',
          height: widget.permanentHeight,
        ),
      SizedBox(width: widget.permanentHeight * 0.1),
      AnimatedSwitcher(
        switchInCurve: widget.animationCurve,
        switchOutCurve: widget.animationCurve,
        duration: widget.animationDuration,
        child: popupExpanded
            ? (widget.closeButton ??
                (context, close) => IconButton(
                      onPressed: close,
                      icon: Icon(
                        Icons.cancel_outlined,
                        color: Theme.of(context).textTheme.titleSmall?.color ??
                            Colors.black,
                        size: widget.permanentHeight,
                      ),
                    ))(
                context,
                () => setState(() => popupExpanded = false),
              )
            : (widget.openButton ??
                (context, open) => IconButton(
                      onPressed: open,
                      tooltip: 'Attributions',
                      icon: Icon(
                        Icons.info_outlined,
                        color: Colors.black,
                        size: widget.permanentHeight,
                      ),
                    ))(
                context,
                () {
                  setState(() => popupExpanded = true);
                  mapEventSubscription = FlutterMapState.maybeOf(context)!
                      .mapController
                      .mapEventStream
                      .listen((e) {
                    setState(() => popupExpanded = false);
                    mapEventSubscription?.cancel();
                  });
                },
              ),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) => Align(
        alignment: widget.alignment.real,
        child: Stack(
          alignment: widget.alignment.real,
          children: [
            if (persistentAttributionSize != null)
              AnimatedOpacity(
                opacity: popupExpanded ? 1 : 0,
                curve: widget.animationCurve,
                duration: widget.animationDuration,
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Container(
                    decoration: BoxDecoration(
                      color: widget.popupBackgroundColor ??
                          Theme.of(context).colorScheme.background,
                      border: Border.all(width: 0, style: BorderStyle.none),
                      borderRadius: widget.popupBorderRadius ??
                          BorderRadius.only(
                            topLeft: const Radius.circular(10),
                            topRight: const Radius.circular(10),
                            bottomLeft: widget.alignment ==
                                    AttributionAlignment.bottomLeft
                                ? Radius.zero
                                : const Radius.circular(10),
                            bottomRight: widget.alignment ==
                                    AttributionAlignment.bottomRight
                                ? Radius.zero
                                : const Radius.circular(10),
                          ),
                    ),
                    constraints: BoxConstraints(
                      minWidth: constraints.maxWidth < 420
                          ? constraints.maxWidth
                          : persistentAttributionSize!.width,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...widget.attributions
                              .whereType<TextSourceAttribution>(),
                          const TextSourceAttribution(
                            "Made with 'flutter_map'",
                            prependCopyright: false,
                            textStyle: TextStyle(fontStyle: FontStyle.italic),
                          ),
                          SizedBox(height: (widget.permanentHeight - 24) + 32),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            MouseRegion(
              key: persistentAttributionKey,
              onEnter: (_) => setState(() => persistentHovered = true),
              onExit: (_) => setState(() => persistentHovered = false),
              cursor: SystemMouseCursors.click,
              child: AnimatedOpacity(
                opacity: persistentHovered || popupExpanded ? 1 : 0.5,
                curve: widget.animationCurve,
                duration: widget.animationDuration,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: FittedBox(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children:
                          widget.alignment == AttributionAlignment.bottomLeft
                              ? persistentAttributionItems.reversed.toList()
                              : persistentAttributionItems,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension _ListExt<E> on Iterable<E> {
  Iterable<E> separate(E separator) sync* {
    for (int i = 0; i < length; i++) {
      yield elementAt(i);
      if (i < length) yield separator;
    }
  }
}

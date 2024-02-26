import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:meta/meta.dart';

/// Base class for attributions that render themselves as widgets in a
/// [RichAttributionWidget]
///
/// Extended by [TextSourceAttribution] & [LogoSourceAttribution].
@immutable
sealed class SourceAttribution extends StatelessWidget {
  const SourceAttribution._({super.key, this.onTap});

  /// This callback gets called when the user clicks or taps on the attribution
  /// source.
  ///
  /// Most tile providers will require you to link to their terms of service,
  /// which may be done through this callback (and a package like
  /// 'url_launcher').
  final VoidCallback? onTap;

  Widget _render(BuildContext context);

  @override
  @nonVirtual
  Widget build(BuildContext context) {
    if (onTap == null) return _render(context);

    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: _render(context),
      ),
    );
  }
}

/// A simple text attribution displayed in the popup box of a
/// [RichAttributionWidget]
@immutable
class TextSourceAttribution extends SourceAttribution {
  /// Default style used to display the [text], only when
  /// [SourceAttribution.onTap] is not `null`
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
@immutable
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

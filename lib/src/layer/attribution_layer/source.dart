import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/src/layer/attribution_layer/rich.dart';

/// Base class for attributions that render themselves as widgets
///
/// Only used by [RichAttributionWidget].
///
/// Extended/implemented by [TextSourceAttribution] & [LogoSourceAttribution].
///
/// Avoid manual implementation - unknown subtypes will not be displayed.
@immutable
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
@immutable
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

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import 'package:flutter_map/src/map/options/options.dart';
import 'package:flutter_map/src/map/widget.dart';

/// A simple attribution box, which mimics a classic design style.
///
/// A custom child can be passed to the default constructor, or a prebuilt
/// design intended for a single source with optional hyperlink styling and tap
/// detector can be built using the [SimpleAttributionLayer.singleLink]
/// constructor.
///
/// Consider wrapping this layer in a [SafeArea] to ensure it's not obscured
/// by the system.
class SimpleAttributionLayer extends StatelessWidget {
  /// Color of the box containing the attribution.
  ///
  /// Defaults to [MapOptions.backgroundColor] if this layer is within a
  /// [FlutterMap], or the default light gray background colour otherwise.
  final Color? backgroundColor;

  /// Color of foreground elements.
  ///
  /// This color is also applied through a [DefaultTextStyle] around [builder].
  ///
  /// Defaults to a white or black contrasting with [backgroundColor]
  /// automatically.
  final Color? foregroundColor;

  /// Alignment of the box relative to the map widget.
  ///
  /// Defaults to displaying at the bottom right of the map.
  final Alignment alignment;

  /// Builder which returns a widget to display within the box.
  final WidgetBuilder builder;

  /// A simple attribution box with [builder].
  ///
  /// Consider wrapping this layer in a [SafeArea] to ensure it's not obscured
  /// by the system.
  const SimpleAttributionLayer({
    super.key,
    this.foregroundColor,
    this.backgroundColor,
    this.alignment = Alignment.bottomRight,
    required this.builder,
  });

  /// A simple attribution box which displays one line of text, optionally as
  /// in a hyperlink style (with underline) when [onTap] is set.
  ///
  /// Consider wrapping this layer in a [SafeArea] to ensure it's not obscured
  /// by the system.
  SimpleAttributionLayer.singleLink({
    super.key,
    required String text,
    void Function()? onTap,
    TextStyle? textStyle,
    bool showFlutterMapPrefix = false,
    this.backgroundColor,
    this.foregroundColor,
    this.alignment = Alignment.bottomRight,
  }) : builder = ((context) => Text.rich(
         TextSpan(
           children: [
             if (showFlutterMapPrefix) const TextSpan(text: 'flutter_map | '),
             TextSpan(
               text: text,
               style:
                   textStyle ??
                   (onTap == null
                       ? null
                       : TextStyle(
                           decoration: TextDecoration.underline,
                           decorationColor: DefaultTextStyle.of(
                             context,
                           ).style.color,
                         )),
               recognizer: onTap == null
                   ? null
                   : (TapGestureRecognizer()..onTap = onTap),
             ),
           ],
         ),
       ));

  @override
  Widget build(BuildContext context) {
    final backgroundColor =
        this.backgroundColor ??
        MapOptions.maybeOf(context)?.backgroundColor ??
        const Color(0xFFE0E0E0);
    final foregroundColor =
        this.foregroundColor ??
        (HSLColor.fromColor(backgroundColor).lightness > 0.5
            ? const Color(0xFF000000)
            : const Color(0xFFFFFFFF));

    return Align(
      alignment: alignment,
      child: ColoredBox(
        color: backgroundColor,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 6),
          child: DefaultTextStyle.merge(
            style: TextStyle(fontSize: 13, color: foregroundColor),
            child: Builder(builder: builder),
          ),
        ),
      ),
    );
  }
}

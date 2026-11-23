import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import 'package:flutter_map/src/map/options/options.dart';
import 'package:flutter_map/src/map/widget.dart';

/// A simple attribution box, which mimics the classic style of attribution.
///
/// This box is best for short attributions, such as to a single source, where
/// the attribution does not require images.
///
/// A custom child can be passed to the default constructor, or a prebuilt
/// design intended for a single source with optional hyperlink styling and tap
/// detector can be built using the [SimpleAttributionLayer.singleLink]
/// constructor.
class SimpleAttributionLayer extends StatelessWidget {
  /// Color of the box containing the [child].
  ///
  /// The child will be wrapped in a [DefaultTextStyle] (which inherits) which
  /// will set the default text color to, where possible, a contrasting color.
  /// This can be overriden by providing a new text style, either manually or
  /// with an overriding [DefaultTextStyle].
  ///
  /// Defaults to [MapOptions.backgroundColor] if this layer is within a
  /// [FlutterMap], or the default light gray background colour otherwise.
  final Color? backgroundColor;

  /// Alignment of the box relative to the map widget.
  ///
  /// Defaults to displaying at the bottom right of the map.
  final Alignment alignment;

  /// Widget to display within the box.
  final Widget child;

  /// A simple attribution box with [child].
  const SimpleAttributionLayer({
    super.key,
    required this.child,
    this.backgroundColor,
    this.alignment = Alignment.bottomRight,
  });

  /// A simple attribution box which displays one line of text, optionally as
  /// in a hyperlink style (with underline) when [onTap] is set.
  SimpleAttributionLayer.singleLink({
    super.key,
    required String text,
    void Function()? onTap,
    TextStyle? textStyle,
    bool showFlutterMapPrefix = false,
    this.backgroundColor,
    this.alignment = Alignment.bottomRight,
  }) : child = Builder(
          builder: (context) => Text.rich(
            TextSpan(
              children: [
                if (showFlutterMapPrefix)
                  const TextSpan(text: 'flutter_map | '),
                TextSpan(
                  text: text,
                  style: textStyle ??
                      (onTap == null
                          ? null
                          : TextStyle(
                              decoration: TextDecoration.underline,
                              decorationColor:
                                  DefaultTextStyle.of(context).style.color,
                            )),
                  recognizer: onTap == null
                      ? null
                      : (TapGestureRecognizer()..onTap = onTap),
                ),
              ],
            ),
          ),
        );

  @override
  Widget build(BuildContext context) {
    final backgroundColor = this.backgroundColor ??
        MapOptions.maybeOf(context)?.backgroundColor ??
        const Color(0xFFE0E0E0);

    return Align(
      alignment: alignment,
      child: ColoredBox(
        color: backgroundColor,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 6),
          child: DefaultTextStyle.merge(
            style: TextStyle(
              color: HSLColor.fromColor(backgroundColor).lightness > 0.5
                  ? const Color(0xFF000000)
                  : const Color(0xFFFFFFFF),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

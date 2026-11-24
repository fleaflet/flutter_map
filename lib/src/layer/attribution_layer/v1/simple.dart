import 'package:flutter/material.dart' show Theme;
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';

/// > [!WARNING]
/// > ### DEPRECATED
/// > **Use [SimpleAttributionLayer] instead. This widget will be removed when
/// > flutter_map removes its dependency on Material in a future breaking
/// > release.**
/// >
/// > The new layer looks very similar to this widget, but does not prefix any
/// > text by default, is more flexible, and free from Material theming.
/// >
/// > To migrate, check the online documentation.
///
/// A simple, classic style, attribution layer
///
/// Displayed as a padded translucent [backgroundColor] box with the following
/// text: 'flutter_map | © [source]', where [source] is wrapped with [onTap].
///
/// See also:
///
///  * [RichAttributionWidget], which is dynamic, supports more customization,
///    and has a more complex appearance.
@Deprecated('''Use `SimpleAttributionLayer` instead.
See documentation on `SimpleAttributionWidget`, and online documentation,
for more information.
This widget will be removed when flutter_map removes its dependency on Material
in a future breaking release.
''')
class SimpleAttributionWidget extends StatelessWidget {
  /// Attribution text, such as 'OpenStreetMap contributors'
  final Text source;

  /// Callback called when [source] is tapped/clicked
  final VoidCallback? onTap;

  /// Color of the box containing the [source] text.
  /// Defaults to the background color of the app [Theme].
  final Color? backgroundColor;

  /// Anchor the widget in a position of the map
  final Alignment alignment;

  /// A simple, classic style, attribution widget
  ///
  /// Displayed as a padded translucent white box with the following text:
  /// 'flutter_map | © [source]'.
  const SimpleAttributionWidget({
    super.key,
    required this.source,
    this.onTap,
    this.backgroundColor,
    this.alignment = Alignment.bottomRight,
  });

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Align(
      alignment: alignment,
      child: ColoredBox(
        color: backgroundColor ?? Theme.of(context).colorScheme.surface,
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
    ),
  );
}

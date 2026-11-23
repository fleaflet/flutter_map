import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:vector_graphics/vector_graphics.dart';
import 'package:vector_graphics/vector_graphics_compat.dart';

part 'widgets/expand_info_button.dart';

class RichAttributionLayer extends StatefulWidget {
  const RichAttributionLayer({
    super.key,
    this.backgroundColor,
    this.foregroundColor,
    this.animationDuration = const Duration(milliseconds: 200),
    this.alignment = Alignment.bottomRight,
    this.initialExpansionDuration = const Duration(seconds: 3),
    this.minimizeOnMapEvent = RichAttributionLayer.defaultMinimizeOnMapEvent,
    this.customButtonIconBuilder,
    this.customButtonTooltipTextBuilder,
    required this.expandedChild,
  });

  /// Color of the box containing the icon button and [expandedChild].
  ///
  /// Defaults to [MapOptions.backgroundColor] if this layer is within a
  /// [FlutterMap], or the default light gray background colour otherwise.
  final Color? backgroundColor;

  /// Color of foreground elements.
  ///
  /// This color is also applied through a [DefaultTextStyle] around
  /// [expandedChild].
  ///
  /// Defaults to a white or black contrasting with [backgroundColor]
  /// automatically.
  final Color? foregroundColor;

  /// Duration of animation of expanding & minimizing.
  ///
  /// Defaults to 200ms.
  final Duration animationDuration;

  /// Alignment of the box relative to the map widget.
  ///
  /// Defaults to displaying at the bottom right of the map.
  final Alignment alignment;

  /// The duration for which to show the attribution expanded on initialisation.
  ///
  /// Set to [Duration.zero] to show it minimized on initialisation.
  ///
  /// [minimizeOnMapEvent] may cause minimisation quicker than the elapse of
  /// this duration.
  ///
  /// Defaults to 3 seconds.
  final Duration initialExpansionDuration;

  /// Callback called whenever the attribution is expanded and the map has an
  /// event, which that determines whether to minimise the attribution.
  ///
  /// `isInInitialExpansion` is `true` when the attribution is expanded since
  /// initialisation; see [initialExpansionDuration].
  ///
  /// Should return `true` to minimise the attribution.
  ///
  /// Defaults to [defaultMinimizeOnMapEvent].
  final bool Function(MapEvent evt, bool isInInitialExpansion)
      minimizeOnMapEvent;

  /// Widget builder that determines icon shown in button that expands/minimises
  /// attribution.
  ///
  /// Defaults to a filled 'i' icon when minimised and an outline 'i' icon when
  /// expanded.
  final Widget Function(BuildContext context, bool expanded)?
      customButtonIconBuilder;

  /// String builder that determines text shown in tooltip for button that
  /// expands/minimises attribution.
  ///
  /// This is primarily to enable translation.
  ///
  /// Defaults to English: "Show attribution" when minimised, "Hide attribution"
  /// when expanded.
  final String Function(bool expanded)? customButtonTooltipTextBuilder;

  /// Widget to show when the attribution layer is expanded.
  ///
  /// This is usually a some kind of text, often [Text.rich] for interactivity.
  /// For example, the following widget creates two strings, one of which is
  /// linked and seperately styled (and uses the automatically calculated
  /// [foregroundColor] for an underline):
  ///
  /// ```dart
  /// import 'package:flutter/gestures.dart';
  ///
  /// Text.rich(
  ///   TextSpan(
  ///     children: [
  ///       TextSpan(
  ///         text: '© OpenStreetMap contributors',
  ///         style: TextStyle(
  ///           decoration: TextDecoration.underline,
  ///           decorationColor: DefaultTextStyle.of(context).style.color,
  ///         ),
  ///         recognizer: TapGestureRecognizer()..onTap = () {
  ///           // Open a URL
  ///         },
  ///       ),
  ///       const TextSpan(text: ' | Last updated: 12 hours ago'),
  ///     ],
  ///   ),
  /// );
  /// ```
  ///
  /// Usually, the text should be displayed on a single line.
  final Widget expandedChild;

  /// Default handler for [minimizeOnMapEvent].
  ///
  /// Returns `true` when the [evt] was likely* a gesture, and not
  /// [isInInitialExpansion].
  static bool defaultMinimizeOnMapEvent(
    MapEvent evt,
    bool isInInitialExpansion,
  ) =>
      !{
        MapEventSource.mapController,
        MapEventSource.nonRotatedSizeChange,
        MapEventSource.fitCamera,
        MapEventSource.custom
      }.contains(evt.source) &&
      !isInInitialExpansion;

  @override
  State<RichAttributionLayer> createState() => _RichAttributionLayerState();
}

class _RichAttributionLayerState extends State<RichAttributionLayer> {
  late final _useInitialExpansion =
      widget.initialExpansionDuration != Duration.zero;

  StreamSubscription<MapEvent>? _mapEventSubscription;
  late final _minimizeTimer = _useInitialExpansion
      ? Timer(widget.initialExpansionDuration, () => _isExpanded.value = false)
      : null;

  late final _isExpanded = ValueNotifier(_useInitialExpansion);

  @override
  void initState() {
    super.initState();

    void minimizeOnMapEvent() {
      final isInInitialExpansion =
          _minimizeTimer != null && _minimizeTimer.isActive;
      _mapEventSubscription = MapController.of(context).mapEventStream.listen(
            (e) => _isExpanded.value =
                !widget.minimizeOnMapEvent(e, isInInitialExpansion),
          );
    }

    if (_useInitialExpansion) {
      WidgetsBinding.instance.addPostFrameCallback((_) => minimizeOnMapEvent());
    }

    void expandedListener() {
      if (_isExpanded.value) {
        minimizeOnMapEvent();
      } else {
        _minimizeTimer?.cancel();
        _mapEventSubscription?.cancel();
      }
    }

    _isExpanded.addListener(expandedListener);
  }

  @override
  void dispose() {
    _minimizeTimer?.cancel();
    _mapEventSubscription?.cancel();
    _isExpanded.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = widget.backgroundColor ??
        MapOptions.maybeOf(context)?.backgroundColor ??
        const Color(0xFFE0E0E0);
    final foregroundColor = widget.foregroundColor ??
        (HSLColor.fromColor(backgroundColor).lightness > 0.5
            ? const Color(0xFF000000)
            : const Color(0xFFFFFFFF));

    final direction = widget.alignment.x > 0 ? -1 : 1;

    return DefaultTextStyle.merge(
      style: TextStyle(color: foregroundColor),
      child: Align(
        alignment: widget.alignment,
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IntrinsicHeight(
            child: ValueListenableBuilder(
              valueListenable: _isExpanded,
              builder: (context, isExpanded, _) {
                final expandedAttribution = AnimatedSwitcher(
                  duration: widget.animationDuration,
                  switchInCurve: Curves.easeInOut,
                  switchOutCurve: Curves.easeInOut,
                  transitionBuilder: (child, animation) => SizeTransition(
                    sizeFactor: animation,
                    axis: Axis.horizontal,
                    alignment: Alignment(-widget.alignment.x, 0),
                    child: child,
                  ),
                  child: isExpanded
                      ? Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          child: widget.expandedChild,
                        )
                      : const SizedBox.shrink(),
                );

                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (direction == -1) Flexible(child: expandedAttribution),
                    _ExpandInfoButton(
                      isExpanded: isExpanded,
                      toggleExpanded: () => _isExpanded.value = !isExpanded,
                      backgroundColor: backgroundColor,
                      animationDuration: widget.animationDuration,
                      direction: direction,
                      customButtonIconBuilder: widget.customButtonIconBuilder,
                      customButtonTooltipTextBuilder:
                          widget.customButtonTooltipTextBuilder,
                    ),
                    if (direction == 1) Flexible(child: expandedAttribution),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

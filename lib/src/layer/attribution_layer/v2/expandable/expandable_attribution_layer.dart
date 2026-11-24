import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:vector_graphics/vector_graphics.dart';
import 'package:vector_graphics/vector_graphics_compat.dart';

part 'widgets/expand_info_button.dart';

/// An animated attribution box which can be either minimized - showing just an
/// icon button - or expanded - showing a custom widget (usually attribution
/// text) alongside.
///
/// The design is similar to that of MapLibre's attribution element.
///
/// Consider wrapping this layer in a [SafeArea] to ensure it's not obscured
/// by the system.
class ExpandableAttributionLayer extends StatefulWidget {
  /// Color of the box containing the icon button and expanded attribution.
  ///
  /// Defaults to [MapOptions.backgroundColor] if this layer is within a
  /// [FlutterMap], or the default light gray background colour otherwise.
  final Color? backgroundColor;

  /// Color of foreground elements.
  ///
  /// This color is also applied through a [DefaultTextStyle] around
  /// [expandedBuilder].
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
  /// Usually a corner is used, often the bottom right corner.
  ///
  /// Defaults to displaying at the bottom right of the map.
  final Alignment alignment;

  /// The duration for which to show the attribution expanded on initialisation.
  ///
  /// Set to [Duration.zero] to show it minimized on initialisation. Set to
  /// `null` to set an infinite duration.
  ///
  /// See also [minimizeOnMapEvent] and [forceInitialExpansionDurationElapse].
  ///
  /// Defaults to 3 seconds.
  final Duration? initialExpansionDuration;

  /// Whether to prevent [minimizeOnMapEvent] minimizing the attribution if it
  /// is expanded since initialisation due to [initialExpansionDuration].
  ///
  /// Recommended to set `false` if [initialExpansionDuration] is `null`.
  ///
  /// Defaults to `true`.
  final bool forceInitialExpansionDurationElapse;

  /// Callback called whenever the attribution is expanded and the map has an
  /// event, which that determines whether to minimise the attribution.
  ///
  /// May be inhibited by [forceInitialExpansionDurationElapse].
  ///
  /// Should return `true` to minimise the attribution.
  ///
  /// Defaults to [defaultMinimizeOnMapEvent].
  final bool Function(MapEvent evt) minimizeOnMapEvent;

  /// Widget builder that determines icon shown in button that expands/minimises
  /// attribution.
  ///
  /// Defaults to a filled 'i' icon when minimised and an outline 'i' icon when
  /// expanded.
  final Widget Function(BuildContext context, bool isExpanded)?
      customButtonIconBuilder;

  /// String builder that determines text shown in tooltip for button that
  /// expands/minimises attribution.
  ///
  /// This is primarily to enable translation.
  ///
  /// Defaults to English: "Show attribution" when minimised, "Hide attribution"
  /// when expanded.
  ///
  /// No effect if [customButtonTooltipBuilder] is set.
  final String Function(bool isExpanded)? customButtonTooltipTextBuilder;

  /// Widget builder that allows wrapping of the icon button with custom widget,
  /// usually a tooltip.
  ///
  /// Defaults to a custom implementation using [RawTooltip].
  final Widget Function(BuildContext context, Widget child, bool isExpanded)?
      customButtonTooltipBuilder;

  /// Optional widget shown adjacent to icon button that moves out of the way
  /// of the [expandedBuilder] as necessary.
  ///
  /// This is useful to display required attribution logo images which must
  /// always be visible, and easily adjacent to the rest of the attributions.
  ///
  /// [expandedBuilder] will not overlap with this. If this is wanted in a
  /// different position (such as the opposite corner as is common), or wants to
  /// allow overlapping, then manually place the widget into the map layer
  /// stack.
  final Widget? adjacentPersistentChild;

  /// Builder which returns widget to show when the attribution layer is
  /// expanded.
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
  /// Usually, the text should be displayed on a single line. If it's long, it
  /// can either wrap over multiple lines, or it could be forced onto a single
  /// line within some scrolling viewport.
  final WidgetBuilder expandedBuilder;

  /// A customisable expandable attribution layer with custom attribution.
  ///
  /// Consider wrapping this layer in a [SafeArea] to ensure it's not obscured
  /// by the system.
  const ExpandableAttributionLayer({
    super.key,
    this.backgroundColor,
    this.foregroundColor,
    this.animationDuration = const Duration(milliseconds: 200),
    this.alignment = Alignment.bottomRight,
    this.initialExpansionDuration = const Duration(seconds: 3),
    this.forceInitialExpansionDurationElapse = true,
    this.minimizeOnMapEvent =
        ExpandableAttributionLayer.defaultMinimizeOnMapEvent,
    this.customButtonIconBuilder,
    this.customButtonTooltipTextBuilder,
    this.customButtonTooltipBuilder,
    this.adjacentPersistentChild,
    required this.expandedBuilder,
  });

  /// Default handler for [minimizeOnMapEvent].
  ///
  /// Returns `true` when the [evt] was likely* a gesture.
  static bool defaultMinimizeOnMapEvent(MapEvent evt) => !{
        MapEventSource.mapController,
        MapEventSource.nonRotatedSizeChange,
        MapEventSource.fitCamera,
        MapEventSource.custom
      }.contains(evt.source);

  @override
  State<ExpandableAttributionLayer> createState() =>
      _ExpandableAttributionLayerState();
}

class _ExpandableAttributionLayerState
    extends State<ExpandableAttributionLayer> {
  late final _useInitialExpansion =
      widget.initialExpansionDuration != Duration.zero;

  // These are only exposed to allow disposal
  StreamSubscription<MapEvent>? _mapEventSubscription;
  late final Timer? _minimizeTimer;

  late final _isExpanded = ValueNotifier(_useInitialExpansion);

  @override
  void initState() {
    super.initState();

    _minimizeTimer =
        _useInitialExpansion && widget.initialExpansionDuration != null
            ? Timer(
                widget.initialExpansionDuration!,
                () => _isExpanded.value = false,
              )
            : null;

    void minimizeOnMapEvent() {
      _mapEventSubscription = MapController.of(context).mapEventStream.listen(
        (e) {
          if (widget.forceInitialExpansionDurationElapse &&
                  _useInitialExpansion &&
                  (_minimizeTimer?.isActive ?? true) // `null` = always active
              ) {
            return;
          }
          if (widget.minimizeOnMapEvent(e)) _isExpanded.value = false;
        },
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

    final attributionMainPanel = DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
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
                      padding: const EdgeInsets.fromLTRB(8, 3, 6, 3),
                      child: Builder(builder: widget.expandedBuilder),
                    )
                  : const SizedBox.shrink(),
            );

            return Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
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
                  customButtonTooltipBuilder: widget.customButtonTooltipBuilder,
                ),
                if (direction == 1) Flexible(child: expandedAttribution),
              ],
            );
          },
        ),
      ),
    );

    return DefaultTextStyle.merge(
      style: TextStyle(fontSize: 13, color: foregroundColor),
      child: Align(
        alignment: widget.alignment,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 8,
            children: [
              if (direction == -1)
                if (widget.adjacentPersistentChild != null)
                  widget.adjacentPersistentChild!,
              Flexible(child: attributionMainPanel),
              if (direction == 1)
                if (widget.adjacentPersistentChild != null)
                  widget.adjacentPersistentChild!,
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:vector_graphics/vector_graphics.dart';
import 'package:vector_graphics/vector_graphics_compat.dart';

class RichAttributionLayer extends StatefulWidget {
  const RichAttributionLayer({
    super.key,
    this.backgroundColor,
    this.alignment = Alignment.bottomRight,
    this.initiallyExpanded = const Duration(seconds: 3),
    this.minimizeOnMapEvent,
    this.customButtonIconBuilder,
    this.customButtonTooltipTextBuilder,
  });

  /// Color of the box containing the [child].
  ///
  /// Defaults to [MapOptions.backgroundColor] if this layer is within a
  /// [FlutterMap], or the default light gray background colour otherwise.
  final Color? backgroundColor;

  /// Alignment of the box relative to the map widget.
  ///
  /// Defaults to displaying at the bottom right of the map.
  final Alignment alignment;

  /// The duration for which to show the attribution expanded on initialisation.
  ///
  /// If `null` or [Duration.zero], it is not shown expanded.
  ///
  /// [minimizeOnMapEvent] may cause minimisation quicker than the elapse of
  /// this duration.
  ///
  /// Defaults to 3 seconds.
  final Duration? initiallyExpanded;

  /// Callback called whenever the attribution is expanded and the map has an
  /// event, which that determines whether to minimise the attribution.
  ///
  /// Should return `true` to minimise the attribution, `false` otherwise.
  ///
  /// Defaults to minimising if the event is triggered by a gesture.
  final bool Function(MapEvent evt)? minimizeOnMapEvent;

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

  @override
  State<RichAttributionLayer> createState() => _RichAttributionLayerState();
}

class _RichAttributionLayerState extends State<RichAttributionLayer> {
  late final _isInitiallyExpanded = widget.initiallyExpanded != null &&
      widget.initiallyExpanded != Duration.zero;

  StreamSubscription<MapEvent>? _mapEventSubscription;
  late final _expanded = ValueNotifier(_isInitiallyExpanded);

  @override
  void initState() {
    super.initState();

    final maxDurationTimer = _isInitiallyExpanded
        ? Timer(widget.initiallyExpanded!, () => _expanded.value = false)
        : null;

    void minimizeOnMapEvent() =>
        _mapEventSubscription = MapController.of(context).mapEventStream.listen(
              (e) => _expanded.value = !(widget.minimizeOnMapEvent?.call(e) ??
                  !{
                    MapEventSource.mapController,
                    MapEventSource.nonRotatedSizeChange,
                    MapEventSource.fitCamera,
                    MapEventSource.custom
                  }.contains(e.source)),
            );

    if (_isInitiallyExpanded) {
      WidgetsBinding.instance.addPostFrameCallback((_) => minimizeOnMapEvent());
    }

    void expandedListener() {
      if (_expanded.value) {
        minimizeOnMapEvent();
      } else {
        maxDurationTimer?.cancel();
        _mapEventSubscription?.cancel();
      }
    }

    _expanded.addListener(expandedListener);
  }

  @override
  void dispose() {
    _mapEventSubscription?.cancel();
    _expanded.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = widget.backgroundColor ??
        MapOptions.maybeOf(context)?.backgroundColor ??
        const Color(0xFFE0E0E0);
    final foregroundColor = HSLColor.fromColor(backgroundColor).lightness > 0.5
        ? const Color(0xFF000000)
        : const Color(0xFFFFFFFF);

    final direction = widget.alignment.x > 0 ? -1 : 1;

    return DefaultTextStyle.merge(
      style: TextStyle(color: foregroundColor),
      child: Align(
        alignment: widget.alignment,
        child: Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(2),
          decoration: ShapeDecoration(
            shape: const StadiumBorder(),
            color: backgroundColor,
          ),
          child: ValueListenableBuilder(
            valueListenable: _expanded,
            builder: (context, expanded, _) {
              final tooltipText =
                  widget.customButtonTooltipTextBuilder?.call(expanded) ??
                      '${expanded ? 'Hide' : 'Show'} attribution';

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RawTooltip(
                    hoverDelay: const Duration(milliseconds: 500),
                    semanticsTooltip: tooltipText,
                    positionDelegate: (context) => Offset(
                      context.target.dx +
                          direction *
                              ((direction == 1
                                      ? 0
                                      : context.tooltipSize.width) +
                                  context.targetSize.width / 2 +
                                  8),
                      context.target.dy - context.tooltipSize.height / 2,
                    ),
                    tooltipBuilder: (context, animation) => FadeTransition(
                      opacity: animation,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: backgroundColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 8,
                          ),
                          child: Text(
                            tooltipText,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    ),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => _expanded.value = !_expanded.value,
                        child: Padding(
                          padding: const EdgeInsets.all(2),
                          child: widget.customButtonIconBuilder
                                  ?.call(context, expanded) ??
                              AnimatedCrossFade(
                                crossFadeState: expanded
                                    ? CrossFadeState.showSecond
                                    : CrossFadeState.showFirst,
                                duration: const Duration(milliseconds: 100),
                                firstCurve: Curves.easeIn,
                                secondCurve: Curves.easeOut,
                                firstChild: SvgPicture(
                                  key: const ValueKey('filled'),
                                  const AssetBytesLoader(
                                    'lib/assets/info_icon_filled.svg.vec',
                                    packageName: 'flutter_map',
                                  ),
                                  width: 18,
                                  height: 18,
                                  colorFilter: ColorFilter.mode(
                                    foregroundColor,
                                    BlendMode.srcIn,
                                  ),
                                ),
                                secondChild: SvgPicture(
                                  key: const ValueKey('outline'),
                                  const AssetBytesLoader(
                                    'lib/assets/info_icon_outline.svg.vec',
                                    packageName: 'flutter_map',
                                  ),
                                  width: 18,
                                  height: 18,
                                  colorFilter: ColorFilter.mode(
                                    foregroundColor,
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

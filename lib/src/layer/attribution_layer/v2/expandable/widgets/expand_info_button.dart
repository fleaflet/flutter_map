part of '../expandable_attribution_layer.dart';

class _ExpandInfoButton extends StatelessWidget {
  const _ExpandInfoButton({
    required this.isExpanded,
    required this.toggleExpanded,
    required this.backgroundColor,
    required this.animationDuration,
    required this.direction,
    required this.customButtonIconBuilder,
    required this.customButtonTooltipTextBuilder,
  });

  final bool isExpanded;
  final void Function() toggleExpanded;

  final Color backgroundColor;
  final Duration animationDuration;
  final int direction;
  final Widget Function(BuildContext context, bool expanded)?
      customButtonIconBuilder;
  final String Function(bool expanded)? customButtonTooltipTextBuilder;

  @override
  Widget build(BuildContext context) {
    final foregroundColor = DefaultTextStyle.of(context).style.color!;

    final tooltipText = customButtonTooltipTextBuilder?.call(isExpanded) ??
        '${isExpanded ? 'Hide' : 'Show'} attribution';

    return TweenAnimationBuilder(
      tween: ColorTween(
        begin: isExpanded ? foregroundColor : backgroundColor,
        end: isExpanded ? foregroundColor : backgroundColor,
      ),
      duration: animationDuration,
      curve: Curves.easeInOut,
      builder: (context, value, child) => DecoratedBox(
        decoration: ShapeDecoration(
          shape: const CircleBorder(),
          color: value,
        ),
        child: child,
      ),
      child: RawTooltip(
        hoverDelay: const Duration(milliseconds: 500),
        semanticsTooltip: tooltipText,
        positionDelegate: (context) => Offset(
          context.target.dx +
              direction *
                  ((direction == 1 ? 0 : context.tooltipSize.width) +
                      context.targetSize.width / 2 +
                      6),
          context.target.dy - context.tooltipSize.height / 2,
        ),
        tooltipBuilder: (context, animation) => FadeTransition(
          opacity: animation,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: isExpanded ? foregroundColor : backgroundColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: Text(
                tooltipText,
                style: TextStyle(
                  fontSize: 13,
                  color: isExpanded ? backgroundColor : foregroundColor,
                ),
              ),
            ),
          ),
        ),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: toggleExpanded,
            behavior: HitTestBehavior.translucent,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: customButtonIconBuilder?.call(context, isExpanded) ??
                  SizedBox.square(
                    dimension: 20,
                    child: AnimatedCrossFade(
                      crossFadeState: isExpanded
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      duration: animationDuration,
                      firstCurve: Curves.easeIn,
                      secondCurve: Curves.easeOut,
                      sizeCurve: Curves.easeInOut,
                      firstChild: SvgPicture(
                        key: const ValueKey('filled'),
                        const AssetBytesLoader(
                          'lib/assets/info_icon_filled.svg.vec',
                          packageName: 'flutter_map',
                        ),
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
                        colorFilter: ColorFilter.mode(
                          backgroundColor,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

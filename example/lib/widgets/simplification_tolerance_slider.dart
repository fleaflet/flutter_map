import 'package:flutter/material.dart';

class SimplificationToleranceSlider extends StatelessWidget {
  const SimplificationToleranceSlider({
    super.key,
    required this.tolerance,
    required this.onChanged,
  });

  final double tolerance;
  final void Function(double) onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 8, top: 4, bottom: 4),
        child: Row(
          children: [
            const Tooltip(
              message: 'Adjust Simplification Tolerance',
              child: Row(
                children: [
                  Icon(Icons.insights),
                  SizedBox(width: 8),
                  Icon(Icons.hdr_strong),
                ],
              ),
            ),
            Expanded(
              child: Slider.adaptive(
                value: tolerance,
                onChanged: onChanged,
                min: 0,
                max: 2,
                divisions: 100,
                label:
                    tolerance == 0 ? 'Disabled' : tolerance.toStringAsFixed(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

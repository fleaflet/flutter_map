import 'package:flutter/material.dart';

class SimplificationToleranceSlider extends StatefulWidget {
  const SimplificationToleranceSlider({
    super.key,
    required this.initialTolerance,
    required this.onChangedTolerance,
  });

  final double initialTolerance;
  final void Function(double) onChangedTolerance;

  @override
  State<SimplificationToleranceSlider> createState() =>
      _SimplificationToleranceSliderState();
}

class _SimplificationToleranceSliderState
    extends State<SimplificationToleranceSlider> {
  late double _simplificationTolerance = widget.initialTolerance;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.background,
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
              child: Slider(
                value: _simplificationTolerance,
                onChanged: (v) {
                  if (_simplificationTolerance == 0 && v != 0) {
                    widget.onChangedTolerance(v);
                  }
                  setState(() => _simplificationTolerance = v);
                },
                onChangeEnd: widget.onChangedTolerance,
                min: 0,
                max: 2,
                divisions: 100,
                label: _simplificationTolerance == 0
                    ? 'Disabled'
                    : _simplificationTolerance.toStringAsFixed(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class NumberOfItemsSlider extends StatelessWidget {
  const NumberOfItemsSlider({
    super.key,
    required this.number,
    required this.onChanged,
    required this.maxNumber,
    this.itemDescription = 'Item',
    int itemsPerDivision = 1000,
  })  : assert(
          (maxNumber / itemsPerDivision) % 1 == 0,
          '`maxNumber` / `itemsPerDivision` must yield integer',
        ),
        divisions = maxNumber ~/ itemsPerDivision;

  final int number;
  final void Function(int) onChanged;
  final String itemDescription;
  final int maxNumber;
  final int divisions;

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
            Tooltip(
              message: 'Adjust Number of ${itemDescription}s',
              child: const Icon(Icons.numbers),
            ),
            Expanded(
              child: Slider.adaptive(
                value: number.toDouble(),
                onChanged: (v) => onChanged(v.toInt()),
                min: 0,
                max: maxNumber.toDouble(),
                divisions: divisions,
                label: number.toString(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

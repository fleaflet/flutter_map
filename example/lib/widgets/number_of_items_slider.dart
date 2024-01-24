import 'package:flutter/material.dart';

class NumberOfItemsSlider extends StatefulWidget {
  const NumberOfItemsSlider({
    super.key,
    required this.initialNumber,
    required this.onChangedNumber,
    required this.maxNumber,
    this.itemDescription = 'Item',
    int itemsPerDivision = 1000,
  })  : assert(
          (maxNumber / itemsPerDivision) % 1 == 0,
          '`maxNumber` / `itemsPerDivision` must yield integer',
        ),
        divisions = maxNumber ~/ itemsPerDivision;

  final int initialNumber;
  final void Function(int) onChangedNumber;
  final String itemDescription;
  final int maxNumber;
  final int divisions;

  @override
  State<NumberOfItemsSlider> createState() => _NumberOfItemsSliderState();
}

class _NumberOfItemsSliderState extends State<NumberOfItemsSlider> {
  late int _number = widget.initialNumber;

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
            Tooltip(
              message: 'Adjust Number of ${widget.itemDescription}s',
              child: const Icon(Icons.numbers),
            ),
            Expanded(
              child: Slider.adaptive(
                value: _number.toDouble(),
                onChanged: (v) {
                  if (_number == 0 && v != 0) {
                    widget.onChangedNumber(v.toInt());
                  }
                  setState(() => _number = v.toInt());
                },
                onChangeEnd: (v) => widget.onChangedNumber(v.toInt()),
                min: 0,
                max: widget.maxNumber.toDouble(),
                divisions: widget.divisions,
                label: _number.toString(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

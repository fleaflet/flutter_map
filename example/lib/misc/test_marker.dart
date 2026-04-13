import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

final _randomGenerator = Random(10);

class TestMarker extends StatefulWidget {
  const TestMarker({super.key, required this.point});

  final LatLng point;

  @override
  State<TestMarker> createState() => _TestMarkerState();
}

class _TestMarkerState extends State<TestMarker> {
  Timer? _tapSelected;
  bool _hoverSelected = false;

  bool get _isSelected => _tapSelected != null || _hoverSelected;

  late final _unselectedColor = Color.fromARGB(
    255,
    _randomGenerator.nextInt(256),
    _randomGenerator.nextInt(256),
    _randomGenerator.nextInt(256),
  );

  @override
  Widget build(BuildContext context) {
    print('built ${widget.point}');
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(
          color: _isSelected ? Colors.green : Colors.black.withAlpha(51),
          width: _isSelected ? 3 : 1,
        ),
      ),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hoverSelected = true),
        onExit: (_) => setState(() => _hoverSelected = false),
        child: GestureDetector(
          onTap: () => setState(() {
            _tapSelected?.cancel();
            _tapSelected = Timer(
              const Duration(seconds: 1),
              () {
                if (mounted) setState(() => _tapSelected = null);
              },
            );
          }),
          child: Icon(
            Icons.location_pin,
            size: 40,
            color: _isSelected ? Colors.green : _unselectedColor,
          ),
        ),
      ),
    );
  }
}

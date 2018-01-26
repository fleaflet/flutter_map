library leaflet_flutter;

import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';

class Leaflet extends StatefulWidget {
  State<StatefulWidget> createState() {
    return new _LeafletState();
  }
}

class _LeafletState extends State<Leaflet> {
  double xOffset = 0.0;
  double yOffset = 0.0;
  double scale = 1.0;
  Widget build(BuildContext context) {
    return new GestureDetector(
      onScaleStart: _handleScaleStart,
      onScaleUpdate: _handleScaleUpdate,
      onScaleEnd: _handleScaleEnd,
      child: new Container(
        child: _buildWidgets(),
        color: Colors.amber[50],
      ),
    );
  }

  Offset _startPoint;
  void _handleScaleStart(ScaleStartDetails details) {
    _startPoint = _startPoint ?? details.focalPoint;
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    var latestPoint = details.focalPoint;
    var scale = details.scale;
    var dx = latestPoint.dx - _startPoint.dx;
    var dy = (latestPoint.dy - _startPoint.dy);
    // dx and dy reset after each scaleStart
    // don't reset them
    setState(() {
      xOffset = dx;
      yOffset = dy;
      this.scale = scale;
    });
  }

  void _handleScaleEnd(ScaleEndDetails details) {
//    _startPoint = null;
  }

  Widget _buildWidgets() {
    var children = [];
    var colorGenerator = new _ColorGenerator();
    for (var i = 0; i < 8; i++) {
      for (var j = 0; j < 8; j++) {
        children.add(
          new Positioned(
            left: i * 96.0 * scale + xOffset,
            top: j * 96.0 * scale + yOffset,
            width: 96.0 * scale,
            height: 96.0 * scale,
            child: new Container(
              color: colorGenerator.next(),
            ),
          ),
        );
      }
    }
    return new Stack(
      children: children,
    );
  }
}

class _ColorGenerator {
  int i;
  _ColorGenerator() : i = 0;
  Color next() {
    final List<MaterialColor> options = <MaterialColor>[
      Colors.red,
      Colors.orange,
      Colors.yellow,
      Colors.green,
      Colors.blue,
      Colors.indigo,
      Colors.purple
    ];
    return options[i++ % options.length];
//    return options[new math.Random().nextInt(options.length)];
  }
}

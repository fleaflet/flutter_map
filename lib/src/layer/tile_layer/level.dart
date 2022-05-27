import 'package:flutter_map/flutter_map.dart';

class Level {
  final CustomPoint origin;
  final double zoom;
  late CustomPoint translatePoint;
  late double scale;

  Level({
    required this.origin,
    required this.zoom,
  });
}

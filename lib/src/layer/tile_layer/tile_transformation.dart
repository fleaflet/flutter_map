import 'package:flutter_map/flutter_map.dart';
import 'package:meta/meta.dart';

@immutable
class TileTransformation {
  final double scale;
  final CustomPoint translate;

  const TileTransformation({
    required this.scale,
    required this.translate,
  });
}

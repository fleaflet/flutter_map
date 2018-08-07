import 'package:flutter/widgets.dart';

import '../layer/layer.dart';
import '../map/map.dart';

abstract class MapPlugin {
  bool supportsLayer(LayerOptions options);
  Widget createLayer(LayerOptions options, MapState mapState);
}

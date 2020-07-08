import 'package:flutter/widgets.dart';
import 'map.dart';

class MapStateInheritedWidget extends InheritedWidget {
  final MapState mapState;

  MapStateInheritedWidget({
    Key key,
    @required this.mapState,
    @required Widget child,
  }) : super(key: key, child: child);

  @override
  bool updateShouldNotify(MapStateInheritedWidget oldWidget) {
    return oldWidget.mapState.zoom == mapState.zoom &&
        oldWidget.mapState.center == mapState.center &&
        oldWidget.mapState.bounds == mapState.bounds &&
        oldWidget.mapState.rotation == mapState.rotation;
  }

  static MapStateInheritedWidget of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<MapStateInheritedWidget>();
  }
}

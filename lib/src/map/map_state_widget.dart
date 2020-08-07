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
    // mapState will be the same because FlutterMapState create MapState object just once
    // and pass the same instance to the old / new MapStateInheritedWidget
    // Moreover MapStateInheritedWidget child isn't cached so all of it's content will be updated no matter if we return here with false
    return true;
  }

  static MapStateInheritedWidget of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<MapStateInheritedWidget>();
  }
}

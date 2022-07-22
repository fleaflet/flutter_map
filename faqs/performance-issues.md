# Performance Issues

This library does not use native widgets (such as GL), which keeps installation simple and makes the project easier to maintain. However, this does mean performance issues are more likely to appear than some other mapping libraries available for Flutter.

If you're having performance issues, there are a few things you can try to help out.

* Ensure you are using `children` instead of `layers`
* Avoid causing the whole `FlutterMap` widget to rebuild
  * Make full use of `FutureBuilder`s and `StreamBuilder`s - wrap them around `LayerWidget`s
  * Use a `MapController` instead of using methods such as `setState()`
* Reduce the number of extra features on the map, such as `Marker`s and `Polyline`s
* Make full use of plugins, such as clustering plugins

We're slowly tracking and resolving performance issues: see [issue #1165 on GitHub](https://github.com/fleaflet/flutter\_map/issues/1165). Please bear with us whilst we do this: maintainer efforts are stretched at the moment. If you have any ideas on how to help, please leave a comment: it's greatly appreciated!

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_example/widgets/drawer.dart';
import 'package:latlong/latlong.dart';

class AnimatedMapControllerPage extends StatefulWidget {
  static const String route = 'map_controller_animated';

  @override
  AnimatedMapControllerPageState createState() {
    return new AnimatedMapControllerPageState();
  }
}

class AnimatedMapControllerPageState extends State<AnimatedMapControllerPage> with TickerProviderStateMixin {
  // Note the addition of the TickerProviderStateMixin here. If you are getting an error like
  // 'The class 'TickerProviderStateMixin' can't be used as a mixin because it extends a class other than Object.'
  // in your IDE, you can probably fix it by adding an analysis_options.yaml file to your project
  // with the following content:
  //  analyzer:
  //    language:
  //      enableSuperMixins: true
  // See https://github.com/flutter/flutter/issues/14317#issuecomment-361085869
  // This project didn't require that change, so YMMV.

  static LatLng london = new LatLng(51.5, -0.09);
  static LatLng paris = new LatLng(48.8566, 2.3522);
  static LatLng dublin = new LatLng(53.3498, -6.2603);

  MapController mapController;

  void initState() {
    super.initState();
    mapController = new MapController();
  }

  void _animatedMapMove (LatLng destLocation, double destZoom) {
    // Create some tweens. These serve to split up the transition from one location to another.
    // In our case, we want to split the transition be<tween> our current map center and the destination.
    final _latTween = new Tween<double>(begin: mapController.center.latitude, end: destLocation.latitude);
    final _lngTween = new Tween<double>(begin: mapController.center.longitude, end: destLocation.longitude);
    final _zoomTween = new Tween<double>(begin: mapController.zoom, end: destZoom);

    // Create a new animation controller that has a duration and a TickerProvider.
    AnimationController controller = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);
    // The animation determines what path the animation will take. You can try different Curves values, although I found
    // fastOutSlowIn to be my favorite.
    Animation<double> animation =  CurvedAnimation(parent: controller, curve: Curves.fastOutSlowIn);

    controller.addListener(() {
      // Note that the mapController.move doesn't seem to like the zoom animation. This may be a bug in flutter_map.
      mapController.move(LatLng(_latTween.evaluate(animation), _lngTween.evaluate(animation)), _zoomTween.evaluate(animation));
      print("Location (${_latTween.evaluate(animation)} , ${_lngTween.evaluate(animation)}) @ zoom ${_zoomTween.evaluate(animation)}");
    });

    animation.addStatusListener((status) {
      print("$status");
      if (status == AnimationStatus.completed) {
        controller.dispose();
      } else if (status == AnimationStatus.dismissed) {
        controller.dispose();
      }
    });

    controller.forward();

  }

  Widget build(BuildContext context) {
    var markers = <Marker>[
      new Marker(
        width: 80.0,
        height: 80.0,
        point: london,
        builder: (ctx) => new Container(
          key: new Key("blue"),
          child: new FlutterLogo(),
        ),
      ),
      new Marker(
        width: 80.0,
        height: 80.0,
        point: dublin,
        builder: (ctx) => new Container(
          child: new FlutterLogo(
            key: new Key("green"),
            colors: Colors.green,
          ),
        ),
      ),
      new Marker(
        width: 80.0,
        height: 80.0,
        point: paris,
        builder: (ctx) => new Container(
          key: new Key("purple"),
          child: new FlutterLogo(colors: Colors.purple),
        ),
      ),
    ];

    return new Scaffold(
      appBar: new AppBar(title: new Text("Animated MapController")),
      drawer: buildDrawer(context, AnimatedMapControllerPage.route),
      body: new Padding(
        padding: new EdgeInsets.all(8.0),
        child: new Column(
          children: [
            new Padding(
              padding: new EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: new Row(
                children: <Widget>[
                  new MaterialButton(
                    child: new Text("London"),
                    onPressed: () {
                      _animatedMapMove(london, 10.0);
                    },
                  ),
                  new MaterialButton(
                    child: new Text("Paris"),
                    onPressed: () {
                      _animatedMapMove(paris, 5.0);
                    },
                  ),
                  new MaterialButton(
                    child: new Text("Dublin"),
                    onPressed: () {
                      _animatedMapMove(dublin, 5.0);
                    },
                  ),
                ],
              ),
            ),
            new Padding(
              padding: new EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: new Row(
                children: <Widget>[
                  new MaterialButton(
                    child: new Text("Fit Bounds"),
                    onPressed: () {
                      var bounds = new LatLngBounds();
                      bounds.extend(dublin);
                      bounds.extend(paris);
                      bounds.extend(london);
                      mapController.fitBounds(
                        bounds,
                        options: new FitBoundsOptions(
                          padding: new Point<double>(30.0, 0.0),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            new Flexible(
              child: new FlutterMap(
                mapController: mapController,
                options: new MapOptions(
                    center: new LatLng(51.5, -0.09),
                    zoom: 5.0,
                    maxZoom: 5.0,
                    minZoom: 3.0
                ),
                layers: [
                  new TileLayerOptions(
                      urlTemplate:
                      "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                      subdomains: ['a', 'b', 'c']),
                  new MarkerLayerOptions(markers: markers)
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import '../widgets/drawer.dart';
import 'package:latlong/latlong.dart';
import 'dart:math' as math;
import 'package:location/location.dart';
import 'package:flutter/services.dart';

//////////////////////////////
// To set emulator location //
//////////////////////////////
// goto terminal
// > adb devices
//
// telnet to device using the port associated with the device listing from the previous command
// > telnet localhost <port>
//
// now you're connected using telnet you need to authenticate yourself
// your token can be located on your host machine at /Users/<username>/.emulator_console_auth_token
// > auth <Token>
//
// Now set the location with the following command
// > geo fix <longitude> <latitude> <altitude>
//
// e.g.
// > geo fix -0.09 51.5
//
// Type the following to end telnet session
// > exit

class FollowMyLocationPage extends StatefulWidget {
  static const String route = 'follow_my_location';

  @override
  FollowMyLocationPageState createState() {
    return new FollowMyLocationPageState();
  }
}

class FollowMyLocationPageState extends State<FollowMyLocationPage> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  static LatLng london = new LatLng(51.5, -0.09);
  static LatLng paris = new LatLng(48.8566, 2.3522);
  static LatLng dublin = new LatLng(53.3498, -6.2603);

  bool _followMyLocation = false;
  List<CircleMarker> _myLocationMarker = List<CircleMarker>();
  StreamSubscription _locationStream;
  static final _locationUpdater = Location();

  MapController mapController;

  @override
  void initState() {
    super.initState();
    mapController = new MapController();

    // set my location
    updateMyLocation();

    // setup location updates
    _locationStream = _locationUpdater.onLocationChanged().listen((Map<String, double> currentLocation) async {
      await updateMyLocation();
    });
  }

  @override
  void dispose() {
    _locationStream.cancel();
    super.dispose();
  }

  Future<void> updateMyLocation({bool zoomInstant = true}) async {
    Map<String, double> locationMap;
    try {
      locationMap = await _locationUpdater.getLocation();
    } on PlatformException {
      return;
    }

    if (locationMap == null) {
      return;
    }

    LatLng myLocation = LatLng(locationMap['latitude'], locationMap['longitude']);
    print(myLocation);

    double scale = 0.9;

    // Update my location marker
    setState(() {
      _myLocationMarker = [
        CircleMarker(
          color: Colors.black.withAlpha(70),
          point: myLocation,
          radius: 12.0 * scale,
        ),
        CircleMarker(
          color: Colors.white,
          point: myLocation,
          radius: 10.0 * scale,
        ),
        CircleMarker(
          color: Colors.blue[700],
          point: myLocation,
          radius: 9.0 * scale,
        ),
      ];
    });

    if (_followMyLocation) {
      if (zoomInstant) {
        mapController.move(myLocation, mapController.zoom);
      } else {
        var bounds = new LatLngBounds();
        bounds.extend(myLocation);

        animatedMapFitToBounds(
          bounds,
          new FitBoundsOptions(
            padding: new EdgeInsets.only(left: 50.0, right: 50.0),
          ),
          mapController,
        );
      }
    }
  }

  Future<void> zoomToMyLocation() async {
    toggleFollowMyLocation();
    updateMyLocation(zoomInstant: false);
  }

  void toggleFollowMyLocation() {
    setState(() {
      _followMyLocation = !_followMyLocation;
    });
  }

  void startFollowingMyLocation() {
    setState(() {
      _followMyLocation = true;
    });
  }

  void stopFollowingMyLocation() {
    setState(() {
      _followMyLocation = false;
    });
  }

  Widget getMyLocationButton() {
    Icon icon = Icon(Icons.my_location);

    if (_followMyLocation) {
      icon = Icon(Icons.my_location, color: Colors.blue);
    }

    return new RaisedButton(
      child: icon,
      onPressed: () => zoomToMyLocation(),
    );
  }

  Widget build(BuildContext context) {
    return new Scaffold(
      key: _scaffoldKey,
      appBar: new AppBar(title: new Text("Follow My Location")),
      drawer: buildDrawer(context, FollowMyLocationPage.route),
      body: new Padding(
        padding: new EdgeInsets.all(8.0),
        child: new Column(
          children: [
            new Padding(
              padding: new EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: new Row(
                children: <Widget>[
                  new MaterialButton(
                    child: new Text("Zoom to extent"),
                    onPressed: () {
                      stopFollowingMyLocation();
                      LatLngBounds bounds = new LatLngBounds();
                      bounds.extend(london);
                      bounds.extend(paris);
                      bounds.extend(dublin);
                      animatedMapFitToBounds(
                        bounds,
                        FitBoundsOptions(
                          padding: EdgeInsets.all(50),
                        ),
                        mapController,
                      );
                    },
                  ),
                  new MaterialButton(
                    child: new Text("London"),
                    onPressed: () {
                      stopFollowingMyLocation();
                      mapController.move(london, 15.0);
                    },
                  ),
                  new MaterialButton(
                    child: new Text("Paris"),
                    onPressed: () {
                      stopFollowingMyLocation();
                      mapController.move(paris, 15.0);
                    },
                  ),
                  new MaterialButton(
                    child: new Text("Dublin"),
                    onPressed: () {
                      stopFollowingMyLocation();
                      mapController.move(dublin, 15.0);
                    },
                  ),
                ],
              ),
            ),
            new Flexible(
              child: Stack(
                children: <Widget>[
                  new FlutterMap(
                    mapController: mapController,
                    options: new MapOptions(
                      center: new LatLng(51.5, -0.09),
                      zoom: 5.0,
                      maxZoom: 13.0,
                      minZoom: 3.0,
                      onPositionChanged: _positionChanged,
                    ),
                    layers: [
                      new TileLayerOptions(urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", subdomains: ['a', 'b', 'c']),
                      new CircleLayerOptions(circles: _myLocationMarker),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.only(right: 5.0),
                            child: getMyLocationButton(),
                          )
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _positionChanged(MapPosition position, bool isGesture, bool isUserGesture) {
    if (isUserGesture) {
      stopFollowingMyLocation();
    }
  }

  // Note to use an animation for the map you will need to have 'with TickerProviderStateMixin' on your state class
  // that is driving the page containing the map.
  void animatedMapFitToBounds(LatLngBounds destinationBounds, FitBoundsOptions fitBoundsOptions, MapController mapController, {int durationMilliseconds: 800}) {
    // we want to go from the current bounds to our new bounds.
    LatLngBounds curBounds = mapController.bounds; // Our current bounds

    LatLng curNorthEast = curBounds.ne;
    LatLng curSouthWest = curBounds.sw;
    LatLng destNorthEast = destinationBounds.ne;
    LatLng destSouthWest = destinationBounds.sw;

    // Create some tweens. These serve to split up the transition from one location to another.
    // In our case, we want to split the transition be<tween> our current ne and sw and the destinations nw and es bounds.
    final _curLatTweenNe = new Tween<double>(begin: curNorthEast.latitude, end: destNorthEast.latitude);
    final _curLngTweenNe = new Tween<double>(begin: curNorthEast.longitude, end: destNorthEast.longitude);

    final _destLatTweenSW = new Tween<double>(begin: curSouthWest.latitude, end: destSouthWest.latitude);
    final _destLngTweenSW = new Tween<double>(begin: curSouthWest.longitude, end: destSouthWest.longitude);

    // Create a new animation controller that has a duration and a TickerProvider.
    AnimationController controller = AnimationController(duration: Duration(milliseconds: durationMilliseconds), vsync: this);

    // The animation determines what path the animation will take. You can try different Curves values.
    // I found linear to be my favorite for fit to bounds.
    Animation<double> animation = CurvedAnimation(parent: controller, curve: Curves.linear);

    // Start padding at 0! this stops the animation from jumping out and applying additional padding on top of existing padding values
    // Existing padding values have already been taken into account during the current bounds retrieval process.
    final startPadding = EdgeInsets.all(0.0);
    final destPadding = fitBoundsOptions.padding;
    final _curLeft = new Tween<double>(begin: startPadding.left, end: destPadding.left);
    final _curTop = new Tween<double>(begin: startPadding.top, end: destPadding.top);
    final _curRight = new Tween<double>(begin: startPadding.right, end: destPadding.right);
    final _curBottom = new Tween<double>(begin: startPadding.bottom, end: destPadding.bottom);

    controller.addListener(() {
      var bounds = new LatLngBounds();
      bounds.extend(new LatLng(_curLatTweenNe.evaluate(animation), _curLngTweenNe.evaluate(animation)));
      bounds.extend(new LatLng(_destLatTweenSW.evaluate(animation), _destLngTweenSW.evaluate(animation)));

      // calc padding
      var padding = new EdgeInsets.fromLTRB(_curLeft.evaluate(animation), _curTop.evaluate(animation), _curRight.evaluate(animation), _curBottom.evaluate(animation));
      fitBoundsOptions = new FitBoundsOptions(zoom: fitBoundsOptions.zoom, maxZoom: fitBoundsOptions.maxZoom, padding: padding);

      mapController.fitBounds(bounds, options: fitBoundsOptions);

      // zoom again on complete, this fixes text rendering issues.
      if (animation.isCompleted) {
        List<LatLng> boundLatLngs = [bounds.northEast, bounds.southEast, bounds.northWest, bounds.southWest];
        mapController.move(getCenterOfLocations(boundLatLngs), mapController.zoom);
      }
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed || status == AnimationStatus.dismissed) {
        controller.dispose();
      }
    });

    controller.forward();
  }

  static LatLng getCenterOfLocations(List<LatLng> locations) {
    // we don't have a list of locations
    if (locations == null || locations.length == 0) {
      return null;
    }

    // if there is only one return it
    if (locations.length == 1) {
      return locations[0];
    }

    // Convert the list of location latitude, longitude pair into a unit-length 3D vector
    // Sum each of those vectors
    double x = 0.0;
    double y = 0.0;
    double z = 0.0;

    for (LatLng location in locations) {
      double latitude = location.latitude * math.pi / 180.0;
      double longitude = location.longitude * math.pi / 180.0;

      x += math.cos(latitude) * math.cos(longitude);
      y += math.cos(latitude) * math.sin(longitude);
      z += math.sin(latitude);
    }

    // Normalise the resulting vector
    int total = locations.length;
    x = x / total;
    y = y / total;
    z = z / total;

    // Convert back to spherical coordinates (latitude, longitude)
    double centralLongitude = math.atan2(y, x);
    double centralSquareRoot = math.sqrt(x * x + y * y);
    double centralLatitude = math.atan2(z, centralSquareRoot);

    return new LatLng(centralLatitude * 180.0 / math.pi, centralLongitude * 180.0 / math.pi);
  }
}

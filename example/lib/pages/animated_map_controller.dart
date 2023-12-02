import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:flutter_map_example/widgets/drawer/menu_drawer.dart';
import 'package:latlong2/latlong.dart';

class AnimatedMapControllerPage extends StatefulWidget {
  static const String route = '/map_controller_animated';

  const AnimatedMapControllerPage({super.key});

  @override
  AnimatedMapControllerPageState createState() =>
      AnimatedMapControllerPageState();
}

class AnimatedMapControllerPageState extends State<AnimatedMapControllerPage>
    with TickerProviderStateMixin {
  static const _startedId = 'AnimatedMapController#MoveStarted';
  static const _inProgressId = 'AnimatedMapController#MoveInProgress';
  static const _finishedId = 'AnimatedMapController#MoveFinished';

  static const _london = LatLng(51.5, -0.09);
  static const _paris = LatLng(48.8566, 2.3522);
  static const _dublin = LatLng(53.3498, -6.2603);

  static const _markers = [
    Marker(
      width: 80,
      height: 80,
      point: _london,
      child: FlutterLogo(key: ValueKey('blue')),
    ),
    Marker(
      width: 80,
      height: 80,
      point: _dublin,
      child: FlutterLogo(key: ValueKey('green')),
    ),
    Marker(
      width: 80,
      height: 80,
      point: _paris,
      child: FlutterLogo(key: ValueKey('purple')),
    ),
  ];

  final mapController = MapController();

  void _animatedMapMove(LatLng destLocation, double destZoom) {
    // Create some tweens. These serve to split up the transition from one location to another.
    // In our case, we want to split the transition be<tween> our current map center and the destination.
    final camera = mapController.camera;
    final latTween = Tween<double>(
        begin: camera.center.latitude, end: destLocation.latitude);
    final lngTween = Tween<double>(
        begin: camera.center.longitude, end: destLocation.longitude);
    final zoomTween = Tween<double>(begin: camera.zoom, end: destZoom);

    // Create a animation controller that has a duration and a TickerProvider.
    final controller = AnimationController(
        duration: const Duration(milliseconds: 500), vsync: this);
    // The animation determines what path the animation will take. You can try different Curves values, although I found
    // fastOutSlowIn to be my favorite.
    final Animation<double> animation =
        CurvedAnimation(parent: controller, curve: Curves.fastOutSlowIn);

    // Note this method of encoding the target destination is a workaround.
    // When proper animated movement is supported (see #1263) we should be able
    // to detect an appropriate animated movement event which contains the
    // target zoom/center.
    final startIdWithTarget =
        '$_startedId#${destLocation.latitude},${destLocation.longitude},$destZoom';
    bool hasTriggeredMove = false;

    controller.addListener(() {
      final String id;
      if (animation.value == 1.0) {
        id = _finishedId;
      } else if (!hasTriggeredMove) {
        id = startIdWithTarget;
      } else {
        id = _inProgressId;
      }

      hasTriggeredMove |= mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
        id: id,
      );
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        controller.dispose();
      } else if (status == AnimationStatus.dismissed) {
        controller.dispose();
      }
    });

    controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Animated MapController')),
      drawer: const MenuDrawer(AnimatedMapControllerPage.route),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: <Widget>[
                  MaterialButton(
                    onPressed: () => _animatedMapMove(_london, 10),
                    child: const Text('London'),
                  ),
                  MaterialButton(
                    onPressed: () => _animatedMapMove(_paris, 5),
                    child: const Text('Paris'),
                  ),
                  MaterialButton(
                    onPressed: () => _animatedMapMove(_dublin, 5),
                    child: const Text('Dublin'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: <Widget>[
                  MaterialButton(
                    onPressed: () {
                      final bounds = LatLngBounds.fromPoints([
                        _dublin,
                        _paris,
                        _london,
                      ]);

                      mapController.fitCamera(
                        CameraFit.bounds(
                          bounds: bounds,
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                        ),
                      );
                    },
                    child: const Text('Fit Bounds'),
                  ),
                  MaterialButton(
                    onPressed: () {
                      final bounds = LatLngBounds.fromPoints([
                        _dublin,
                        _paris,
                        _london,
                      ]);

                      final constrained = CameraFit.bounds(
                        bounds: bounds,
                      ).fit(mapController.camera);
                      _animatedMapMove(constrained.center, constrained.zoom);
                    },
                    child: const Text('Fit Bounds animated'),
                  ),
                ],
              ),
            ),
            Flexible(
              child: FlutterMap(
                mapController: mapController,
                options: const MapOptions(
                  initialCenter: LatLng(51.5, -0.09),
                  initialZoom: 5,
                  maxZoom: 10,
                  minZoom: 3,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'dev.fleaflet.flutter_map.example',
                    tileProvider: CancellableNetworkTileProvider(),
                    tileUpdateTransformer: _animatedMoveTileUpdateTransformer,
                  ),
                  const MarkerLayer(markers: _markers),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Causes tiles to be prefetched at the target location and disables pruning
/// whilst animating movement. When proper animated movement is added (see
/// #1263) we should just detect the appropriate AnimatedMove events and
/// use their target zoom/center.
final _animatedMoveTileUpdateTransformer =
    TileUpdateTransformer.fromHandlers(handleData: (updateEvent, sink) {
  final mapEvent = updateEvent.mapEvent;

  final id = mapEvent is MapEventMove ? mapEvent.id : null;
  if (id?.startsWith(AnimatedMapControllerPageState._startedId) ?? false) {
    final parts = id!.split('#')[2].split(',');
    final lat = double.parse(parts[0]);
    final lon = double.parse(parts[1]);
    final zoom = double.parse(parts[2]);

    // When animated movement starts load tiles at the target location and do
    // not prune. Disabling pruning means existing tiles will remain visible
    // whilst animating.
    sink.add(
      updateEvent.loadOnly(
        loadCenterOverride: LatLng(lat, lon),
        loadZoomOverride: zoom,
      ),
    );
  } else if (id == AnimatedMapControllerPageState._inProgressId) {
    // Do not prune or load whilst animating so that any existing tiles remain
    // visible. A smarter implementation may start pruning once we are close to
    // the target zoom/location.
  } else if (id == AnimatedMapControllerPageState._finishedId) {
    // We already prefetched the tiles when animation started so just prune.
    sink.add(updateEvent.pruneOnly());
  } else {
    sink.add(updateEvent);
  }
});

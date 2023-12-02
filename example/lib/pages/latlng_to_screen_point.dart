import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_example/misc/tile_providers.dart';
import 'package:flutter_map_example/widgets/drawer/menu_drawer.dart';
import 'package:latlong2/latlong.dart';

class LatLngToScreenPointPage extends StatefulWidget {
  static const String route = '/latlng_to_screen_point';

  const LatLngToScreenPointPage({super.key});

  @override
  State<LatLngToScreenPointPage> createState() =>
      _LatLngToScreenPointPageState();
}

class _LatLngToScreenPointPageState extends State<LatLngToScreenPointPage> {
  static const double pointSize = 65;

  final mapController = MapController();

  LatLng? tappedCoords;
  Point<double>? tappedPoint;

  @override
  void initState() {
    super.initState();

    SchedulerBinding.instance
        .addPostFrameCallback((_) => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Tap/click to set coordinate')),
            ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lat/Lng 🡒 Screen Point')),
      drawer: const MenuDrawer(LatLngToScreenPointPage.route),
      body: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: const LatLng(51.5, -0.09),
              initialZoom: 11,
              interactionOptions: const InteractionOptions(
                flags: ~InteractiveFlag.doubleTapZoom,
              ),
              onTap: (_, latLng) {
                final point = mapController.camera
                    .latLngToScreenPoint(tappedCoords = latLng);
                setState(() => tappedPoint = Point(point.x, point.y));
              },
            ),
            children: [
              openStreetMapTileLayer,
              if (tappedCoords != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      width: pointSize,
                      height: pointSize,
                      point: tappedCoords!,
                      child: const Icon(
                        Icons.circle,
                        size: 10,
                        color: Colors.black,
                      ),
                    )
                  ],
                ),
            ],
          ),
          if (tappedPoint != null)
            Positioned(
              left: tappedPoint!.x - 60 / 2,
              top: tappedPoint!.y - 60 / 2,
              child: const IgnorePointer(
                child: Icon(
                  Icons.center_focus_strong_outlined,
                  color: Colors.black,
                  size: 60,
                ),
              ),
            )
        ],
      ),
    );
  }
}

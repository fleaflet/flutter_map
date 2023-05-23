import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_example/pages/fallback_url/fallback_url.dart';
import 'package:latlong2/latlong.dart';

class FallbackUrlOfflinePage extends StatelessWidget {
  static const String route = '/fallback_url_offline';

  const FallbackUrlOfflinePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FallbackUrlPage(
      route: route,
      tileLayer: TileLayer(
        tileProvider: AssetTileProvider(),
        maxZoom: 14,
        urlTemplate: 'assets/fake/tiles/{z}/{x}/{y}.png',
        fallbackUrl: 'assets/map/anholt_osmbright/{z}/{x}/{y}.png',
      ),
      title: 'Fallback URL AssetTileProvider',
      description:
          'Map with a fake asset path, should be using the fallback to show Anholt Island, Denmark.',
      maxZoom: 14,
      minZoom: 12,
      center: const LatLng(56.704173, 11.543808),
    );
  }
}

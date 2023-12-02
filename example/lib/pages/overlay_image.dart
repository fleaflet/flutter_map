import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_example/misc/tile_providers.dart';
import 'package:flutter_map_example/widgets/drawer/menu_drawer.dart';
import 'package:latlong2/latlong.dart';

class OverlayImagePage extends StatelessWidget {
  static const String route = '/overlay_image';

  const OverlayImagePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Overlay Image')),
      drawer: const MenuDrawer(route),
      body: FlutterMap(
        options: const MapOptions(
          initialCenter: LatLng(51.5, -0.09),
          initialZoom: 6,
        ),
        children: [
          openStreetMapTileLayer,
          OverlayImageLayer(
            overlayImages: [
              OverlayImage(
                bounds: LatLngBounds(
                  const LatLng(51.5, -0.09),
                  const LatLng(48.8566, 2.3522),
                ),
                opacity: 0.8,
                imageProvider: const NetworkImage(
                    'https://images.pexels.com/photos/231009/pexels-photo-231009.jpeg?auto=compress&cs=tinysrgb&dpr=2&h=300&w=600'),
              ),
              const RotatedOverlayImage(
                topLeftCorner: LatLng(53.377, -2.999),
                bottomLeftCorner: LatLng(52.503, -1.868),
                bottomRightCorner: LatLng(53.475, 0.275),
                opacity: 0.8,
                imageProvider: NetworkImage(
                    'https://images.pexels.com/photos/231009/pexels-photo-231009.jpeg?auto=compress&cs=tinysrgb&dpr=2&h=300&w=600'),
              ),
            ],
          ),
          const MarkerLayer(
            markers: [
              Marker(
                point: LatLng(53.377, -2.999),
                child: _Circle(color: Colors.redAccent, label: 'TL'),
              ),
              Marker(
                point: LatLng(52.503, -1.868),
                child: _Circle(color: Colors.redAccent, label: 'BL'),
              ),
              Marker(
                point: LatLng(53.475, 0.275),
                child: _Circle(color: Colors.redAccent, label: 'BR'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  final String label;
  final Color color;

  const _Circle({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Center(
        child: Text(
          label,
          style:
              const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }
}

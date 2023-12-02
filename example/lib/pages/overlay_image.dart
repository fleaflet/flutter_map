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
          initialCenter: (lat: 51.5, lon: 0.09),
          initialZoom: 6,
        ),
        children: [
          openStreetMapTileLayer,
          OverlayImageLayer(
            overlayImages: [
              OverlayImage(
                bounds: LatLngBounds(
                  const (lat: 51.5, lon: 0.09),
                  const (lat: 48.8566, lon: 2.3522),
                ),
                opacity: 0.8,
                imageProvider: const NetworkImage(
                    'https://images.pexels.com/photos/231009/pexels-photo-231009.jpeg?auto=compress&cs=tinysrgb&dpr=2&h=300&w=600'),
              ),
              const RotatedOverlayImage(
                topLeftCorner: (lat: 53.377, lon: 2.999),
                bottomLeftCorner: (lat: 52.503, lon: 1.868),
                bottomRightCorner: (lat: 53.475, lon: 0.275),
                opacity: 0.8,
                imageProvider: NetworkImage(
                    'https://images.pexels.com/photos/231009/pexels-photo-231009.jpeg?auto=compress&cs=tinysrgb&dpr=2&h=300&w=600'),
              ),
            ],
          ),
          const MarkerLayer(
            markers: [
              Marker(
                point: (lat: 53.377, lon: 2.999),
                child: _Circle(color: Colors.redAccent, label: 'TL'),
              ),
              Marker(
                point: (lat: 52.503, lon: 1.868),
                child: _Circle(color: Colors.redAccent, label: 'BL'),
              ),
              Marker(
                point: (lat: 53.475, lon: 0.275),
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

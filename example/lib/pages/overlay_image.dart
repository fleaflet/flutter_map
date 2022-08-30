import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_example/widgets/drawer.dart';
import 'package:latlong2/latlong.dart';

class OverlayImagePage extends StatelessWidget {
  static const String route = 'overlay_image';

  const OverlayImagePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final topLeftCorner = LatLng(53.377, -2.999);
    final bottomRightCorner = LatLng(53.475, 0.275);
    final bottomLeftCorner = LatLng(52.503, -1.868);

    final overlayImages = <BaseOverlayImage>[
      OverlayImage(
          bounds: LatLngBounds(LatLng(51.5, -0.09), LatLng(48.8566, 2.3522)),
          opacity: 0.8,
          imageProvider: const NetworkImage(
              'https://images.pexels.com/photos/231009/pexels-photo-231009.jpeg?auto=compress&cs=tinysrgb&dpr=2&h=300&w=600')),
      RotatedOverlayImage(
          topLeftCorner: topLeftCorner,
          bottomLeftCorner: bottomLeftCorner,
          bottomRightCorner: bottomRightCorner,
          opacity: 0.8,
          imageProvider: const NetworkImage(
              'https://images.pexels.com/photos/231009/pexels-photo-231009.jpeg?auto=compress&cs=tinysrgb&dpr=2&h=300&w=600')),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Overlay Image')),
      drawer: buildDrawer(context, route),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 8, bottom: 8),
              child: Text('This is a map that is showing (51.5, -0.9).'),
            ),
            Flexible(
              child: FlutterMap(
                options: MapOptions(
                  center: LatLng(51.5, -0.09),
                  zoom: 6,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    subdomains: ['a', 'b', 'c'],
                    userAgentPackageName: 'dev.fleaflet.flutter_map.example',
                  ),
                  OverlayImageLayer(
                          overlayImages: overlayImages),
                  MarkerLayer(markers: [
                    Marker(
                        point: topLeftCorner,
                        builder: (context) => const _Circle(
                            color: Colors.redAccent, label: "TL")),
                    Marker(
                        point: bottomLeftCorner,
                        builder: (context) => const _Circle(
                            color: Colors.redAccent, label: "BL")),
                    Marker(
                        point: bottomRightCorner,
                        builder: (context) => const _Circle(
                            color: Colors.redAccent, label: "BR")),
                  ])
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  final String label;
  final Color color;

  const _Circle({Key? key, required this.label, required this.color})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ));
  }
}

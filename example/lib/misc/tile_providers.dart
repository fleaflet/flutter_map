import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart';
import 'package:http/retry.dart';
import 'package:url_launcher/url_launcher.dart';

final _httpClient = RetryClient(Client());

class PrimaryTileLayer extends StatelessWidget {
  const PrimaryTileLayer({super.key, this.showAttributionImmediately = false});

  final bool showAttributionImmediately;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'dev.fleaflet.flutter_map.demo',
          tileProvider: NetworkTileProvider(httpClient: _httpClient),
          maxNativeZoom: 19,
        ),
        RichAttributionWidget(
          popupInitialDisplayDuration: showAttributionImmediately
              ? const Duration(seconds: 5)
              : Duration.zero,
          animationConfig: const ScaleRAWA(),
          attributions: [
            TextSourceAttribution(
              'OpenStreetMap contributors',
              onTap: () async =>
                  launchUrl(Uri.parse('https://openstreetmap.org/copyright')),
            ),
          ],
        ),
      ],
    );
  }
}

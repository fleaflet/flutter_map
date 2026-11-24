import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart';
import 'package:http/retry.dart';
import 'package:url_launcher/url_launcher.dart';

final _httpClient = RetryClient(Client());

class PrimaryTileLayer extends StatelessWidget {
  const PrimaryTileLayer({super.key, this.includeAttribution = true});

  final bool includeAttribution;

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
        // TODO: This means that this appears beneath any other layers in the
        // map. Use `AttributionLayer` directly in pages.
        if (includeAttribution) const AttributionLayer(),
      ],
    );
  }
}

class AttributionLayer extends StatelessWidget {
  const AttributionLayer({
    super.key,
    this.backgroundColor,
    this.showAttributionImmediately = false,
  });

  final Color? backgroundColor;
  final bool showAttributionImmediately;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ExpandableAttributionLayer(
        backgroundColor:
            backgroundColor ??
            // Just a bit of fun, and showing that it can handle it
            Colors.primaries[Random().nextInt(Colors.primaries.length)],
        initialExpansionDuration: showAttributionImmediately
            ? const Duration(seconds: 3)
            : Duration.zero,
        adjacentPersistentChild: SizedBox.square(
          dimension: 26,
          child: Image.asset('assets/ProjectIcon.png'),
        ),
        expandedBuilder: (context) => Text.rich(
          maxLines: 1,
          softWrap: false,
          TextSpan(
            children: [
              const TextSpan(text: '© '),
              TextSpan(
                text: 'OpenStreetMap',
                style: TextStyle(
                  decoration: TextDecoration.underline,
                  decorationColor: DefaultTextStyle.of(context).style.color,
                ),
                recognizer: TapGestureRecognizer()
                  ..onTap = () => launchUrl(
                    Uri.parse('https://www.openstreetmap.org/copyright'),
                  ),
              ),
              const TextSpan(text: ' contributors'),
            ],
          ),
        ),
      ),
    );
  }
}

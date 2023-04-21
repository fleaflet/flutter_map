import 'package:flutter_map/flutter_map.dart';
import 'package:url_launcher/url_launcher.dart';

final standardSingleAttributionLayer = [
  RichAttributionWidget(
    attributions: [
      TextSourceAttribution(
        'OpenStreetMap contributors',
        onTap: () => launchUrl(
          Uri.parse('https://openstreetmap.org/copyright'),
        ),
      ),
    ],
  ),
];

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_example/widgets/drawer/menu_drawer.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class WMSLayerPage extends StatelessWidget {
  static const String route = '/wms_layer';

  const WMSLayerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WMS Layer')),
      drawer: const MenuDrawer(route),
      body: FlutterMap(
        options: const MapOptions(
          initialCenter: LatLng(42.58, 12.43),
          initialZoom: 6,
        ),
        children: [
          TileLayer(
            wmsOptions: WMSTileLayerOptions(
              baseUrl: 'https://tiles.maps.eox.at/wms?',
              layers: const ['s2cloudless-2021_3857'],
            ),
            subdomains: const ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'],
            userAgentPackageName: 'dev.fleaflet.flutter_map.example',
          ),
          RichAttributionWidget(
            popupInitialDisplayDuration: const Duration(seconds: 5),
            attributions: [
              TextSourceAttribution(
                'Sentinel-2 provided by the European Commission (free, full '
                'and open access) [Sentinel-2 cloudless 2016, 2018, 2019, '
                '2020, 2021, 2022 & 2023]',
                onTap: () => launchUrl(Uri.parse(
                  'https://sentinel.esa.int/documents/247904/690755/Sentinel_Data_Legal_Notice',
                )),
                prependCopyright: false,
              ),
              TextSourceAttribution(
                'OpenStreetMap © OpenStreetMap contributors [Terrain Light, '
                'Terrain, OpenStreetMap, Overlay]',
                onTap: () => launchUrl(Uri.parse(
                  'http://www.openstreetmap.org/copyright',
                )),
                prependCopyright: false,
              ),
              TextSourceAttribution(
                'NaturalEarth public domain [Terrain Light, Terrain, Overlay]',
                onTap: () => launchUrl(Uri.parse(
                  'http://www.naturalearthdata.com/about/terms-of-use/',
                )),
                prependCopyright: false,
              ),
              const TextSourceAttribution(
                'EUDEM © Produced using Copernicus data and information funded '
                'by the European Union [Terrain]',
                prependCopyright: false,
              ),
              TextSourceAttribution(
                'ASTER GDEM is a product of METI and NASA [Terrain Light]',
                onTap: () => launchUrl(Uri.parse(
                  'https://lpdaac.usgs.gov/products/aster_policies',
                )),
                prependCopyright: false,
              ),
              TextSourceAttribution(
                'SRTM © NASA [Terrain]',
                onTap: () => launchUrl(Uri.parse('http://www.nasa.gov/')),
                prependCopyright: false,
              ),
              TextSourceAttribution(
                'GTOPO30 Data available from the U.S. Geological Survey '
                '[Terrain Light, Terrain]',
                onTap: () => launchUrl(Uri.parse(
                  'https://lta.cr.usgs.gov/GTOPO30',
                )),
                prependCopyright: false,
              ),
              const TextSourceAttribution(
                'CleanTOPO2 public domain [Terrain]',
                prependCopyright: false,
              ),
              TextSourceAttribution(
                'GEBCO © GEBCO [Terrain Light]',
                onTap: () => launchUrl(Uri.parse('http://www.gebco.net/')),
                prependCopyright: false,
              ),
              TextSourceAttribution(
                'GlobCover © ESA [Terrain]',
                onTap: () => launchUrl(Uri.parse(
                  'http://due.esrin.esa.int/page_globcover.php',
                )),
                prependCopyright: false,
              ),
              const TextSourceAttribution(
                "Blue Marble © NASA's Earth Observatory [Blue Marble]",
                prependCopyright: false,
              ),
              const TextSourceAttribution(
                "Black Marble © NASA's Earth Observatory [Black Marble]",
                prependCopyright: false,
              ),
              TextSourceAttribution(
                'Rendering: © EOX [Terrain Light, Terrain, OpenStreetMap, '
                'Overlay]',
                onTap: () => launchUrl(Uri.parse('http://eox.at/')),
                prependCopyright: false,
              ),
              TextSourceAttribution(
                'Rendering: © MapServer [OpenStreetMap, Overlay]',
                onTap: () => launchUrl(Uri.parse(
                  'https://github.com/mapserver/basemaps',
                )),
                prependCopyright: false,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

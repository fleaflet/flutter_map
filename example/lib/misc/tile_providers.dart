import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart';
import 'package:http/retry.dart';
//import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';

final httpClient = RetryClient(Client());

TileLayer get openStreetMapTileLayer => TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'dev.fleaflet.flutter_map.example',
      // Use the recommended flutter_map_cancellable_tile_provider package to
      // support the cancellation of loading tiles.
      // TODO: change
      tileProvider: NetworkTileProvider(httpClient: httpClient),
    );

import 'package:flutter_map/src/layer/tile_layer/tile_provider/base_tile_provider.dart';
import 'package:http/http.dart';
import 'package:http/retry.dart';
import 'package:meta/meta.dart';

@internal
abstract class NetworkTileProviderBase extends TileProvider {
  NetworkTileProviderBase({
    super.headers = const {},
    BaseClient? httpClient,
  }) : httpClient = httpClient ?? RetryClient(Client());

  final BaseClient httpClient;
}

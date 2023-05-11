import 'package:flutter/rendering.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_provider/network_providers/tile_provider_base.dart';
import 'package:http/retry.dart';

/// [TileProvider] to fetch tiles from the network
///
/// Stub for IO & web specific implementations for [NetworkTileProviderBase].
///
/// In both implemenations, by default, a [RetryClient] is used to retry failed
/// requests.
///
/// The web implmentation does not support changing the 'User-Agent' header, due
/// to a Dart/browser limitation.
class NetworkTileProvider extends NetworkTileProviderBase {
  /// [TileProvider] to fetch tiles from the network
  ///
  /// Stub for IO & web specific implementations for [NetworkTileProviderBase].
  ///
  /// In both implemenations, by default, a [RetryClient] is used to retry failed
  /// requests.
  ///
  /// The web implmentation does not support changing the 'User-Agent' header,
  /// due to a Dart/browser limitation.
  NetworkTileProvider({
    super.headers = const {},
    super.httpClient,
  });

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      throw UnimplementedError();
}

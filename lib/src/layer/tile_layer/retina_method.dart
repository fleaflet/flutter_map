part of 'tile_layer.dart';

/// Describes the methods available to acquire/simulate higher resolution tiles
/// for high density/retina displays
///
/// {@template retina_explanation}
/// Map tiles can look pixelated on high density displays, so some servers
/// support "@2x" tiles, which are tiles at twice the resolution of normal.
/// However, not all tile servers support this, so flutter_map can attempt to
/// simulate retina behaviour.
/// {@endtemplate}
enum RetinaMethod {
  /// Choose between disabling retina mode and [preferServer] based on
  /// [TileLayer.retinaContext].
  ///
  /// If [TileLayer.retinaContext] is not present, or (when queried) it does
  /// not represent a high density display, retina mode is disabled. Otherwise,
  /// [preferServer] is inferred.
  auto,

  /// Uses the [TileLayer.urlTemplate] to determine whether the tile server
  /// supports native retina tiles, and uses that when possible, falling back to
  /// simulating retina behaviour.
  ///
  /// The presence of the '{r}' placeholder in the [TileLayer.urlTemplate] is
  /// inferred to mean that the tile server supports native retina tiles.
  preferServer,

  /// Simulates higher resolution tiles by requesting four tiles at a larger zoom
  /// level and combining them together in place of one
  ///
  /// However, if the tile server supports retina tiles natively, you should
  /// always use them instead. Therefore, this option is not recommended, and you
  /// should use [auto], or at least [preferServer]. As such, this is marked as
  /// visible for testing only, as there is realistically no other reason to
  /// choose this option.
  ///
  /// Note that this will drastically increase the number of tile requests, at
  /// your own expense.
  ///
  /// Also note that the maximum zoom level will be decreased by one (since thi
  /// behaviour is simulated with [TileLayer.zoomOffset]).
  @visibleForTesting
  forceSimulation,
}

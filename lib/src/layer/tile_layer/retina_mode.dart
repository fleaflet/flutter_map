part of 'tile_layer.dart';

/// Retina mode improves the resolution of map tiles, particularly on high
/// density displays
///
/// Map tiles can look pixelated on high density displays, so some servers
/// support "@2x" tiles, which are tiles at twice the resolution of normal.
/// However, not all tile servers support this, so flutter_map can attempt to
/// simulate retina behaviour.
///
/// ---
///
/// Enabling or disabling of retina mode functionality is done through
/// [TileLayer]'s constructor, with the `retinaMode` argument.
///
/// If this is `true`, the '{r}' placeholder inside [TileLayer.urlTemplate] will
/// be filled with "@2x" to request high resolution tiles from the server, if it
/// is present. If not present, flutter_map will simulate retina behaviour by
/// requesting four tiles at a larger zoom level and combining them together
/// in place of one.
///
/// Note that simulating retina mode will increase tile requests, decrease the
/// effective maximum zoom by 1, and may result in map labels/text/POIs appearing
/// smaller than normal.
///
/// It is recommended to enable retina mode on high density retina displays
/// automatically, using [RetinaMode.isHighDensity].
///
/// If this is `false` (default), then retina mode is disabled.
///
/// ---
///
/// Caution is advised when mixing retina mode with different `tileSize`s,
/// especially when simulating retina mode.
///
/// It is expected that [TileLayer.fallbackUrl] follows the same retina support
/// behaviour as [TileLayer.urlTemplate].
enum RetinaMode {
  /// Resolved to disable retina mode
  ///
  /// This should not be referred to by users, but is open for internal and
  /// plugin use by [TileLayer.resolvedRetinaMode].
  disabled('Disabled'),

  /// Resolved to use the '{r}' placeholder to request native retina tiles from
  /// the server
  ///
  /// This should not be referred to by users, but is open for internal and
  /// plugin use by [TileLayer.resolvedRetinaMode].
  server('Server'),

  /// Resolved to simulate retina mode
  ///
  /// This should not be referred to by users, but is open for internal and
  /// plugin use by [TileLayer.resolvedRetinaMode].
  simulation('Simulation');

  /// The readable name of the [RetinaMode]
  final String friendlyName;

  const RetinaMode(this.friendlyName);

  /// Recommended switching method to assign to [TileLayer]`.retinaMode`
  ///
  /// Returns `true` when the [MediaQuery] of [context] returns an indication
  /// of a high density display.
  static bool isHighDensity(BuildContext context) =>
      MediaQuery.of(context).devicePixelRatio > 1.0;
}

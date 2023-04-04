import 'package:latlong2/latlong.dart';

/// Describes whether loading and/or pruning should occur and allows overriding
/// the load center/zoom. If loading/pruning is not desired the
/// [TileUpdateTransformer] should just not add a TileUpdateEvent to its sink.
class TileUpdateEvent {
  final bool load;
  final bool prune;
  final LatLng? loadCenterOverride;
  final double? loadZoomOverride;

  /// Do not load new tiles, only prune old ones.
  const TileUpdateEvent.pruneOnly()
      : load = false,
        prune = true,
        loadCenterOverride = null,
        loadZoomOverride = null;

  /// Load new tiles, do not prune old ones. The loading center/zoom can be
  /// overriden with [loadCenterOverride] and [loadZoomOverride] otherwise they
  /// will default to the map's current center/zoom.
  const TileUpdateEvent.loadOnly({
    this.loadCenterOverride,
    this.loadZoomOverride,
  })  : load = true,
        prune = false;

  /// Load new tiles and prune old ones. The loading center/zoom can be
  /// overriden with [loadCenterOverride] and [loadZoomOverride] otherwise they
  /// will default to the map's current center/zoom.
  const TileUpdateEvent.loadAndPrune({
    this.loadCenterOverride,
    this.loadZoomOverride,
  })  : load = true,
        prune = true;
}

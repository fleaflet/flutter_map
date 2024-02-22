import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:meta/meta.dart';

/// Describes whether loading and/or pruning should occur and allows overriding
/// the load center/zoom.
@immutable
class TileUpdateEvent {
  /// The [MapEvent] that caused the [TileUpdateEvent].
  final MapEvent mapEvent;

  /// Set to true if the tiles should get loaded.
  final bool load;

  /// Set to true if the tiles should get pruned.
  final bool prune;

  /// An optional overridden center value while loading.
  final LatLng? loadCenterOverride;

  /// An optional overridden zoom value while loading.
  final double? loadZoomOverride;

  /// Create a new [TileUpdateEvent].
  const TileUpdateEvent({
    required this.mapEvent,
    this.load = true,
    this.prune = true,
    this.loadCenterOverride,
    this.loadZoomOverride,
  });

  /// Getter for the map zoom, respects a potential overridden zoom
  /// when loading tiles.
  double get zoom => loadZoomOverride ?? mapEvent.camera.zoom;

  /// Getter for the map center, respects a potential overridden map center
  /// when loading tiles.
  LatLng get center => loadCenterOverride ?? mapEvent.camera.center;

  /// Shortcut for the [MapCamera] of the event.
  MapCamera get camera => mapEvent.camera;

  /// Returns a copy of this TileUpdateEvent with only pruning enabled and the
  /// loadCenterOverride/loadZoomOverride removed.
  TileUpdateEvent pruneOnly() => TileUpdateEvent(
        mapEvent: mapEvent,
        load: false,
      );

  /// Returns a copy of this TileUpdateEvent with only loading enabled. The
  /// loading center/zoom can be overriden with [loadCenterOverride] and
  /// [loadZoomOverride] otherwise they will default to the map's current
  /// center/zoom.
  TileUpdateEvent loadOnly({
    LatLng? loadCenterOverride,
    double? loadZoomOverride,
  }) =>
      TileUpdateEvent(
        mapEvent: mapEvent,
        prune: false,
        loadCenterOverride: loadCenterOverride,
        loadZoomOverride: loadZoomOverride,
      );

  /// Returns a copy of this TileUpdateEvent with loading and pruning enabled.
  /// The loading center/zoom can be overriden with [loadCenterOverride] and
  /// [loadZoomOverride] otherwise they will default to the map's current
  /// center/zoom.
  TileUpdateEvent loadAndPrune({
    LatLng? loadCenterOverride,
    double? loadZoomOverride,
  }) =>
      TileUpdateEvent(
        mapEvent: mapEvent,
        loadCenterOverride: loadCenterOverride,
        loadZoomOverride: loadZoomOverride,
      );

  /// Checks if the [MapEvent] has been caused by a tap.
  bool wasTriggeredByTap() =>
      mapEvent is MapEventTap ||
      mapEvent is MapEventSecondaryTap ||
      mapEvent is MapEventLongPress;

  @override
  String toString() =>
      'TileUpdateEvent(mapEvent: $mapEvent, load: $load, prune: $prune, loadCenterOverride: $loadCenterOverride, loadZoomOverride: $loadZoomOverride)';
}

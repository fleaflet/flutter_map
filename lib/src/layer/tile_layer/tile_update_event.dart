import 'package:flutter_map/src/gestures/map_events.dart';
import 'package:flutter_map/src/map/camera.dart';
import 'package:latlong2/latlong.dart';

/// Describes whether loading and/or pruning should occur and allows overriding
/// the load center/zoom.
class TileUpdateEvent {
  final MapEvent mapEvent;
  final bool load;
  final bool prune;
  final LatLng? loadCenterOverride;
  final double? loadZoomOverride;

  const TileUpdateEvent({
    required this.mapEvent,
    this.load = true,
    this.prune = true,
    this.loadCenterOverride,
    this.loadZoomOverride,
  });

  double get zoom => loadZoomOverride ?? mapEvent.camera.zoom;

  LatLng get center => loadCenterOverride ?? mapEvent.camera.center;

  MapCamera get camera => mapEvent.camera;

  /// Returns a copy of this TileUpdateEvent with only pruning enabled and the
  /// loadCenterOverride/loadZoomOverride removed.
  TileUpdateEvent pruneOnly() => TileUpdateEvent(
        mapEvent: mapEvent,
        load: false,
        prune: true,
        loadCenterOverride: null,
        loadZoomOverride: null,
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
        load: true,
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
        load: true,
        prune: true,
        loadCenterOverride: loadCenterOverride,
        loadZoomOverride: loadZoomOverride,
      );

  @override
  String toString() =>
      'TileUpdateEvent(mapEvent: $mapEvent, load: $load, prune: $prune, loadCenterOverride: $loadCenterOverride, loadZoomOverride: $loadZoomOverride)';
}

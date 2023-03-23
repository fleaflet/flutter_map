import 'package:flutter_map/src/core/bounds.dart';
import 'package:flutter_map/src/core/point.dart';
import 'package:flutter_map/src/geo/crs/crs.dart';
import 'package:flutter_map/src/geo/latlng_bounds.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_coordinate.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_range.dart';
import 'package:latlong2/latlong.dart';
import 'package:tuple/tuple.dart';

abstract class TileBounds {
  final Crs crs;
  final CustomPoint _tileSize;
  final LatLngBounds? _latLngBounds;

  const TileBounds._(
    this.crs,
    this._tileSize,
    this._latLngBounds,
  );

  factory TileBounds({
    required Crs crs,
    required CustomPoint tileSize,
    required LatLngBounds? latLngBounds,
  }) {
    if (crs.infinite && latLngBounds == null) {
      return InfiniteTileBounds._(crs, tileSize, latLngBounds);
    } else if (crs.wrapLat == null && crs.wrapLng == null) {
      return DiscreteTileBounds._(crs, tileSize, latLngBounds);
    } else {
      return WrappedTileBounds._(crs, tileSize, latLngBounds);
    }
  }

  TileBoundsAtZoom atZoom(int zoom);

  // Returns [true] if these bounds may no longer be valid for the given [crs]
  // and [tileSize].
  bool shouldReplace(
    Crs crs,
    CustomPoint tileSize,
    LatLngBounds? latLngBounds,
  ) =>
      (crs != this.crs ||
          tileSize.x != _tileSize.x ||
          tileSize.y != _tileSize.y ||
          latLngBounds != _latLngBounds);
}

class InfiniteTileBounds extends TileBounds {
  const InfiniteTileBounds._(
    Crs crs,
    CustomPoint tileSize,
    LatLngBounds? latLngBounds,
  ) : super._(crs, tileSize, latLngBounds);

  @override
  TileBoundsAtZoom atZoom(int zoom) => const InfiniteTileBoundsAtZoom._();
}

class DiscreteTileBounds extends TileBounds {
  final Map<int, TileBoundsAtZoom> _tileBoundsAtZoomCache = {};

  DiscreteTileBounds._(
    Crs crs,
    CustomPoint<num> tileSize,
    LatLngBounds? latLngBounds,
  ) : super._(crs, tileSize, latLngBounds);

  @override
  TileBoundsAtZoom atZoom(int zoom) {
    return _tileBoundsAtZoomCache.putIfAbsent(
        zoom, () => _tileBoundsAtZoomImpl(zoom));
  }

  TileBoundsAtZoom _tileBoundsAtZoomImpl(int zoom) {
    final zoomDouble = zoom.toDouble();

    final Bounds<num> pixelBounds;
    if (_latLngBounds == null) {
      pixelBounds = crs.getProjectedBounds(zoomDouble)!;
    } else {
      pixelBounds = Bounds(
        crs.latLngToPoint(_latLngBounds!.southWest, zoomDouble).floor(),
        crs.latLngToPoint(_latLngBounds!.northEast, zoomDouble).ceil(),
      );
    }

    return DiscreteTileBoundsAtZoom._(
      DiscreteTileRange.fromPixelBounds(
        zoom: zoom,
        tileSize: _tileSize,
        pixelBounds: pixelBounds,
      ),
    );
  }
}

class WrappedTileBounds extends TileBounds {
  final Map<int, WrappedTileBoundsAtZoom> _tileBoundsAtZoomCache = {};

  WrappedTileBounds._(
    Crs crs,
    CustomPoint tileSize,
    LatLngBounds? latLngBounds,
  ) : super._(crs, tileSize, latLngBounds);

  @override
  WrappedTileBoundsAtZoom atZoom(int zoom) {
    return _tileBoundsAtZoomCache.putIfAbsent(
        zoom, () => _tileBoundsAtZoomImpl(zoom));
  }

  WrappedTileBoundsAtZoom _tileBoundsAtZoomImpl(int zoom) {
    final zoomDouble = zoom.toDouble();

    final Bounds<num> pixelBounds;
    if (_latLngBounds == null) {
      pixelBounds = crs.getProjectedBounds(zoomDouble)!;
    } else {
      pixelBounds = Bounds(
        crs.latLngToPoint(_latLngBounds!.southWest, zoomDouble).floor(),
        crs.latLngToPoint(_latLngBounds!.northEast, zoomDouble).ceil(),
      );
    }

    final tzDouble = zoom.toDouble();

    Tuple2<int, int>? wrapX;
    if (crs.wrapLng != null) {
      final wrapXMin =
          (crs.latLngToPoint(LatLng(0, crs.wrapLng!.item1), tzDouble).x /
                  _tileSize.x)
              .floor();
      final wrapXMax =
          (crs.latLngToPoint(LatLng(0, crs.wrapLng!.item2), tzDouble).x /
                  _tileSize.y)
              .ceil();
      wrapX = Tuple2(wrapXMin, wrapXMax);
    }

    Tuple2<int, int>? wrapY;
    if (crs.wrapLat != null) {
      final wrapYMin =
          (crs.latLngToPoint(LatLng(crs.wrapLat!.item1, 0), tzDouble).y /
                  _tileSize.x)
              .floor();
      final wrapYMax =
          (crs.latLngToPoint(LatLng(crs.wrapLat!.item2, 0), tzDouble).y /
                  _tileSize.y)
              .ceil();
      wrapY = Tuple2(wrapYMin, wrapYMax);
    }

    return WrappedTileBoundsAtZoom._(
      DiscreteTileRange.fromPixelBounds(
        zoom: zoom,
        tileSize: _tileSize,
        pixelBounds: pixelBounds,
      ),
      wrapX,
      wrapY,
    );
  }
}

abstract class TileBoundsAtZoom {
  const TileBoundsAtZoom._();

  TileCoordinate wrap(TileCoordinate coordinate);

  Iterable<TileCoordinate> validCoordinatesIn(DiscreteTileRange tileRange);
}

class InfiniteTileBoundsAtZoom extends TileBoundsAtZoom {
  const InfiniteTileBoundsAtZoom._() : super._();

  @override
  TileCoordinate wrap(TileCoordinate coordinate) => coordinate;

  @override
  Iterable<TileCoordinate> validCoordinatesIn(DiscreteTileRange tileRange) =>
      tileRange.coordinates;
}

class DiscreteTileBoundsAtZoom extends TileBoundsAtZoom {
  final DiscreteTileRange _tileRange;

  const DiscreteTileBoundsAtZoom._(this._tileRange) : super._();

  @override
  TileCoordinate wrap(TileCoordinate coordinate) {
    assert(coordinate.z == _tileRange.zoom);
    return coordinate;
  }

  @override
  Iterable<TileCoordinate> validCoordinatesIn(DiscreteTileRange tileRange) {
    assert(_tileRange.zoom == tileRange.zoom);
    return _tileRange.intersect(tileRange).coordinates;
  }
}

class WrappedTileBoundsAtZoom extends TileBoundsAtZoom {
  final DiscreteTileRange _discreteTileBoundsAtZoom;
  final Tuple2<int, int>? _wrapX;
  final Tuple2<int, int>? _wrapY;

  const WrappedTileBoundsAtZoom._(
    this._discreteTileBoundsAtZoom,
    this._wrapX,
    this._wrapY,
  ) : super._();

  @override
  TileCoordinate wrap(TileCoordinate coordinate) {
    final newCoords = TileCoordinate(
      _wrapX != null ? _wrapInt(coordinate.x, _wrapX!) : coordinate.x,
      _wrapY != null ? _wrapInt(coordinate.y, _wrapY!) : coordinate.y,
      coordinate.z,
    );
    return newCoords;
  }

  @override
  Iterable<TileCoordinate> validCoordinatesIn(DiscreteTileRange tileRange) =>
      _discreteTileBoundsAtZoom
          .intersect(tileRange)
          .coordinates
          .where(_contains);

  bool _contains(TileCoordinate coordinate) {
    if (_wrapX == null &&
        (coordinate.x <= _discreteTileBoundsAtZoom.min.x ||
            coordinate.x >= _discreteTileBoundsAtZoom.max.x)) {
      return false;
    }

    if (_wrapY == null &&
        (coordinate.y <= _discreteTileBoundsAtZoom.min.y ||
            coordinate.y >= _discreteTileBoundsAtZoom.max.y)) {
      return false;
    }

    return true;
  }

  // TODO check this is valid against old impl in util
  int _wrapInt(int x, Tuple2<int, int> range) {
    final max = range.item2;
    final min = range.item1;
    final d = max - min;
    return ((x - min) % d + d) % d + min;
  }
}

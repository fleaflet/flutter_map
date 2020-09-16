import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

typedef TileBuilder = Widget Function(
    BuildContext context, Widget tileWidget, Tile tile);

typedef TilesContainerBuilder = Widget Function(
    BuildContext context, Widget tilesContainer, List<Tile> tiles);

/// Applies inversion color matrix on Tiles container which may simulate Dark mode.
final TilesContainerBuilder darkModeTilesContainerBuilder =
    (BuildContext context, Widget tilesContainer, List<Tile> tiles) {
  return ColorFiltered(
    colorFilter: const ColorFilter.matrix(<double>[
      -1,
      0,
      0,
      0,
      255,
      0,
      -1,
      0,
      0,
      255,
      0,
      0,
      -1,
      0,
      255,
      0,
      0,
      0,
      1,
      0,
    ]),
    child: tilesContainer,
  );
};

/// Applies inversion color matrix on Tiles which may simulate Dark mode.
/// [darkModeTilesContainerBuilder] is better at performance because it applies color matrix on the container instead of on every Tile
final TileBuilder darkModeTileBuilder =
    (BuildContext context, Widget tileWidget, Tile tile) {
  return ColorFiltered(
    colorFilter: const ColorFilter.matrix(<double>[
      -1,
      0,
      0,
      0,
      255,
      0,
      -1,
      0,
      0,
      255,
      0,
      0,
      -1,
      0,
      255,
      0,
      0,
      0,
      1,
      0,
    ]),
    child: tileWidget,
  );
};

/// Shows coordinates over Tiles
final TileBuilder coordinateDebugTileBuilder =
    (BuildContext context, Widget tileWidget, Tile tile) {
  final coords = tile.coords;
  final readableKey =
      '${coords.x.floor()} : ${coords.y.floor()} : ${coords.z.floor()}';

  return Container(
    decoration: BoxDecoration(
      border: Border.all(),
    ),
    child: Stack(
      fit: StackFit.passthrough,
      children: [
        tileWidget,
        Center(
          child: Text(
            readableKey,
            style: Theme.of(context).textTheme.headline5,
          ),
        ),
      ],
    ),
  );
};

/// Shows the Tile loading time in ms
final TileBuilder loadingTimeDebugTileBuilder =
    (BuildContext context, Widget tileWidget, Tile tile) {
  var loadStarted = tile.loadStarted;
  var loaded = tile.loaded;

  final time = loaded == null
      ? 'Loading'
      : '${(loaded.millisecond - loadStarted.millisecond).abs()} ms';

  return Container(
    decoration: BoxDecoration(
      border: Border.all(),
    ),
    child: Stack(
      fit: StackFit.passthrough,
      children: [
        tileWidget,
        Center(
          child: Text(
            time,
            style: Theme.of(context).textTheme.headline5,
          ),
        ),
      ],
    ),
  );
};

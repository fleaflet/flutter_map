import 'package:flutter/material.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_image.dart';

typedef TileBuilder = Widget Function(
    BuildContext context, Widget tileWidget, TileImage tile);

/// Applies inversion color matrix on Tiles container which may simulate Dark mode.
Widget darkModeTilesContainerBuilder(
  BuildContext context,
  Widget tilesContainer,
) {
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
}

/// Applies inversion color matrix on Tiles which may simulate Dark mode.
/// [darkModeTilesContainerBuilder] is better at performance because it applies color matrix on the container instead of on every Tile
Widget darkModeTileBuilder(
  BuildContext context,
  Widget tileWidget,
  TileImage tile,
) {
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
}

/// Shows coordinates over Tiles
Widget coordinateDebugTileBuilder(
  BuildContext context,
  Widget tileWidget,
  TileImage tile,
) {
  final coords = tile.coordinate;
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
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
      ],
    ),
  );
}

/// Shows the Tile loading time in ms
Widget loadingTimeDebugTileBuilder(
  BuildContext context,
  Widget tileWidget,
  TileImage tile,
) {
  final loadStarted = tile.loadStarted;
  final loaded = tile.loadFinishedAt;

  final time = loaded == null
      ? 'Loading'
      : '${(loaded.millisecond - loadStarted!.millisecond).abs()} ms';

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
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
      ],
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

/// Builder function that returns a [TileBuilder] instance.
typedef TileBuilder = Widget Function(
    BuildContext context, Widget tileWidget, TileImage tile);

/// Applies inversion color matrix on Tiles container which may simulate Dark mode.
Widget darkModeTilesContainerBuilder(
  BuildContext context,
  Widget tilesContainer,
) {
  return ColorFiltered(
    colorFilter: const ColorFilter.matrix(<double>[
      //Colors get Inverted and then Hue Rotated by 180 degrees
      0.5740000009536743, -1.4299999475479126, -0.14399999380111694, 0, 255, //R
      -0.4259999990463257, -0.429999977350235, -0.14399999380111694, 0, 255, //G
      -0.4259999990463257, -1.4299999475479126, 0.8559999465942383, 0, 255, //B
      0, 0, 0, 1, 0, //A
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
      //Colors get Inverted and then Hue Rotated by 180 degrees
      0.5740000009536743, -1.4299999475479126, -0.14399999380111694, 0, 255, //R
      -0.4259999990463257, -0.429999977350235, -0.14399999380111694, 0, 255, //G
      -0.4259999990463257, -1.4299999475479126, 0.8559999465942383, 0, 255, //B
      0, 0, 0, 1, 0, //A
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
  final coordinates = tile.coordinates;
  final readableKey = '${coordinates.x} : ${coordinates.y} : ${coordinates.z}';

  return DecoratedBox(
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

  return DecoratedBox(
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

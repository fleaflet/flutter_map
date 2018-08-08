## [0.0.11] - 8/2/2018
- upgrade to latlong from 0.4.0 to 0.5.3

## [0.0.11] - 7/31/2018
- fix LICENSE spelling error
- double-tap to zoom (#62)
- Fix polyline overlap issue (#67)
- Offline map example (#53)

Thanks to contributors @alfanhui, @avioli, @solid-software, and @vinicentus for
this release!

## [0.0.10] - 6/7/2018
- update .gitignore (#40)
- Applied constraints to zoom on gesture update if min or max options set (#46)
- Pan Boundary with 2 new MapOptions variables: swPanBoundary and nePanBoundary
(#47)
- OfflineMode bool variable added to TileLayerOptions for AssetImage Widget use (#48)
- remove quiver dep (#32)

Thanks to contributors @avioli, @bcko, and @alfanhui for this release!

## [0.0.9] - 5/31/2018
- add LatlngBounds.contains, avoid rendering out-of-view markers in MarkerLayer

## [0.0.8] - 5/31/2018
- bug: rendering far-away tiles was causing a GPU crash on the simulator. add
  tile pruning to TileLayer

## [0.0.7] - 5/29/2018
- bug: TileLayer not listening to onMoved events from MapController

## [0.0.6] - 5/11/2018
- fitBounds, onPositionChanged (#39)

## [0.0.5] - 3/11/2018

- make tile background customizable (#36)
- use transparent_image as placeholder image (#37)

## [0.0.4] - 4/18/2018

- Add marker anchor support (#27, #30)

## [0.0.3] - 4/18/2018

- fixed Dart 2.0 type errors (#23)
- add MapController API (#24 + #25)

## [0.0.2] - 2/21/2018

- subdomain support
- move gesture detection into map widget
- improved tile layer support
- improved examples
- Polyline layers
- fix marker redraw on map rotation

## [0.0.1] - 2/5/2018

- inital release


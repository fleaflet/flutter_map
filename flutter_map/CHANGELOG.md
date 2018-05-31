## [0.0.9] - 3/31/2018
- add LatlngBounds.contains, avoid rendering out-of-view markers in MarkerLayer

## [0.0.8] - 3/31/2018
- bug: rendering far-away tiles was causing a GPU crash on the simulator. add
  tile pruning to TileLayer

## [0.0.7] - 3/11/2018
- bug: TileLayer not listening to onMoved events from MapController

## [0.0.6] - 3/11/2018
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


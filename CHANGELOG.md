## [0.5.4] - 6/7/2019
- fix markers on edge of screen disappearing (#313)
- dart analysis fixes (#300)
- add border circle (#299)
- add dotted line to polygon (#295)
- fix example esri page (#292)
- add flutter_map_marker_cluster package to README (#309)

Note: 0.5.x releases are compatable with Flutter's `stable` channel, currently
v1.5.4-hotfix.2 and 0.6.x releases (also on the `flutter_map` `dev` branch) is a
version of flutter_map compatible with Flutter's `dev` channel

Thanks to @lpongetti @FalkF @Victor-emil @lsaudon and @lorenzo for this release!

## [0.5.3] - 5/21/2019
- update dependencies (#288)

## [0.5.2] - 5/20/2019
- fix zooming issue (#281)

## [0.5.1] - 5/17/2019

- add mbtiles
- add formatting and linter rules
- Fix null pointer in isOutOfBounds (#274)
- add isUserGesture (#237)
- fix emulator pinching error

Thanks to @avbk, @OrKoN, @pintomic, @wmcshane, @manhluong for this release!

## [0.5.0] - 2/21/2019

- add cached network image support (#204)
- Use PositionedTapDetector only in interactive mode (#207)
- Allow defining CircleMarkerRadius in meters (#213)
- support for tms tile coordinates (#214)
- add moving markers example
- add long press gesture for markers (#229)
- add patreon badge to README
- rename Point to CustomPoint (#187)
- remove layers property from MapOptions (#193)

Thanks to @SamuelRioTz, @jecoz, @4kssoft, @bugWebDeveloper, @RaimundWege,
@vinicentus, and @etzuk for this release!

## [0.4.0] - 12/31/2018
- Zoom to focal point on double tap and scale gestures (#121)
- Make anchor field public (#172)
- FitBoundsOptions now uses EdgeInsets padding
- Add GroupLayer
- Update README

Thanks to @tomwyr, @csjames, @kengu, @ocularrhythm for this release!

## [0.3.0] - 11/1/2018
- PositionCallback now has hasGesture #139

Thanks to @gimox for this release!

## [0.2.0] - 10/25/2018
- Use NetworkImageWithRetry for tile layers (#145)
- Add rebuild capability to LayerOptions (#144)
- Added Circle layer (#137)
- Prevent Map Layer Excessive Rebuilds (#131)

Thanks to @kengu, @mortenboye, and @tomwyr for this release!

## [0.1.4] - 9/24/2018
- Polygon Support (#118)

Thanks to @JulianBerger for this release!

## [0.1.3] - 9/18/2018
- fix identical map position callbacks (#111)
- Prune tiles bug fix (#112)

Thanks to @IhorKlimov and @tomwyr for this release!

## [0.1.2] - 8/21/2018
- Added polyline customisation options (#94)
- Expose map bounds (#99)
- Added onTap example (#103)
- route bugfix (#104)
- options is now required (#105)
- Project refactor and changes to offline map #85

Thanks to @LJaraCastillo, @ubilabs, @xqwzts, @vinicentus, and @lsaudon for this
release!

## [0.1.0] - 8/21/2018
- Set Dart SDK to 2

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
- OfflineMode bool variable added to TileLayerOptions for AssetImage Widget use
(#48)
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


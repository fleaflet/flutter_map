## [0.12.0] - 3/16/2021
TileLayerOptions now takes some additional options, templateFunction,
tileBuilder, tilesContainerBuilder, and evictErrorTileStrategy

- Evict error tiles (#577)
- Post process tiles (#582)
- Prevent crash when move() is called before FlutterMap has been built (#827)

Thanks to gr4yscale, maRci002, MooNag, tlserver, 6y

## [0.11.0] - 01/29/2021
This version removes various tile providers that depend on plugins.
This helps simplify the flutter_map release process. Tile providers can
be implemented in your app or in a separate package.

- remove mbtiles tile provider + sqlflite dependency (#787)
- Add two finger rotation (#719)
- add allowPanning property (#766)
- reload map if additionalOptions changes (#740)

thanks to maRci002, escamoteur, and Xennis for this release!

## [0.10.2] - 10/29/2020
- added property `allowPanning` to `MapOptions` that allows to disable only panning while touch events are still triggered

## [0.10.1+1] - 8/4/2020
- fix possible issue with code published in previous version

## [0.10.1] - 8/4/2020
- Controller position stream (#505)
- Fix gray tiles when tile image is already available (#715)
- Key management (#695)
- migrate to androidx (#697)

Thanks to @maRci002, @4F2E4A2E, and @porfirioribeiro

## [0.10.0] - 7/7/2020
- add package:meta dependency, set cached_network_image to 2.0.0
- Support retina mode (#585)
- Handle exception on move without internet connection (#600)
- Fix TileLayer/Tiles not getting disposed correctly (#595)
- Polyline culling (#611) 
- Remove mapbox from README (#651)
- docs update (#655)
- Fix #595 TileLayer not getting disposed correctly (#596)
- Support subdomains on wms layer (#516)
- Slide map along map boundaries (#430)
- Add example of showing current location (#447)
- Adding an explanation when a plugin has not been activated (#477)
- Add icons & color params for zoombuttons (#544)
- Fix Bug 545 stacked MBTileImageProvider (#546)
- fix #608 Empty map fails when return to same route (#609)
- fix Flickering bug - on double click / MapController move (#579)
- fix/group-layer-rebuid: consuming rebuild stream in group layer (#663)
- Fix #446: Polyline rendering on web (#662)
- Initialize map widgets with bounds or center (#646)
- Add flutter_map_marker_popup to plugins in README.md (#603)
- add lat lon grid plugin to readme (#601)
- Handle exception on move without internet connection (#600)
- Fix "plugins.flutter.io/path_provider" deprecation (#598)
- Fix #595 TileLayer not getting disposed correctly (#596)
- New Widget layers API (#619)

Thanks to @maRci002, @beerline, @saibotma, @kuhnroyal, @porfirioribeiro, @Lootwig,
@raacker, @wpietri, @HugoHeneault, @felixjunghans, @hlin079g6, @eugenio165,
@fusion44, @rorystephenson, @mat8854, @dpatrongomez, @ruizalexandre 

## [0.9.0] - 4/6/2020
- Improve tile management (#572) - This is a huge improvement aligns
  tile rendering with Leaflet's behavior. 
- Wms Support (#500)
- Update README for open street maps (#495)
- Support custom CRS (#529)
- Proj4dart update (#541)
- Fix changelog (#511)
- Fix multiple origins bouncing (#548)
- Add android permissions instructions to README (#569)
- Add an option for gapless playback on OverlayImage (#566)
- Add flutter_map_tappable_polyline plugin to README (#563)
- Move plugins to front of checks so they can override defaults (#555)
- Support holed polygons (#526)

**Big** thanks to @maRci002 for this release! See pull request #572 for details.

Thanks to @marCi002, @bugDim88, @buggamer, @pumano, @fegyi001, @jpeiffer,
@syonip, @pento, @tuarrep, and @ibrierley for this release!

## [0.8.2] - 1/7/2020
- Add polyline with gradient (#452)

Thanks to @SebWojd for this release!

## [0.8.1] - 1/3/2020
- Add ZoomButtonsPlugin (#487)

Thanks to @moovida for this release!

## [0.8.0] - 12/16/2019
Added Flutter 1.12 support

- Polygon Culling (#449)
- fix marker anchor sample (#448, #427)
- upgrade imageloader for Flutter 1.12 (#478)
- Tidying up project files (#469)

Thanks to @raacker, @Varuni-Punchihewa, @wmcshane, @domesticmouse, and @kimlet
for this release!

## [0.7.3] - 10/3/2019
- Update changelog (#408)
- Readability improvements (#410)
- add double-tap-hold zoom (#393)
- Fix Unsupported Operation and add missing onTap and onLongPress methods (#436)
- Fix error when unproject bottomLeft or topRight and lat are < -90 or > 90 or
  lng are < -180 or > 180
- Fix/transparent polyline (#407)

Thanks to @yywwuing, @GregorySech, @avimak, @kengu, @lpongetti, and @2ZeroSix
for this release!

## [0.7.2] - 8/30/2019
- expose TileProvider.getTileUrl (#401)

Thanks to @kengu for this release!
## [0.7.1] - 8/28/2019
- upgrade to cached_network_image ^1.1.0 (#358)
- documentation (#400)
- remove isUserGesture (#389)
- fix initialization exception (#379)

Thanks to @escamoteur, @wmcschane, and @GregorySech for this release!

## [0.7.0+2] - 7/31/2019
- Fix OverlayImage with transparency (#382)

Thanks to @4kssoft for this release!

## [0.7.0+1] - 7/30/2019
- update MapState options when FlutterMap widget options change (#380)

## [0.7.0] - 7/27/2019
- compatability with flutter's stable and master channels
- add scalebar (#356)
- add rotation (#359)
- fix OverlayLayer bug (#360)
- fix rotation pan issue (#363, #365)

Thanks to @kimlet, @escamoteur, @4kssoft for this release! 

## [0.5.6] - 7/9/2019
- fix compatibility with flutter 1.7.8 (stable) (#296)

Thanks to @MichalMisiaszek for the heads up and @slightfoot for help with
upgrading (#296)!

## [0.6.x] - 6/7/2019
- temporary releases compatable with early flutter releases

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


# Changelog

## [5.0.0] - 2023/XX/XX

**Dart The Third**

Contains the following changes (may not be a comprehensive list):

- Migrated to Flutter 3.10 and Dart 3.0 minimums - [#1512](https://github.com/fleaflet/flutter_map/pull/1512) & [#1517](https://github.com/fleaflet/flutter_map/pull/1517)
- Improved tile providers and tile image providers - [#1512](https://github.com/fleaflet/flutter_map/pull/1512)
  - Improved performance and removed unnecessary code
  - Removed `NetworkNoRetryTileProvider` in favour of custom `NetworkTileProvider.httpClient`
  - Removed `FileTileProvider` fallback to `NetworkTileProvider` on web
- Improved performance in environments where `MediaQuery` changes frequently - [#1523](https://github.com/fleaflet/flutter_map/pull/1523)
- Improved/stricter typing of `CustomPoint` - [#1515](https://github.com/fleaflet/flutter_map/pull/1515)
- Updated dependencies - [#1530](https://github.com/fleaflet/flutter_map/pull/1530)
  - Updated 'latlong2' to access `const` `LatLng` objects
  - Updated 'http'
  - Removed 'tuple' ([#1517](https://github.com/fleaflet/flutter_map/pull/1517))
- Deprecated `TileUpdateTransformers.alwaysLoadAndPrune` in favour of `ignoreTapEvents` - [#1517](https://github.com/fleaflet/flutter_map/pull/1517)

Contains the following bug fixes:

- Polylines with translucent fills and borders now paint properly - [#1519](https://github.com/fleaflet/flutter_map/pull/1519) for [#1510](https://github.com/fleaflet/flutter_map/issues/1510) & [#1420](https://github.com/fleaflet/flutter_map/issues/1420)
- Removed potential for jitter/frame delay when painting `Polyline`s & `Polygon`s - [#1514](https://github.com/fleaflet/flutter_map/pull/1514)
- Removed potential for un-`mounted` `setState` call in `RichAttributionWidget` - [#1532](https://github.com/fleaflet/flutter_map/pull/1532)

In other news:

- You may have noticed some minor rebranding around the repo recently! The maintainers have finally gained full member access from the previous owner (thanks John :)) to the 'fleaflet' organisation and now have total control.
- We've launched a Live Web Demo so you can experiment with flutter_map without having to build from source yourself! Visit [demo.fleaflet.dev](https://demo.fleaflet.dev).

Many thanks to these contributors (in no particular order):

- @josxha
- @ignatz
- ... and all the maintainers

And an additional special thanks to @josxha & @ignatz for investing so much of their time into this project recently - we appreciate it!

## [4.0.0] - 2023/05/05

**"Out With The Old, In With The New"**

Contains the following improvements:

- Reimplemented `TileLayer` and underlying systems - [#1475](https://github.com/fleaflet/flutter_map/pull/1475)
- Reimplemented attribution layers - [#1487](https://github.com/fleaflet/flutter_map/pull/1487) & [#1390](https://github.com/fleaflet/flutter_map/pull/1390)
- Added secondary tap handling to `MapOptions` - [#1448](https://github.com/fleaflet/flutter_map/pull/1448) for [#1444](https://github.com/fleaflet/flutter_map/issues/1444)
- Refactored `FlutterMapState`'s `maybeOf` method into `maybeOf` & `of` - [#1495](https://github.com/fleaflet/flutter_map/pull/1495)
- Removed `LatLngBounds.pad` (unused and broken) method - [#1427](https://github.com/fleaflet/flutter_map/pull/1427)
- Removed `absorbPanEventsOnScrollables` option - [#1455](https://github.com/fleaflet/flutter_map/pull/1455) for [#1454](https://github.com/fleaflet/flutter_map/issues/1454)
- Removed leftover deprecations - [#1475](https://github.com/fleaflet/flutter_map/pull/1475)
- Improved rotation gestures (cause rotation about the gesture center) - [#1437](https://github.com/fleaflet/flutter_map/pull/1437)
- Improved number (`num`/`int`/`double`) consistency internally - [#1482](https://github.com/fleaflet/flutter_map/pull/1482)
- Minor example application improvements - [#1440](https://github.com/fleaflet/flutter_map/pull/1440) & [#1487](https://github.com/fleaflet/flutter_map/pull/1487)

Contains the following bug fixes:

- Prevented scrolling of list and simultaneous panning of map on some platforms - [#1453](https://github.com/fleaflet/flutter_map/pull/1453)
- Improved `LatLngBounds`'s null safety situation to improve stability - [#1431](https://github.com/fleaflet/flutter_map/pull/1431)
- Migrated from multiple deprecated APIs - [#1438](https://github.com/fleaflet/flutter_map/pull/1438)

Contains the following performance and stability improvements:

- Batched polygon and polyline rendering to minimize redraws and maximize their efficiency - [#1442](https://github.com/fleaflet/flutter_map/pull/1442) & [#1462](https://github.com/fleaflet/flutter_map/pull/1462)
- Added a threshold for rasterization to avoid excessive fixed overhead cost for cheap redraws - [#1462](https://github.com/fleaflet/flutter_map/pull/1462)

Many thanks to these contributors (in no particular order):

- @rorystephenson
- @augustweinbren
- @ianthetechie
- @pablojimpas
- @tlserver
- @Zzerr0r
- @tobiasht
- @ignatz
- ... and all the maintainers

And an additional special thanks to @rorystephenson & @ignatz for investing so much of their time into this project recently - we appreciate it!

## [3.1.0] - 2022/12/21

Contains the following additions/removals:

- Added fallback URLs - [#1348](https://github.com/fleaflet/flutter_map/pull/1348) for [#1203](https://github.com/fleaflet/flutter_map/issues/1203)
- Added parameter to force integer zoom levels to `FitBoundsOptions` - [#1367](https://github.com/fleaflet/flutter_map/pull/1367)
- Added `Key`s to `Polygon`s, `Polyline`s, and `CircleMarker`s - [#1402](https://github.com/fleaflet/flutter_map/pull/1402) & [#1403](https://github.com/fleaflet/flutter_map/pull/1403)
- Added `Polyline` parameter to treat width in meters - [#1404](https://github.com/fleaflet/flutter_map/pull/1404)
- Added buffer feature to `TileLayer` to preload surrounding tiles - [#1405](https://github.com/fleaflet/flutter_map/pull/1405) for [#1337](https://github.com/fleaflet/flutter_map/issues/1337)
- Deprecated obsolete parameter - [#1368](https://github.com/fleaflet/flutter_map/pull/1368)

Contains the following bug fixes:

- Improved tile handling to simplify internals - [#1356](https://github.com/fleaflet/flutter_map/pull/1356)
- Improved performance by removing unnecessary casts - [#1357](https://github.com/fleaflet/flutter_map/pull/1357)
- Fixed ESPG:3413 example - [#1359](https://github.com/fleaflet/flutter_map/pull/1359)
- Fixed tile layer reset example - [#1372](https://github.com/fleaflet/flutter_map/pull/1372)
- Fixed issue with `MapController` movement - [#1374](https://github.com/fleaflet/flutter_map/pull/1374)
- Fixed flickering issue with `fitBounds` - [#1376](https://github.com/fleaflet/flutter_map/pull/1376)
- Fixed `fitBounds`/`bounds` not working on first display - [#1413](https://github.com/fleaflet/flutter_map/pull/1413)
- Fixed error when zooming - [#1388](https://github.com/fleaflet/flutter_map/pull/1388)

Many thanks to these contributors (in no particular order):

- @JosefWN
- @Robbendebiene
- @urusai88
- @LeonTenorio
- ... and all the maintainers

## [3.0.0] - 2022/09/04

**"Boiler(plate) Repairs"**

Contains the following additions/removals:

- Multiple changes - [#1333](https://github.com/fleaflet/flutter_map/pull/1333)
  - Removed deprecated APIs from v2
  - Removed old layering system
  - Added new layering system
  - Removed old plugin registration system
- Added `Polygon` label rotation (countered to the map rotation) - [#1332](https://github.com/fleaflet/flutter_map/pull/1332)

Contains the following bug fixes:

- Fixed missing widget sizing to fix multiple issues - [#1334](https://github.com/fleaflet/flutter_map/pull/1334)
- Forced CRS changes to rebuild children - [#1322](https://github.com/fleaflet/flutter_map/issues/1322)
- Allowed map to absorb gesture events correctly within other scrollables - [#1308](https://github.com/fleaflet/flutter_map/issues/1308)
- Improved performance by harnessing the full power of Flutter widgets - [#1165](https://github.com/fleaflet/flutter_map/issues/1165), [#958](https://github.com/fleaflet/flutter_map/issues/958)

In other news:

- @MooNag & @TesteurManiak have joined the maintainer team!

Many thanks to these contributors (in no particular order):

- @MooNag
- @jetpeter
- @Firefishy
- ... and all the maintainers

## [2.2.0] - 2022/08/02

Contains the following additions/removals:

- Added `RotatedOverlayImage` which supports image rotation and skewing by specifying a 3rd point - [#1315](https://github.com/fleaflet/flutter_map/pull/1315)
- Added `latLngToScreenPoint` and refactored `pointToLatLng` - [#1330](https://github.com/fleaflet/flutter_map/pull/1330)

Contains the following bug fixes:

- Removed a particularly illusive null-safety bug - [#1323](https://github.com/fleaflet/flutter_map/pull/1323)

In other news:

- Internal lints have been improved - [#1319](https://github.com/fleaflet/flutter_map/pull/1319)
- GitHub Actions have been improved - [#1323](https://github.com/fleaflet/flutter_map/pull/1323)

Many thanks to these contributors (in no particular order):

- @Robbendebiene
- @lsaudon
- ... and all the maintainers

## [2.1.1] - 2022/07/25

Contains the following additions/removals:

- None

Contains the following bug fixes:

- Removed a particularly illusive null-safety bug - [#1318](https://github.com/fleaflet/flutter_map/pull/1318)

In other news:

- None

Many thanks to these contributors (in no particular order):

- sergioisair (tested changes over on Discord)
- ... and all the maintainers

## [2.1.0] - 2022/07/22

Contains the following additions/removals:

- Added built in keep alive functionality - [#1312](https://github.com/fleaflet/flutter_map/pull/1312)
- Added disposal of `AnimationController` before it is reassigned - [#1303](https://github.com/fleaflet/flutter_map/pull/1303)
- Added better polar projection support and example - [#1295](https://github.com/fleaflet/flutter_map/pull/1295)
- Added stroke cap and stroke join options to `Polygon`s - [#1295](https://github.com/fleaflet/flutter_map/pull/1295)

Contains the following bug fixes:

- Removed a class of `LateInitializationError`s by reworking `MapController` lifecycle - [#1293](https://github.com/fleaflet/flutter_map/pull/1293) for [#1288](https://github.com/fleaflet/flutter_map/issues/1288)
- Improved performance during painting `Polygon`s - [#1295](https://github.com/fleaflet/flutter_map/pull/1295)

In other news:

- None

Many thanks to these contributors (in no particular order):

- @Zverik
- @rbellens
- @JosefWN
- ... and all the maintainers

## [2.0.0] - 2022/07/11

**"~~Blocked By OSM~~"**

Contains the following additions/removals:

- Added adjustable mouse wheel zoom speed - [#1289](https://github.com/fleaflet/flutter_map/pull/1289)
- Multiple changes - [#1294](https://github.com/fleaflet/flutter_map/pull/1294)
  - Added advanced header support, including 'User-Agent'
  - Refactored `TileProvider`s
  - Resolved multiple TODOs within codebase
  - Removed old deprecated code

Contains the following bug fixes:

- Fixed unsymmetrical markers disappearing with unusually positioned anchors - [#1291](https://github.com/fleaflet/flutter_map/pull/1291)
- Fixed potential for error 403s due to invalid/blocked 'User-Agent' header - [#1294](https://github.com/fleaflet/flutter_map/pull/1294)

In other news:

- None

Many thanks to these contributors (in no particular order):

- @mboe
- @aytunch
- @MichalTorma
- ... and all the maintainers

## [1.1.1] - 2022/06/25

Contains the following additions/removals:

- None

Contains the following bug fixes:

- None

In other news:

- The new documentation website is now live at <https://docs.fleaflet.dev>. Visit it today to get much improved setup and usage instructions, and more!

Many thanks to these contributors (in no particular order):

- All the documentation authors: <https://docs.fleaflet.dev/credits>
- ... and all the maintainers

## [1.1.0] - 2022/06/16

Contains the following additions/removals:

- Deprecated the existing `attributionBuilder` & added a new method of attribution through `AttributionWidget` - [#1262](https://github.com/fleaflet/flutter_map/pull/1262) for [#1040](https://github.com/fleaflet/flutter_map/issues/1040)
- Added more callbacks for pointer gestures - [#1275](https://github.com/fleaflet/flutter_map/pull/1275)

Contains the following bug fixes:

- Fixed double click zoom gesture zooming to incorrect location - [#1271](https://github.com/fleaflet/flutter_map/pull/1271) for [#1265](https://github.com/fleaflet/flutter_map/issues/1265)

In other news:

- None

Many thanks to these contributors (in no particular order):

- @pmjobin
- ... and all the maintainers

## [1.0.0] - 2022/06/07

Contains the following additions/removals:

- Removed inappropriate null-aware checking from `moveAndRotate` - [#1003](https://github.com/fleaflet/flutter_map/pull/1003)
- Removed unused dependencies from pubspec - [#1237](https://github.com/fleaflet/flutter_map/pull/1237)
- Migrated to 'flutter_lints' from 'pedantic' - [#1183](https://github.com/fleaflet/flutter_map/pull/1183)
- Made boolean values uppercase strings in WMS requests - [#1132](https://github.com/fleaflet/flutter_map/pull/1132)
- Made pinch zoom use center of gesture for focus of zoom - [#1081](https://github.com/fleaflet/flutter_map/pull/1081)
- Made scroll zoom use center of gesture for focus of zoom - [#1191](https://github.com/fleaflet/flutter_map/pull/1191)
- Added stroke, cap, and join options to `Polyline` - [#1077](https://github.com/fleaflet/flutter_map/pull/1077)
- Added option to use pixel cache and length check on `Markers` to avoid crash - [#1147](https://github.com/fleaflet/flutter_map/pull/1147)
- Added `MapEventScrollWheelZoom` event when zooming using scroll wheel - [#1182](https://github.com/fleaflet/flutter_map/pull/1182)
- Added `isFilled` parameter to `Polygon` - [#501](https://github.com/fleaflet/flutter_map/pull/501)
- Added example page for `Polygon`s - [#501](https://github.com/fleaflet/flutter_map/pull/501)
- Added `maxBounds` parameter to `MapOptions` - [#1211](https://github.com/fleaflet/flutter_map/pull/1211)
- Added `tileBounds` parameter to `TileLayerOptions` - [#1212](https://github.com/fleaflet/flutter_map/pull/1212)
- Added `saveLayers` parameter to `PolylineLayerOptions` and `PolylinePainter` - [#1219](https://github.com/fleaflet/flutter_map/pull/1219) (part of [#1165](https://github.com/fleaflet/flutter_map/issues/1165)) for [#1217](https://github.com/fleaflet/flutter_map/issues/1217)
- Added centered labels to `Polygon` - [#1220](https://github.com/fleaflet/flutter_map/pull/1220) based off [#800](https://github.com/fleaflet/flutter_map/pull/800)
- Added alternative `Polygon` label centering algorithm with an option - [#1225](https://github.com/fleaflet/flutter_map/pull/1225)
- Added `pointToLatLng` method in `MapController` - [#1115](https://github.com/fleaflet/flutter_map/pull/1115) for [#496](https://github.com/fleaflet/flutter_map/issues/496), [#607](https://github.com/fleaflet/flutter_map/issues/607), [#981](https://github.com/fleaflet/flutter_map/issues/981), [#1010](https://github.com/fleaflet/flutter_map/issues/1010)
- Added stricter linting rules - [#1238](https://github.com/fleaflet/flutter_map/pull/1238)
- Switched to semantic versioning (from 0.15.0 to 1.0.0)
- Multiple plugin list changes
- Multiple README changes

Contains the following bug fixes:

- Fixed unusual behaviour by cancelling animations on `MapController` move events - [#1043](https://github.com/fleaflet/flutter_map/pull/1043) for [#946](https://github.com/fleaflet/flutter_map/issues/946)
- Fixed `ZoomButtonsPluginOption` by checking minimum and maximum zoom properly - [#1120](https://github.com/fleaflet/flutter_map/pull/1120)
- Fixed external bug by updating dependency on 'positioned_tap_detector_2' - [#1047](https://github.com/fleaflet/flutter_map/pull/1047)
- Fixed equal operator types for `Coords` - [#1113](https://github.com/fleaflet/flutter_map/pull/1113)
- Fixed `LateInitializationError` when using `polylineCulling` - [#1110](https://github.com/fleaflet/flutter_map/pull/1110) for [#1119](https://github.com/fleaflet/flutter_map/issues/1119), [#1037](https://github.com/fleaflet/flutter_map/issues/1037), [#974](https://github.com/fleaflet/flutter_map/issues/974), [#931](https://github.com/fleaflet/flutter_map/issues/931)
- Fixed `FileTileProvider` on the web - [#1170](https://github.com/fleaflet/flutter_map/pull/1170)
- Fixed `Polygon` dotted border drawing - [#501](https://github.com/fleaflet/flutter_map/pull/501)
- Fixed example application on Android - [#1213](https://github.com/fleaflet/flutter_map/pull/1213)
- Fixed hairline cracks and flickering - [#1169](https://github.com/fleaflet/flutter_map/pull/1169)
- Fixed EPSG4326 parameter - [#1135](https://github.com/fleaflet/flutter_map/pull/1135)
- Fixed initial `bounds` in `MapOptions` - [#1216](https://github.com/fleaflet/flutter_map/pull/1216)
- Fixed emission of move event when source is custom - [#1232](https://github.com/fleaflet/flutter_map/pull/1232) for [#1231](https://github.com/fleaflet/flutter_map/issues/1231)
- Fixed tile layer lag during flings/animations - [#1247](https://github.com/fleaflet/flutter_map/pull/1247) (part of [#1165](https://github.com/fleaflet/flutter_map/issues/1165)) for [#1245](https://github.com/fleaflet/flutter_map/issues/1245)
- Fixed/added Flutter 3 compatibility - [#1236](https://github.com/fleaflet/flutter_map/pull/1236) for [#1234](https://github.com/fleaflet/flutter_map/issues/1234)

In other news:

- Two more maintainers joined the team (@ibrierley & @JaffaKetchup)
- A public Discord server was created - join via the README link
- A new documentation website was started - take a peek via the README link

Many thanks to these contributors (in no particular order):

- @JonIsAmazingYa
- @Robbendebiene
- @paolorotolo
- @comatory
- @chriscant
- @calmh
- @FaFre
- @jithware
- @stou
- @Zzerr0r
- @mo-ah-dawood
- @a14n
- @pmjobin
- @BaptistePires
- @Zverik
- @yeleibo
- @TesteurManiak
- @sikandersaleem
- @teuaguiar01
- @beroso
- @hschendel
- @pablojimpas
- @HugoHeneault
- @rorystephenson
- ... and all the maintainers

---

## [0.14.0] - 6/7/2021

This version contains the following changes

- Added scroll wheel zoom support for web
- Added TapPosition to TapCallback
- Added center to LatLngBounds
- Added equality operators for LatLngBounds and MapPosition
- Added support for resetting TileLayer cache
- Added attribution builder to TileLayer
- Added 'inside' parameter to FitBoundsOptions
- Added centerZoomFitBounds to MapController
- Added vector_map_tiles to plugin section in README
- Added option to prevent Scrollable widgets from snatching horizontal scrolling gestures

Thanks to moehme, Tom Prebble, Binabh, ondbyte, Sébastien Dabet, Thomas Lüder, Kevin Thorne, kimlet, TheOneWithTheBraid, David Green and Kenneth Gulbrandsøy.

## [0.13.1] - 6/7/2021

This version contains hotfixes from null safety migration.

## [0.13.0] - 6/4/2021

This version has support for sound null safety. For this purpose, some inactive
packages were exchanged with active forks.

- Sound null safety migration (#851, #870)
  - requires flutter version 2.0.0 or higher
  - latlong is replaced with latlong2
  - ready-flag on map has been removed
- Remove the package flutter_image and add http instead (#894)
  - http has to be version 0.13.2 or higher for this package (#894)
- Removed deprecated properties
  - debug property has been removed
  - interactive has been replaced by interactiveFlags
- Bounds getCenter has been replaced by center getter

Thanks to escamoteur, ThexXTURBOXx, Sata51, tazik561, kengu, passsy,
Ahmed-gubara, johnpryan, josxha and andreandersson for this release!

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

- added property `allowPanning` to `MapOptions` that allows to disable only
  panning while touch events are still triggered

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

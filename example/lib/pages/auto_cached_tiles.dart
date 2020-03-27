import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';
import 'package:tuple/tuple.dart';

import '../widgets/drawer.dart';

class AutoCachedTilesPage extends StatelessWidget {
  static const String route = '/auto_cached_tiles';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('AutoCachedTiles Map')),
        drawer: buildDrawer(context, route),
        body: _AutoCachedTilesPageContent());
  }
}

class _AutoCachedTilesPageContent extends StatefulWidget {
  @override
  _AutoCachedTilesPageContentState createState() =>
      _AutoCachedTilesPageContentState();
}

class _AutoCachedTilesPageContentState
    extends State<_AutoCachedTilesPageContent> {
  final northController = TextEditingController();
  final eastController = TextEditingController();
  final westController = TextEditingController();
  final southController = TextEditingController();
  final minZoomController = TextEditingController();
  final maxZoomController = TextEditingController();

  final mapController = MapController();

  LatLngBounds _selectedBounds;

  final decimalInputFormatter =
      WhitelistingTextInputFormatter(RegExp(r'^-?\d{0,3}\.?\d{0,6}$'));

  @override
  void initState() {
    super.initState();
    northController.addListener(_handleBoundsInput);
    eastController.addListener(_handleBoundsInput);
    westController.addListener(_handleBoundsInput);
    southController.addListener(_handleBoundsInput);
  }

  @override
  void dispose() {
    northController.dispose();
    eastController.dispose();
    westController.dispose();
    southController.dispose();
    minZoomController.dispose();
    maxZoomController.dispose();
    super.dispose();
  }

  void _handleBoundsInput() {
    final north =
        double.tryParse(northController.text) ?? _selectedBounds?.north;
    final east = double.tryParse(eastController.text) ?? _selectedBounds?.east;
    final west = double.tryParse(westController.text) ?? _selectedBounds?.west;
    final south =
        double.tryParse(southController.text) ?? _selectedBounds?.south;
    if (north == null || east == null || west == null || south == null) {
      return;
    }
    final sw = LatLng(south, west);
    final ne = LatLng(north, east);
    final bounds = LatLngBounds(sw, ne);
    if (!bounds.isValid) return;
    setState(() => _selectedBounds = bounds);
  }

  void _showErrorSnack(String errorMessage) async {
    SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
      Scaffold.of(context).showSnackBar(SnackBar(
        content: Text(errorMessage),
      ));
    });
  }

  void _calculateApproxTileAmount() {
    if (!_checkTileLoadParams()) return;
    final zoomMin = int.tryParse(minZoomController.text);
    final zoomMax = int.tryParse(maxZoomController.text) ?? zoomMin;
    final approximateTileCount =
        StorageCachingTileProvider.approximateTileAmount(
            bounds: _selectedBounds, minZoom: zoomMin, maxZoom: zoomMax);
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              title: Text('Aproximate tile amount'),
              content: Text(
                '~ $approximateTileCount',
                style: Theme.of(ctx).textTheme.headline4,
              ),
              actions: <Widget>[
                FlatButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text('Ok'),
                )
              ],
            ));
  }

  void _changeSettings() async {
    final currentMaxTileAmount =
        await TileStorageCachingManager.maxCachedTilesAmount;
    final result = await showDialog<int>(
        context: context,
        builder: (ctx) {
          final tileAmountController = TextEditingController();
          tileAmountController.text = currentMaxTileAmount.toString();
          return AlertDialog(
            title: Text('Change max caching tile amount'),
            actions: <Widget>[
              FlatButton(
                child: Text('Cancel'),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
              FlatButton(
                child: Text('Ok'),
                onPressed: () => Navigator.of(ctx)
                    .pop(int.tryParse(tileAmountController.text ?? '')),
              )
            ],
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text('max cach tile amount: '),
                SizedBox(
                  width: 8,
                ),
                Expanded(
                  // width: width / 3,
                  child: TextField(
                    inputFormatters: [
                      WhitelistingTextInputFormatter.digitsOnly
                    ],
                    keyboardType: TextInputType.number,
                    controller: tileAmountController,
                  ),
                )
              ],
            ),
          );
        });
    if (result == null || result == currentMaxTileAmount) return;
    await TileStorageCachingManager.changeMaxTileCount(result);
  }

  bool _checkTileLoadParams() {
    final zoomMin = int.tryParse(minZoomController.text);
    final zoomMax = int.tryParse(maxZoomController.text) ?? zoomMin;
    if (zoomMin == null) {
      _showErrorSnack('At least zoomMin must be defined!');
      return false;
    }
    if (zoomMin < 0 || zoomMin > 19) {
      _showErrorSnack('valid zoom value must be inside 1..19 range');
      return false;
    }
    if (zoomMax < zoomMin) {
      _showErrorSnack('Max zoom must be bigger than min zoom');
      return false;
    }
    if (_selectedBounds == null) {
      _showErrorSnack('bounds of caching area are not defined');
      return false;
    }
    return true;
  }

  Future<void> _loadMap(
      StorageCachingTileProvider tileProvider, TileLayerOptions options) async {
    _hideKeyboard();
    if (!_checkTileLoadParams()) return;
    final zoomMin = int.tryParse(minZoomController.text);
    final zoomMax = int.tryParse(maxZoomController.text) ?? zoomMin;
    final approximateTileCount =
        StorageCachingTileProvider.approximateTileAmount(
            bounds: _selectedBounds, minZoom: zoomMin, maxZoom: zoomMax);
    final maxTilesAmount = await TileStorageCachingManager.maxCachedTilesAmount;
    if (approximateTileCount > maxTilesAmount) {
      _showErrorSnack(
          'tiles ammount $approximateTileCount bigger than current maximum $maxTilesAmount');
      return;
    }
    await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
                title: Text('Tile loading...'),
                content: StreamBuilder<Tuple3<int, int, int>>(
                  initialData: Tuple3(0, 0, 0),
                  stream: tileProvider.loadTiles(
                      _selectedBounds, zoomMin, zoomMax, options),
                  builder: (ctx, snapshot) {
                    if (snapshot.hasError) {
                      return Text('error: ${snapshot.error.toString()}');
                    }
                    if (snapshot.connectionState == ConnectionState.done) {
                      Navigator.of(ctx).pop();
                    }
                    final tileIndex = snapshot.data?.item1 ?? 0;
                    final tilesAmount = snapshot.data?.item3 ?? 0;
                    return getLoadProgresWidget(ctx, tileIndex, tilesAmount);
                  },
                ),
                actions: <Widget>[
                  FlatButton(
                    child: Text('Cancel'),
                    onPressed: () => Navigator.of(ctx).pop(),
                  )
                ]));
  }

  Future<void> _deleteCachedMap() async {
    _hideKeyboard();
    final currentCacheSize =
        await TileStorageCachingManager.cacheDbSize / 1024 / 1024;
    final currentCacheAmount =
        await TileStorageCachingManager.cachedTilesAmount;
    final result = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
              title: Text('Cache cleaning'),
              content: Text(
                  'Cache db size: ${currentCacheSize.toStringAsFixed(2)} mb.'
                  '\nCached tiles amount: $currentCacheAmount'
                  '\nSeriosly want to delete this stuf?'),
              actions: <Widget>[
                FlatButton(
                  child: Text('Cancel'),
                  onPressed: () => Navigator.pop(context, false),
                ),
                FlatButton(
                  child: Text('OK'),
                  onPressed: () => Navigator.pop(context, true),
                )
              ],
            ));
    if (result == true) {
      await TileStorageCachingManager.cleanCache();
      _showErrorSnack('cache cleanded ...');
    }
  }

  void _hideKeyboard() => FocusScope.of(context).requestFocus(FocusNode());

  void _focusToBounds() {
    _hideKeyboard();
    mapController.fitBounds(_selectedBounds,
        options: FitBoundsOptions(padding: EdgeInsets.all(32)));
  }

  Widget getBoundsInputWidget(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final boundsSectionWidth = size.width * 0.8;
    final zoomSectionWidth = size.width - boundsSectionWidth;
    final boundsInputSize = boundsSectionWidth / 2 - 4 * 16;
    final zoomInputWidth = zoomSectionWidth - 32;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: <Widget>[
          //BOUNDS
          Expanded(
            child: Container(
              padding: EdgeInsets.only(left: 8, right: 8, bottom: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey, width: 2),
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text('BOUNDS', style: Theme.of(context).textTheme.subtitle1),
                  SizedBox(
                    width: boundsInputSize,
                    child: TextField(
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(hintText: 'north'),
                      inputFormatters: [decimalInputFormatter],
                      keyboardType:
                          TextInputType.numberWithOptions(decimal: true),
                      controller: northController,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        SizedBox(
                          width: boundsInputSize,
                          child: TextField(
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(hintText: 'west'),
                            inputFormatters: [decimalInputFormatter],
                            keyboardType:
                                TextInputType.numberWithOptions(decimal: true),
                            controller: westController,
                          ),
                        ),
                        SizedBox(
                          width: boundsInputSize,
                          child: TextField(
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(hintText: 'east'),
                            inputFormatters: [decimalInputFormatter],
                            keyboardType:
                                TextInputType.numberWithOptions(decimal: true),
                            controller: eastController,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: boundsInputSize,
                    child: TextField(
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(hintText: 'south'),
                      inputFormatters: [decimalInputFormatter],
                      keyboardType:
                          TextInputType.numberWithOptions(decimal: true),
                      controller: southController,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            width: 16,
          ),
          //ZOOM
          Container(
            padding: EdgeInsets.only(left: 8, right: 8, bottom: 8),
            decoration: BoxDecoration(
                border: Border.all(color: Colors.grey, width: 2),
                borderRadius: BorderRadius.all(Radius.circular(10))),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text('ZOOM', style: Theme.of(context).textTheme.subtitle1),
                SizedBox(
                  width: zoomInputWidth,
                  child: TextField(
                    textAlign: TextAlign.center,
                    maxLength: 2,
                    decoration:
                        InputDecoration(counterText: '', hintText: 'min'),
                    inputFormatters: [
                      WhitelistingTextInputFormatter.digitsOnly
                    ],
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: false),
                    controller: minZoomController,
                  ),
                ),
                SizedBox(
                  width: zoomInputWidth,
                  child: TextField(
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: 'max',
                    ),
                    maxLength: 2,
                    inputFormatters: [
                      WhitelistingTextInputFormatter.digitsOnly
                    ],
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: false),
                    controller: maxZoomController,
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget getLoadProgresWidget(
      BuildContext context, int tileIndex, int tileAmount) {
    if (tileAmount == 0) {
      tileAmount = 1;
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox(
          width: 50,
          height: 50,
          child: Stack(
            children: <Widget>[
              SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(
                  backgroundColor: Colors.grey,
                  value: tileIndex / tileAmount,
                ),
              ),
              Align(
                alignment: Alignment.center,
                child: Text(
                  (tileIndex / tileAmount * 100).toInt().toString(),
                  style: Theme.of(context).textTheme.subtitle1,
                ),
              )
            ],
          ),
        ),
        SizedBox(
          height: 8,
        ),
        Text('$tileIndex/$tileAmount',
            style: Theme.of(context).textTheme.subtitle2)
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final tileProvider = StorageCachingTileProvider();
    final tileLayerOptions = TileLayerOptions(
      tileProvider: tileProvider,
      urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
      subdomains: ['a', 'b', 'c'],
    );
    return Column(
      children: [
        Expanded(
          child: FlutterMap(
            mapController: mapController,
            options: MapOptions(
              center: LatLng(55.753215, 37.622504),
              maxZoom: 18.0,
              zoom: 13.0,
            ),
            layers: [
              tileLayerOptions,
              PolygonLayerOptions(
                  polygons: _selectedBounds == null
                      ? []
                      : [
                          Polygon(
                              color: Colors.red.withAlpha(128),
                              borderColor: Colors.red,
                              borderStrokeWidth: 3,
                              points: [
                                _selectedBounds.southWest,
                                _selectedBounds.southEast,
                                _selectedBounds.northEast,
                                _selectedBounds.northWest
                              ])
                        ]),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
          child: Text('define area borders and zoom edges for tile caching'),
        ),
        getBoundsInputWidget(context),
        Container(
            height: 56,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                IconButton(
                  icon: Icon(Icons.settings),
                  onPressed: _changeSettings,
                ),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: _deleteCachedMap,
                ),
                IconButton(
                  icon: Icon(Icons.cloud_download),
                  onPressed: () => _loadMap(tileProvider, tileLayerOptions),
                ),
                IconButton(
                  icon: Icon(Icons.straighten),
                  onPressed: _calculateApproxTileAmount,
                ),
                IconButton(
                  icon: Icon(Icons.filter_center_focus),
                  onPressed: _selectedBounds == null ? null : _focusToBounds,
                )
              ],
            ))
      ],
    );
  }
}

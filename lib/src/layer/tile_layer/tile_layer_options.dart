part of 'tile_layer.dart';

typedef TemplateFunction = String Function(
    String str, Map<String, String> data);

enum EvictErrorTileStrategy {
  // never evict error Tiles
  none,
  // evict error Tiles during _pruneTiles / _abortLoading calls
  dispose,
  // evict error Tiles which are not visible anymore but respect margin (see keepBuffer option)
  // (Tile's zoom level not equals current _tileZoom or Tile is out of viewport)
  notVisibleRespectMargin,
  // evict error Tiles which are not visible anymore
  // (Tile's zoom level not equals current _tileZoom or Tile is out of viewport)
  notVisible,
}

typedef ErrorTileCallBack = void Function(Tile tile, dynamic error);

/// Describes the needed properties to create a tile-based layer. A tile is an
/// image bound to a specific geographical position.
///
/// You should read up about the options by exploring each one, or visiting
/// https://docs.fleaflet.dev/usage/layers/tile-layer. Some are important to
/// avoid issues.
class TileLayerOptions extends LayerOptions {
  /// Defines the structure to create the URLs for the tiles. `{s}` means one of
  /// the available subdomains (can be omitted) `{z}` zoom level `{x}` and `{y}`
  /// — tile coordinates `{r}` can be used to add "&commat;2x" to the URL to
  /// load retina tiles (can be omitted)
  ///
  /// Example:
  ///
  /// https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png
  ///
  /// Is translated to this:
  ///
  /// https://a.tile.openstreetmap.org/12/2177/1259.png
  final String? urlTemplate;

  /// If `true`, inverses Y axis numbering for tiles (turn this on for
  /// [TMS](https://en.wikipedia.org/wiki/Tile_Map_Service) services).
  final bool tms;

  /// If not `null`, then tiles will pull's WMS protocol requests
  final WMSTileLayerOptions? wmsOptions;

  /// Size for the tile.
  /// Default is 256
  final double tileSize;

  // The minimum zoom level down to which this layer will be
  // displayed (inclusive).
  final double minZoom;

  /// The maximum zoom level up to which this layer will be displayed
  /// (inclusive). In most tile providers goes from 0 to 19.
  final double maxZoom;

  /// Minimum zoom number the tile source has available. If it is specified, the
  /// tiles on all zoom levels lower than minNativeZoom will be loaded from
  /// minNativeZoom level and auto-scaled.
  final double? minNativeZoom;

  /// Maximum zoom number the tile source has available. If it is specified, the
  /// tiles on all zoom levels higher than maxNativeZoom will be loaded from
  /// maxNativeZoom level and auto-scaled.
  final double? maxNativeZoom;

  /// If set to true, the zoom number used in tile URLs will be reversed
  /// (`maxZoom - zoom` instead of `zoom`)
  final bool zoomReverse;

  /// The zoom number used in tile URLs will be offset with this value.
  final double zoomOffset;

  /// List of subdomains for the URL.
  ///
  /// Example:
  ///
  /// Subdomains = {a,b,c}
  ///
  /// and the URL is as follows:
  ///
  /// https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png
  ///
  /// then:
  ///
  /// https://a.tile.openstreetmap.org/{z}/{x}/{y}.png
  /// https://b.tile.openstreetmap.org/{z}/{x}/{y}.png
  /// https://c.tile.openstreetmap.org/{z}/{x}/{y}.png
  final List<String> subdomains;

  /// Color shown behind the tiles
  final Color backgroundColor;

  /// Opacity of the rendered tile
  final double opacity;

  /// Provider with which to load map tiles
  ///
  /// The default is [NetworkNoRetryTileProvider]. Alternatively, use
  /// [NetworkTileProvider] for a network provider which will retry requests.
  ///
  /// Both network providers will use some form of caching, although not reliable. For
  /// better options, see https://docs.fleaflet.dev/usage/layers/tile-layer#caching.
  ///
  /// `userAgentPackageName` is a construction parameter, which should be passed
  /// the application's correct package name, such as 'com.example.app'. If no
  /// value is passed, it defaults to 'unknown'. This parameter is used to form
  /// part of the 'User-Agent' header, which is important to avoid blocking by
  /// tile servers. Namely, the header is the following 'flutter_map (<packageName>)'.
  ///
  /// Header rules are as follows, after 'User-Agent' is generated as above:
  ///
  /// * If no provider is specified here, the default will be used with
  /// 'User-Agent' header injected (recommended)
  /// * If a provider is specified here with no 'User-Agent' header, that
  /// provider will be used and the 'User-Agent' header will be injected
  /// * If a provider is specified here with a 'User-Agent' header, that
  /// provider will be used and the 'User-Agent' header will not be changed to any created here
  ///
  /// [AssetTileProvider] and [FileTileProvider] are alternatives to network
  /// providers, which use the [urlTemplate] as a path instead.
  /// For example, 'assets/map/{z}/{x}/{y}.png' or
  /// '/storage/emulated/0/map_app/tiles/{z}/{x}/{y}.png'.
  ///
  /// Custom [TileProvider]s can also be used, but these will not follow the header
  /// rules above.
  late final TileProvider tileProvider;

  /// When panning the map, keep this many rows and columns of tiles before
  /// unloading them.
  final int keepBuffer;

  /// Tile image to show in place of the tile that failed to load.
  final ImageProvider? errorImage;

  /// Static information that should replace placeholders in the [urlTemplate].
  /// Applying API keys is a good example on how to use this parameter.
  ///
  /// Example:
  ///
  /// ```dart
  ///
  /// TileLayerOptions(
  ///     urlTemplate: "https://api.tiles.mapbox.com/v4/"
  ///                  "{id}/{z}/{x}/{y}{r}.png?access_token={accessToken}",
  ///     additionalOptions: {
  ///         'accessToken': '<PUT_ACCESS_TOKEN_HERE>',
  ///          'id': 'mapbox.streets',
  ///     },
  /// ),
  /// ```
  final Map<String, String> additionalOptions;

  /// Tiles will not update more than once every `updateInterval` (default 200
  /// milliseconds) when panning. It can be null (but it will calculating for
  /// loading tiles every frame when panning / zooming, flutter is fast) This
  /// can save some fps and even bandwidth (ie. when fast panning / animating
  /// between long distances in short time)
  final Duration? updateInterval;

  /// Tiles fade in duration in milliseconds (default 100). This can be null to
  /// avoid fade in.
  final Duration? tileFadeInDuration;

  /// Opacity start value when Tile starts fade in (0.0 - 1.0) Takes effect if
  /// `tileFadeInDuration` is not null
  final double tileFadeInStart;

  /// Opacity start value when an exists Tile starts fade in with different Url
  /// (0.0 - 1.0) Takes effect when `tileFadeInDuration` is not null and if
  /// `overrideTilesWhenUrlChanges` if true
  final double tileFadeInStartWhenOverride;

  /// `false`: current Tiles will be first dropped and then reload via new url
  /// (default) `true`: current Tiles will be visible until new ones aren't
  /// loaded (new Tiles are loaded independently) @see
  /// https://github.com/johnpryan/flutter_map/issues/583
  final bool overrideTilesWhenUrlChanges;

  /// If `true`, it will request four tiles of half the specified size and a
  /// bigger zoom level in place of one to utilize the high resolution.
  ///
  /// If `true` then MapOptions's `maxZoom` should be `maxZoom - 1` since
  /// retinaMode just simulates retina display by playing with `zoomOffset`. If
  /// geoserver supports retina `@2` tiles then it it advised to use them
  /// instead of simulating it (use {r} in the [urlTemplate])
  ///
  /// It is advised to use retinaMode if display supports it, write code like
  /// this:
  ///
  /// ```dart
  /// TileLayerOptions(
  ///     retinaMode: true && MediaQuery.of(context).devicePixelRatio > 1.0,
  /// ),
  /// ```
  final bool retinaMode;

  /// This callback will be execute if some errors occur when fetching tiles.
  final ErrorTileCallBack? errorTileCallback;

  final TemplateFunction templateFunction;

  /// Function which may Wrap Tile with custom Widget
  /// There are predefined examples in 'tile_builder.dart'
  final TileBuilder? tileBuilder;

  /// Function which may wrap Tiles Container with custom Widget
  /// There are predefined examples in 'tile_builder.dart'
  final TilesContainerBuilder? tilesContainerBuilder;

  // If a Tile was loaded with error and if strategy isn't `none` then TileProvider
  // will be asked to evict Image based on current strategy
  // (see #576 - even Error Images are cached in flutter)
  final EvictErrorTileStrategy evictErrorTileStrategy;

  /// This option is useful when you have a transparent layer: rather than
  /// keeping the old layer visible when zooming (resulting in both layers
  /// being temporarily visible), the old layer is removed as quickly as
  /// possible when this is set to `true` (default `false`).
  ///
  /// This option is likely to cause some flickering of the transparent layer,
  /// most noticeable when using pinch-to-zoom. It's best used with maps that
  /// have `interactive` set to `false`, and zoom using buttons that call
  /// `MapController.move()`.
  ///
  /// When set to `true`, the `tileFadeIn*` options will be ignored.
  final bool fastReplace;

  /// Stream to notify the [TileLayer] that it needs resetting
  Stream<void>? reset;

  /// Only load tiles that are within these bounds
  LatLngBounds? tileBounds;

  TileLayerOptions({
    Key? key,
    this.urlTemplate,
    double tileSize = 256.0,
    double minZoom = 0.0,
    double maxZoom = 18.0,
    this.minNativeZoom,
    this.maxNativeZoom,
    this.zoomReverse = false,
    double zoomOffset = 0.0,
    Map<String, String>? additionalOptions,
    this.subdomains = const <String>[],
    this.keepBuffer = 2,
    this.backgroundColor = const Color(0xFFE0E0E0),
    this.errorImage,
    TileProvider? tileProvider,
    this.tms = false,
    this.wmsOptions,
    this.opacity = 1.0,

    /// Tiles will not update more than once every `updateInterval` milliseconds
    /// (default 200) when panning. It can be 0 (but it will calculating for
    /// loading tiles every frame when panning / zooming, flutter is fast) This
    /// can save some fps and even bandwidth (ie. when fast panning / animating
    /// between long distances in short time)
    Duration updateInterval = const Duration(milliseconds: 200),
    Duration tileFadeInDuration = const Duration(milliseconds: 100),
    this.tileFadeInStart = 0.0,
    this.tileFadeInStartWhenOverride = 0.0,
    this.overrideTilesWhenUrlChanges = false,
    this.retinaMode = false,
    this.errorTileCallback,
    Stream<void>? rebuild,
    this.templateFunction = util.template,
    this.tileBuilder,
    this.tilesContainerBuilder,
    this.evictErrorTileStrategy = EvictErrorTileStrategy.none,
    this.fastReplace = false,
    this.reset,
    this.tileBounds,
    String userAgentPackageName = 'unknown',
  })  : updateInterval =
            updateInterval <= Duration.zero ? null : updateInterval,
        tileFadeInDuration =
            tileFadeInDuration <= Duration.zero ? null : tileFadeInDuration,
        assert(tileFadeInStart >= 0.0 && tileFadeInStart <= 1.0),
        assert(tileFadeInStartWhenOverride >= 0.0 &&
            tileFadeInStartWhenOverride <= 1.0),
        maxZoom =
            wmsOptions == null && retinaMode && maxZoom > 0.0 && !zoomReverse
                ? maxZoom - 1.0
                : maxZoom,
        minZoom =
            wmsOptions == null && retinaMode && maxZoom > 0.0 && zoomReverse
                ? math.max(minZoom + 1.0, 0)
                : minZoom,
        zoomOffset = wmsOptions == null && retinaMode && maxZoom > 0.0
            ? (zoomReverse ? zoomOffset - 1.0 : zoomOffset + 1.0)
            : zoomOffset,
        tileSize = wmsOptions == null && retinaMode && maxZoom > 0.0
            ? (tileSize / 2.0).floorToDouble()
            : tileSize,
        additionalOptions = additionalOptions == null
            ? const <String, String>{}
            : Map.from(additionalOptions),
        tileProvider = tileProvider == null
            ? NetworkNoRetryTileProvider(
                headers: {'User-Agent': 'flutter_map ($userAgentPackageName)'},
              )
            : (tileProvider
              ..headers = <String, String>{
                ...tileProvider.headers,
                if (!tileProvider.headers.containsKey('User-Agent'))
                  'User-Agent': 'flutter_map ($userAgentPackageName)',
              }),
        super(key: key, rebuild: rebuild);
}

class WMSTileLayerOptions {
  final service = 'WMS';
  final request = 'GetMap';

  /// WMS service's URL, for example 'http://ows.mundialis.de/services/service?'
  final String baseUrl;

  /// List of WMS layers to show
  final List<String> layers;

  /// List of WMS styles
  final List<String> styles;

  /// WMS image format (use 'image/png' for layers with transparency)
  final String format;

  /// Version of the WMS service to use
  final String version;

  /// Whether to make tiles transparent
  final bool transparent;

  /// Encode boolean values as uppercase in request
  final bool uppercaseBoolValue;

  /// Sets map projection standard
  final Crs crs;

  /// Other request parameters
  final Map<String, String> otherParameters;

  late final String _encodedBaseUrl;

  late final double _versionNumber;

  WMSTileLayerOptions({
    required this.baseUrl,
    this.layers = const [],
    this.styles = const [],
    this.format = 'image/png',
    this.version = '1.1.1',
    this.transparent = true,
    this.uppercaseBoolValue = false,
    this.crs = const Epsg3857(),
    this.otherParameters = const {},
  }) {
    _versionNumber = double.tryParse(version.split('.').take(2).join('.')) ?? 0;
    _encodedBaseUrl = _buildEncodedBaseUrl();
  }

  String _buildEncodedBaseUrl() {
    final projectionKey = _versionNumber >= 1.3 ? 'crs' : 'srs';
    final buffer = StringBuffer(baseUrl)
      ..write('&service=$service')
      ..write('&request=$request')
      ..write('&layers=${layers.map(Uri.encodeComponent).join(',')}')
      ..write('&styles=${styles.map(Uri.encodeComponent).join(',')}')
      ..write('&format=${Uri.encodeComponent(format)}')
      ..write('&$projectionKey=${Uri.encodeComponent(crs.code)}')
      ..write('&version=${Uri.encodeComponent(version)}')
      ..write(
          '&transparent=${uppercaseBoolValue ? transparent.toString().toUpperCase() : transparent}');
    otherParameters
        .forEach((k, v) => buffer.write('&$k=${Uri.encodeComponent(v)}'));
    return buffer.toString();
  }

  String getUrl(Coords coords, int tileSize, bool retinaMode) {
    final tileSizePoint = CustomPoint(tileSize, tileSize);
    final nvPoint = coords.scaleBy(tileSizePoint);
    final sePoint = nvPoint + tileSizePoint;
    final nvCoords = crs.pointToLatLng(nvPoint, coords.z as double)!;
    final seCoords = crs.pointToLatLng(sePoint, coords.z as double)!;
    final nv = crs.projection.project(nvCoords);
    final se = crs.projection.project(seCoords);
    final bounds = Bounds(nv, se);
    final bbox = (_versionNumber >= 1.3 && crs is Epsg4326)
        ? [bounds.min.y, bounds.min.x, bounds.max.y, bounds.max.x]
        : [bounds.min.x, bounds.min.y, bounds.max.x, bounds.max.y];

    final buffer = StringBuffer(_encodedBaseUrl);
    buffer.write('&width=${retinaMode ? tileSize * 2 : tileSize}');
    buffer.write('&height=${retinaMode ? tileSize * 2 : tileSize}');
    buffer.write('&bbox=${bbox.join(',')}');
    return buffer.toString();
  }
}

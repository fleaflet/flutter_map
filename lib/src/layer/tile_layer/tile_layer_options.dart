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

  /// Color shown behind the tiles.
  final Color backgroundColor;

  /// Opacity of the rendered tile
  final double opacity;

  /// Provider to load the tiles. The default is `NonCachingNetworkTileProvider()` which
  /// doesn't cache tiles and won't retry the HTTP request. Use `NetworkTileProvider()` for
  /// a provider which will retry requests. For the best caching implementations, see the
  /// flutter_map readme.
  ///
  /// In order to use images from the asset folder set this option to
  /// AssetTileProvider() Note that it requires the urlTemplate to target
  /// assets, for example:
  ///
  /// ```dart
  /// urlTemplate: "assets/map/anholt_osmbright/{z}/{x}/{y}.png",
  /// ```
  ///
  /// In order to use images from the filesystem set this option to
  /// FileTileProvider() Note that it requires the urlTemplate to target the
  /// file system, for example:
  ///
  /// ```dart
  /// urlTemplate: "/storage/emulated/0/tiles/some_place/{z}/{x}/{y}.png",
  /// ```
  ///
  /// Furthermore you create your custom implementation by subclassing
  /// TileProvider
  final TileProvider tileProvider;

  /// When panning the map, keep this many rows and columns of tiles before
  /// unloading them.
  final int keepBuffer;

  /// Placeholder to show until tile images are fetched by the provider.
  ///
  /// _`placeholderImage` has been deprecated with no current replacement or workaround. Usage no longer has an effect internally._
  @Deprecated(
      '`placeholderImage` has been deprecated with no current replacement or workaround. Usage no longer has an effect internally.')
  final ImageProvider? placeholderImage;

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

  /// [attributionBuilder] has been deprecated. Usage will continue to work, however not as expected. As an alternative, use [AttributionWidget] inside `nonRotatedChildren`.
  @Deprecated(
    '`attributionBuilder` has been deprecated. Usage will continue to work, however not as expected. As an alternative, use `AttributionWidget` inside `nonRotatedChildren`.',
  )
  final WidgetBuilder? attributionBuilder;

  ///aligment of the attribution text on the map widget
  final Alignment attributionAlignment;

  /// Stream to notify the [TileLayer] that it needs resetting
  Stream<void>? reset;

  /// Only load tiles that are within these bounds
  LatLngBounds? tileBounds;

  TileLayerOptions({
    this.attributionAlignment = Alignment.bottomRight,
    @Deprecated(
      '`attributionBuilder` has been deprecated. Usage will continue to work, however not as expected. As an alternative, use `AttributionWidget` inside `nonRotatedChildren`.',
    )
        this.attributionBuilder,
    Key? key,
    // TODO: make required
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
    @Deprecated('`placeholderImage` has been deprecated with no current replacement or workaround. Usage no longer has an effect internally.')
        this.placeholderImage,
    this.errorImage,
    this.tileProvider = const NonCachingNetworkTileProvider(),
    this.tms = false,
    // ignore: avoid_init_to_null
    this.wmsOptions = null,
    this.opacity = 1.0,
    // Tiles will not update more than once every `updateInterval` milliseconds
    // (default 200) when panning. It can be 0 (but it will calculating for
    // loading tiles every frame when panning / zooming, flutter is fast) This
    // can save some fps and even bandwidth (ie. when fast panning / animating
    // between long distances in short time)
    // TODO: change to Duration
    int updateInterval = 200,
    // Tiles fade in duration in milliseconds (default 100).  This can be set to
    // 0 to avoid fade in
    // TODO: change to Duration
    int tileFadeInDuration = 100,
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
  })  : updateInterval =
            updateInterval <= 0 ? null : Duration(milliseconds: updateInterval),
        tileFadeInDuration = tileFadeInDuration <= 0
            ? null
            : Duration(milliseconds: tileFadeInDuration),
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
        // copy additionalOptions Map if not null, so we can safely compare old
        // and new Map inside didUpdateWidget with MapEquality.
        additionalOptions = additionalOptions == null
            ? const <String, String>{}
            : Map.from(additionalOptions),
        super(key: key, rebuild: rebuild);
}

class WMSTileLayerOptions {
  final service = 'WMS';
  final request = 'GetMap';

  /// url of WMS service.
  /// Ex.: 'http://ows.mundialis.de/services/service?'
  final String baseUrl;

  /// list of WMS layers to show
  final List<String> layers;

  /// list of WMS styles
  final List<String> styles;

  /// WMS image format (use 'image/png' for layers with transparency)
  final String format;

  /// Version of the WMS service to use
  final String version;

  /// tile transparency flag
  final bool transparent;

  /// Encode boolean values as uppercase in request
  final bool uppercaseBoolValue;

  // TODO find a way to implicit pass of current map [Crs]
  final Crs crs;

  /// other request parameters
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

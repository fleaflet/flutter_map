# Built-In Caching

{% hint style="danger" %}
This page contains references to as-of-yet unconfirmed features, which may change without warning. The information on this page is likely to change frequently, and potentially significantly, or may be removed completely.

See [https://github.com/fleaflet/flutter\_map/pull/2082](https://github.com/fleaflet/flutter_map/pull/2082) for progress.
{% endhint %}

From v8.2.0, flutter\_map provides simple automatically-enabled built-in caching for compatible tile providers (such as `NetworkTileProvider`) on non-web platforms.

{% hint style="warning" %}
Built-in caching is not a replacement for caching which can better guarantee resilience. It provides no guarantees as to the safety of cached tiles, which may become unexpectedly lost/inaccessible at any time.

It should not be relied upon where not having cached tiles may lead to a dangerous situation - for example, offline mapping. See [offline-mapping.md](../../tile-servers/offline-mapping.md "mention") for information about implementing more appropriate solutions.
{% endhint %}

Built-in caching aims to:

* Reduce the strain on tile servers (particularly the [OpenStreetMap public tile servers](../../tile-servers/using-openstreetmap-direct.md))
* Improve compliance with tile server terms/requirements
* Reduce the costs of using tile servers by reducing unnecessary tile requests
* Improve map tile loading speeds, especially on slower networks
* Keep your app lightweight - it doesn't require a database

It does, however, come at the expense of usage of on-device storage capacity.

{% hint style="info" %}
Some plugins which perform caching or offline mapping may instead provide a dedicated `TileProvider`.

In this case, built-in caching is not applicable, and will not be used (unless the provider explicitly supports usage of built-in caching).&#x20;
{% endhint %}

## Configuration

{% hint style="success" %}
Built-in caching is enabled by default.
{% endhint %}

Built-in caching supports extendability and customizability.

By default, the `BuiltInMapCachingProvider` is used, which has multiple options to adjust its basic behaviour. It's backed by an efficient filesystem cache, where tiles are stored alongside their metadata (necessary to perform caching) in the same file.

<mark style="background-color:yellow;">insert link</mark>

To configure the `BuiltInMapCachingProvider`,  supply arguments to the `getOrCreateInstance` factory constructor. Usually this is done when constructing the `TileLayer`/`TileProvider`:

<pre class="language-dart"><code class="lang-dart">TileLayer(
    urlTemplate: '...',
    userAgentPackageName: '...',
    tileProvider: NetworkTileProvider(
<strong>        cachingProvider: BuiltInMapCachingProvider.getOrCreateInstance(
</strong><strong>            maxCacheSize: 1_000_000_000, // 1 GB is the default
</strong><strong>        ),
</strong>    ),
);
</code></pre>

By default, caching occurs in a platform provided cache directory. The operating system may clear this at any time.

By default, a 1 GB (soft) limit is applied to the built-in caching. This limit is only applied when the cache provider is initialised (usually when the first tiles are loaded on each app session).

HTTP headers are used to determine how long a tile is considered 'fresh' - this fulfills the requirements of many tile servers. However, setting `overrideFreshAge` allows the HTTP headers to be overridden, and the tile to be stored and used for a set duration.

{% hint style="info" %}
It is not possible to change the configuration after the provider instance has been created.

It is possible to change the configuration when an existing cache exists, but the provider has not yet been initialised (in the app session).
{% endhint %}

It is also possible to create the provider instance elsewhere in the app, as long as it occurs before the first tile provider uses it. With the default provider, configuration will automatically occur for all tile providers, and you won't need to specify it on each one, as above.

### Using Other `MapCachingProvider`s

You can also use any other `MapCachingProvider` implementation, such as provided by plugins, or create one yourself! They may support the web platform, unlike the built-in cache.

You should check that plugin's documentation for information about initialisation & configuration. You will always need to pass it to the `cachingProvider` argument of a compatible `TileProvider`, as above.

### Disabling Built-In Caching

{% hint style="warning" %}
Before disabling built-in caching, you should check that you can still be compliant with any requirements imposed by your tile server.

It is your own responsibility to comply with any appropriate restrictions and requirements set by your chosen tile server/provider. Always read their Terms of Service. Failure to do so may lead to any punishment, at the tile server's discretion.

The built-in caching is designed to be compliant with the caching requirement for the [OpenStreetMap public tile server](../../tile-servers/using-openstreetmap-direct.md). Disabling it may make your project non-compliant.
{% endhint %}

If you prefer to disable built-in caching, use the `DisabledMapCachingProvider` on each tile provider:&#x20;

```dart
TileLayer(
    urlTemplate: '...',
    userAgentPackageName: '...',
    tileProvider: NetworkTileProvider(
        cachingProvider: const DisabledMapCachingProvider(),
    ),
);
```

This is not necessary on the web.

## Managing The Cache

It is not directly possible to reset/empty/delete the cache (when using the `BuiltInMapCachingProvider`).

On many systems, users can delete the entire app cache through the app's settings. Alternatively, it can be cleared out manually on desktop platforms.

You may also delete the cache directory yourself. This is only possible before the cache has been used for the first time by the process - for example, before the first map tile is loaded - otherwise, some files will be locked by flutter\_map. If you're using a custom directory, delete that - otherwise, use '[package:path\_provider](https://pub.dev/packages/path_provider)'s `getApplicationCacheDirectory()`.

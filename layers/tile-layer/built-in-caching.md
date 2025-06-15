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
* Be extensible, customizable, and integrate with multiple tile providers

It does, however, come at the expense of usage of on-device storage capacity.

{% hint style="info" %}
Some plugins which perform caching or offline mapping may instead provide a dedicated `TileProvider`.

In this case, built-in caching is not applicable, and will not be used (unless the provider explicitly supports usage of built-in caching).&#x20;
{% endhint %}

## Configuring the default provider

{% hint style="success" %}
Built-in caching is enabled by default, using the `BuiltInMapCachingProvider` implementation.
{% endhint %}

<mark style="background-color:yellow;">insert link</mark>

To configure the default provider, provide arguments to the `getOrCreateInstance` factory constructor. Usually this is done when constructing the `TileLayer`/`TileProvider`:

<pre class="language-dart" data-title="configured_built_in.dart"><code class="lang-dart">TileLayer(
    urlTemplate: '...',
    userAgentPackageName: '...',
    tileProvider: NetworkTileProvider(
<strong>        cachingProvider: BuiltInMapCachingProvider.getOrCreateInstance(
</strong><strong>            maxCacheSize: 1_000_000_000, // 1 GB is the default
</strong><strong>        ),
</strong>    ),
);
</code></pre>

{% hint style="info" %}
It is not possible to change the configuration after the provider instance has been created (without first `destroy`ing it).

This means if you configure the provider in the first tile provider/tile layer used (or indeed outside of the map context, such as in the `main` method), the configuration does not need to be manually specified in each tile provider.

***

It is possible to change the configuration after a cache on the filesystem has already been created.
{% endhint %}

By default, caching occurs in a platform provided cache directory. The operating system may clear this at any time.

By default, a 1 GB (soft) limit is applied to the built-in caching. This limit is only applied when the cache provider is initialised (usually when the first tiles are loaded on each app session).

HTTP headers are used to determine how long a tile is considered 'fresh' - this fulfills the requirements of many tile servers. However, setting `overrideFreshAge` allows the HTTP headers to be overridden, and the tile to be stored and used for a set duration.

The `tileKeyGenerator` can be customized. The callback accepts the tile's URL, and converts it to a key used to uniquely identify the tile. By default, it generates a UUID from the entire URL string. However, in some cases, the default behaviour should be changed:

<details>

<summary>Using a custom <code>tileKeyGenerator</code></summary>

Where parts of the URL are volatile or do not represent the tile's&#x20;contents/image - for example, API keys contained with the query&#x20;parameters - this should be modified to remove the volatile portions.

Otherwise, tiles stored with an old/rejected volatile portion will not be utilised by the cache, and will waste storage space.

Keys must be usable as filenames on all intended platform filesystems.

***

Implementations may use the static utility method `uuidTileKeyGenerator` if they just wish to modify the input URL.

Convenient methods to modify URLs can be found by first parsing it to a [`Uri`](https://api.flutter.dev/flutter/dart-core/Uri-class.html) using `Uri.parse`, working on it (such as with [`replace`](https://api.flutter.dev/flutter/dart-core/Uri/replace.html)), then converting it back to a string.

Alternatively, the raw URL string could be worked on manually, such as by using regular expression to extract certain parts.

</details>

### Deleting the cache

With the default `BuiltInMapCachingProvider`, it is possible to delete the cache contents in two ways:

* When the app is running, `destroy` the current instance and set the `deleteCache` argument to `true` (then optionally create a new instance if required, which happens automatically on the next tile load by default)
* When the app is not running, users may delete the storage directory
  * If the default cache directory is used, users may do this by 'clearing the app cache' through their operating system, for example. On some platforms, this may need to be done manually (which may be difficult for less technical users), whilst on others, it may be a simple action.

## Using other implementations

You can also use any other `MapCachingProvider` implementation, such as provided by plugins, or [create one yourself](../../plugins/create/caching-providers.md)! They may support the web platform, unlike the built-in cache.

You should check that plugin's documentation for information about initialisation & configuration. You will always need to pass it to the `cachingProvider` argument of a compatible `TileProvider`.

<pre class="language-dart" data-title="custom.dart"><code class="lang-dart">TileLayer(
    urlTemplate: '...',
    userAgentPackageName: '...',
    tileProvider: NetworkTileProvider(
<strong>        cachingProvider: CustomMapCachingProvider(),
</strong>    ),
);
</code></pre>

## Disabling built-in caching

{% hint style="warning" %}
Before disabling built-in caching, you should check that you can still be compliant with any requirements imposed by your tile server.

It is your own responsibility to comply with any appropriate restrictions and requirements set by your chosen tile server/provider. Always read their Terms of Service. Failure to do so may lead to any punishment, at the tile server's discretion.

The built-in caching is designed to be compliant with the caching requirement for the [OpenStreetMap public tile server](../../tile-servers/using-openstreetmap-direct.md). Disabling it may make your project non-compliant.
{% endhint %}

{% hint style="info" %}
This is not necessary when running on the web.
{% endhint %}

If you prefer to disable built-in caching, use the `DisabledMapCachingProvider` on each tile provider:&#x20;

{% code title="disabled.dart" %}
```dart
TileLayer(
    urlTemplate: '...',
    userAgentPackageName: '...',
    tileProvider: NetworkTileProvider(
        cachingProvider: const DisabledMapCachingProvider(),
    ),
);
```
{% endcode %}

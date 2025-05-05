# Built-In Caching

{% hint style="danger" %}
This page contains references to as-of-yet unconfirmed features, which may change without warning. The information on this page is likely to change frequently, and potentially significantly, or may be removed completely.

See [https://github.com/fleaflet/flutter\_map/pull/2082](https://github.com/fleaflet/flutter_map/pull/2082) for progress.
{% endhint %}

From v8.2.0, flutter\_map provides simple automatically-enabled built-in caching for the `NetworkTileProvider` (and `CancellableNetworkTileProvider` in the near-future) on native platforms.

{% hint style="warning" %}
Built-in caching is not a replacement for caching which can better guarantee resilience. It provides no guarantees as to the safety of cached tiles, which may become unexpectedly lost/inaccessible at any time.

It should not be relied upon where not having cached tiles may lead to a dangerous situation - for example, offline mapping. See [offline-mapping.md](../../tile-servers/offline-mapping.md "mention") for information about implementing more appropriate solutions.
{% endhint %}

Built-in caching aims to:

* Reduce the strain on tile servers (particularly the [OpenStreetMap public tile servers](../../tile-servers/using-openstreetmap-direct.md))
* Improve compliance with tile server terms/requirements
* Reduce the costs of using tile servers by reducing unnecessary tile requests
* Potentially improve map tile loading speeds

It does, however, come at the expense of usage of on-device storage capacity.

It uses HTTP caching headers returned with tiles to perform this.&#x20;

## Disabling built-in caching

{% hint style="warning" %}
Before disabling built-in caching, you should check that you can still be compliant with any requirements imposed by your tile server.

It is your own responsibility to comply with any appropriate restrictions and requirements set by your chosen tile server/provider. Always read their Terms of Service. Failure to do so may lead to any punishment, at the tile server's discretion.

The built-in caching is designed to be compliant with the caching requirement for the [OpenStreetMap public tile server](../../tile-servers/using-openstreetmap-direct.md). Disabling it may make your project non-compliant.
{% endhint %}

If you prefer to disable built-in caching, set the `cachingOptions` parameter on the tile provider to `null`.

```dart
TileLayer(
    urlTemplate: '',
    userAgentPackageName: '',
    tileProvider: NetworkTileProvider(
        cachingOptions: null,
    ),
),
```

If you're using a different tile provider that does not use `MapTileCachingManager` internally, it does not support built-in caching.

## Configuration

The `cachingOptions` parameter can be passed a `MapCachingOptions` to configure the built-in caching.

<mark style="background-color:yellow;">insert link</mark>

By default, caching occurs in a platform provided cache directory. The operating system may clear this at any time.

By default, a 1GB preferred (soft) limit is applied to the built-in caching.

## Managing the cache

<mark style="background-color:yellow;">check!</mark>

It is not directly possible to reset/empty/delete the cache.

On many systems, users can delete the entire app cache through the app's settings. Alternatively, it can be cleared out manually on desktop platforms.

You may also try to delete the cache directory yourself. This is only possible before the cache has been used for the first time in that execution - for example, before the first map tile is loaded.


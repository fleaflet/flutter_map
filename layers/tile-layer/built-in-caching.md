# Built-In Caching

{% hint style="danger" %}
This page contains references to as-of-yet unconfirmed features, which may change without warning. The information on this page is likely to change frequently, and potentially significantly, or may be removed completely.

See [https://github.com/fleaflet/flutter\_map/pull/2082](https://github.com/fleaflet/flutter_map/pull/2082) for progress.
{% endhint %}

From v8.2.0, flutter\_map provides simple automatically-enabled built-in caching (based on the HTTP headers sent with tile responses) for the `NetworkTileProvider` (and `CancellableNetworkTileProvider` in the near-future) on non-web platforms.

{% hint style="warning" %}
Built-in caching is not a replacement for caching which can better guarantee resilience. It provides no guarantees as to the safety of cached tiles, which may become unexpectedly lost/inaccessible at any time.

It should not be relied upon where not having cached tiles may lead to a dangerous situation - for example, offline mapping. See [offline-mapping.md](../../tile-servers/offline-mapping.md "mention") for information about implementing more appropriate solutions.
{% endhint %}

Built-in caching aims to:

* Reduce the strain on tile servers (particularly the [OpenStreetMap public tile servers](../../tile-servers/using-openstreetmap-direct.md))
* Improve compliance with tile server terms/requirements
* Reduce the costs of using tile servers by reducing unnecessary tile requests
* Potentially improve map tile loading speeds, especially on slower networks
* Keep your app lightweight - it doesn't require a database

It does, however, come at the expense of usage of on-device storage capacity.

## Recommended Setup

{% hint style="success" %}
Built-in caching is enabled by default.

However, you/users may notice a small delay before tiles are initially loaded. Usually, this delay is \~50ms to \~800ms, depending on the size of the cache. With a single extra line, this delay can be 'moved'.
{% endhint %}

This delay can be 'moved'. We recommend moving the delay for all production apps.

If you have a loading screen, you could move the delay to be included within that. Otherwise, we recommend moving it to the `main` method prior to calling `runApp`:

<pre class="language-dart"><code class="lang-dart">Future&#x3C;void> main() async {
<strong>  await BuiltInMapCachingProvider.getOrCreateInstance().isInitialised;
</strong>  runApp(const MyApp());
}
</code></pre>

{% hint style="info" %}
Some plugins which perform caching or offline mapping may instead provide a dedicated `TileProvider`.

In this case, built-in caching is not applicable, and will not be used (unless the provider explicitly supports usage of built-in caching). You should not await the caching provider's initialisation as above, as it will not be used.
{% endhint %}

## Configuration

Built-in caching supports extendability and customizability.

By default, the `BuiltInMapCachingProvider` is used, which has multiple options to adjust its basic behaviour. It's backed by a simple (yet performant) JSON + I/O cache.

<mark style="background-color:yellow;">insert link</mark>

To configure the `BuiltInMapCachingProvider`, we recommend following the [#recommended-setup](built-in-caching.md#recommended-setup "mention") above. Then, you can supply arguments to the `getOrCreateInstance` factory constructor, which will be automatically used.

By default, caching occurs in a platform provided cache directory. The operating system may clear this at any time. By default, a 1GB preferred (soft) limit is applied to the built-in caching.

### Using Other `MapCachingProvider`s

You can also use any other `MapCachingProvider` implementation, such as provided by plugins, or create one yourself!

If you're using built-in caching through a `MapCachingProvider`, but not using the default `BuiltInMapCachingProvider`, you should check that provider's documentation if available.

You will always need to - regardless of if that provider has an initialisation delay, and you've moved it (such as in [#recommended-setup](built-in-caching.md#recommended-setup "mention")) - pass it to the `NetworkTileProvider` (or whichever other tile provider you are using):

<pre class="language-dart"><code class="lang-dart">TileLayer(
    urlTemplate: '...',
    userAgentPackageName: '...',
    tileProvider: NetworkTileProvider(
        // demonstrated here with the `BuiltInMapCachingProvider`
<strong>        cachingProvider: BuiltInMapCachingProvider.getOrCreateInstance(),
</strong>    ),
);
</code></pre>

## Disabling Built-In Caching

{% hint style="warning" %}
Before disabling built-in caching, you should check that you can still be compliant with any requirements imposed by your tile server.

It is your own responsibility to comply with any appropriate restrictions and requirements set by your chosen tile server/provider. Always read their Terms of Service. Failure to do so may lead to any punishment, at the tile server's discretion.

The built-in caching is designed to be compliant with the caching requirement for the [OpenStreetMap public tile server](../../tile-servers/using-openstreetmap-direct.md). Disabling it may make your project non-compliant.
{% endhint %}

If you prefer to disable built-in caching, use the `DisabledMapCachingProvider`:&#x20;

```dart
TileLayer(
    urlTemplate: '...',
    userAgentPackageName: '...',
    tileProvider: NetworkTileProvider(
        cachingProvider: const DisabledMapCachingProvider(),
    ),
);
```

## Managing The Cache

It is not directly possible to reset/empty/delete the cache (when using the `BuiltInMapCachingProvider`).

On many systems, users can delete the entire app cache through the app's settings. Alternatively, it can be cleared out manually on desktop platforms.

You may also delete the cache directory yourself. This is only possible before the cache has been used for the first time by the process - for example, before the first map tile is loaded - otherwise, some files will be locked by flutter\_map. If you're using a custom directory, delete that - otherwise, use '[package:path\_provider](https://pub.dev/packages/path_provider)'s `getApplicationCacheDirectory()`.

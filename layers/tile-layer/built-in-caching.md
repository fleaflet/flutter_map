# Built-In Caching

{% hint style="danger" %}
This page contains references to as-of-yet unconfirmed features, which may change without warning. The information on this page is likely to change frequently, and potentially significantly, or may be removed completely.

See [https://github.com/fleaflet/flutter\_map/pull/2082](https://github.com/fleaflet/flutter_map/pull/2082) for progress.
{% endhint %}

From v8.2.0, flutter\_map provides simple automatically-enabled built-in caching for the `NetworkTileProvider` (and `CancellableNetworkTileProvider` in the near-future) on non-web platforms.

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

{% hint style="info" %}
Some plugins which perform caching or offline mapping may instead provide a dedicated `TileProvider`.

In this case, built-in caching is not applicable, and will not be used (unless the provider explicitly supports usage of built-in caching).&#x20;
{% endhint %}

## Pre-Initialisation

{% hint style="success" %}
Built-in caching is enabled by default.

However, you/users may notice a small delay (usually less than a few hundred milliseconds) before the initial tiles (in the camera view when the map is created) load.
{% endhint %}

This delay occurs whilst the central cache file stored on the filesystem is opened and unpacked into memory, which ensures that cache reads are superfast - this is known as initialisation.

As a rough estimate:

* On more powerful systems (such as desktops), 40k cached tiles adds \~100ms to the initialisation time
* On less powerful systems (such as lower-mid end smartphones), it's \~10k:100ms - although this is much more variable and improves efficiency with a larger number of stored tiles
* 10k tiles adds a little under 1 MB to the central cache file (plus the size of the tiles themselves)
* Running the size limiter adds a larger amount of time (seconds), but is harder to quantify and more dependent on I/O

{% hint style="warning" %}
Debug mode performance is not indicative of release mode performance. The time to initialise in debug mode may be up to 10x greater.
{% endhint %}

If the delay becomes significant, this delay can be 'moved', so that tile loading is not delayed directly. If you have a loading screen, you could move the delay to be included within that. Otherwise, we recommend moving it to the `main` method prior to calling `runApp`:

<pre class="language-dart"><code class="lang-dart">Future&#x3C;void> main() async {
<strong>  WidgetsFlutterBinding.ensureInitialized(); // required only if before `runApp`
</strong><strong>  await BuiltInMapCachingProvider.getOrCreateInstance().isInitialised;
</strong>  
  runApp(const MyApp());
}
</code></pre>

If you're not using built-in caching (for example, because you've disabled it, or because you're using a different tile provider which does not support it), you should remove this line.

Other built-in caching providers may provide their own similar method to await initialisation elsewhere if necessary.

## Configuration

Built-in caching supports extendability and customizability.

By default, the `BuiltInMapCachingProvider` is used, which has multiple options to adjust its basic behaviour. It's backed by a simple (yet performant) filesystem cache, where tiles are stored as raw files and a central 'registry' file coordinates the metadata for cached tiles in a FlatBuffer format.

<mark style="background-color:yellow;">insert link</mark>

To configure the `BuiltInMapCachingProvider`, we recommend following the [#recommended-setup](built-in-caching.md#recommended-setup "mention") above. Then, you can supply arguments to the `getOrCreateInstance` factory constructor, which will be automatically used.

By default, caching occurs in a platform provided cache directory. The operating system may clear this at any time.

By default, an 800 MB preferred (soft) limit is applied to the built-in caching. This limit is only applied when the cache provider is initialised (the first tiles are loaded), and so may increase the duration of the initialisation (considerably depending on the size of the cache and the target size).

HTTP headers are used to determine how long a tile is considered 'fresh' - this fulfills the requirements of many tile servers. However, setting `overrideFreshAge` allows the HTTP headers to be overridden, and the tile to be stored and used for a set duration.

### Using Other `MapCachingProvider`s

You can also use any other `MapCachingProvider` implementation, such as provided by plugins, or create one yourself!

If you're using built-in caching through a `MapCachingProvider`, but not using the default `BuiltInMapCachingProvider`, you should check that provider's documentation if available.

You will always need to - regardless of if that provider has an initialisation delay, and you've moved it (similarly to [#recommended-setup](built-in-caching.md#recommended-setup "mention")) - pass it to the `NetworkTileProvider` (or whichever other tile provider you are using):

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

Also ensure you remove the line in [#recommended-setup](built-in-caching.md#recommended-setup "mention").

This is not necessary on the web. On the web, ignoring or following [#recommended-setup](built-in-caching.md#recommended-setup "mention") and leaving `cachingProvider` at its default is exactly equivalent to using `DisabledMapCachingProvider`.

## Managing The Cache

It is not directly possible to reset/empty/delete the cache (when using the `BuiltInMapCachingProvider`).

On many systems, users can delete the entire app cache through the app's settings. Alternatively, it can be cleared out manually on desktop platforms.

You may also delete the cache directory yourself. This is only possible before the cache has been used for the first time by the process - for example, before the first map tile is loaded - otherwise, some files will be locked by flutter\_map. If you're using a custom directory, delete that - otherwise, use '[package:path\_provider](https://pub.dev/packages/path_provider)'s `getApplicationCacheDirectory()`.

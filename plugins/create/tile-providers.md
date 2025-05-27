# Tile Providers

One common requirement is a custom `TileProvider`, and potentially a custom `ImageProvider` inside. This will allow your plugin to intercept all tile requests made by a map, and take your own action(s), before finally returning a tile.

{% hint style="info" %}
Check the [list.md](../list.md "mention") for providers that already implement the behaviour you wish to replicate.
{% endhint %}

## 1. Extending `TileProvider`

To create your own usable `TileProvider`, the first step is making a class that `extends` the abstract class, and adding a constructor.

The constructor should accept an argument of `super.headers`, without a `const`ant default.

```dart
class CustomTileProvider extends TileProvider {
    CustomTileProvider({
        // Suitably initialise your own custom properties
        super.headers, // Accept a `Map` of custom HTTP headers
    })
}
```

{% hint style="info" %}
If using an object that needs closing/cancelling, such as an `HttpClient`, override the `dispose` method.
{% endhint %}

## 2. Setup Tile Retrieval

`TileProvider`s must implement a method to return an `ImageProvider` (the image of a tile), given its coordinates and the `TileLayer` it is used within.

{% hint style="success" %}
It is best to put as much logic as possible into a custom `ImageProvider`, to avoid blocking the main thread.
{% endhint %}

There's two methods that could be called by flutter\_map internals to retrieve a tile: `getImage` or `getImageWithCancelLoadingSupport`.

Prefer overriding `getImageWithCancelLoadingSupport` for `TileProvider`s that can cancel the loading of a tile in-flight, if the tile is pruned before it is fully loaded. An example of a provider that may be able to do this is one that makes HTTP requests, as HTTP requests can be aborted on the web (although Dart does not 'natively' support it yet, so a library such as Dio is necessary). Otherwise, `getImage` must be overridden.

{% tabs %}
{% tab title="With Cancel Loading Support" %}
In addition to the coordinates and `TileLayer`, the method also takes a `Future<void>` that is completed when the tile is pruned. It should be listened to for completion (for example, with `then`), then used to trigger the cancellation.

For an example of this, see [#cancellablenetworktileprovider](../../layers/tile-layer/tile-providers.md#cancellablenetworktileprovider "mention").

```dart
    @override
    bool get supportsCancelLoading => true;
    
    @override
    ImageProvider getImageWithCancelLoadingSupport(
        TileCoordinates coordinates,
        TileLayer options,
        Future<void> cancelLoading,
    ) =>
        CustomCancellableImageProvider(
            url: getTileUrl(coordinates, options),
            fallbackUrl: getTileFallbackUrl(coordinates, options),
            cancelLoading: cancelLoading,
            tileProvider: this,
        );
```
{% endtab %}

{% tab title="Without Cancel Loading Support" %}
```dart
    @override
    ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
        CustomImageProvider(
            url: getTileUrl(coordinates, options),
            fallbackUrl: getTileFallbackUrl(coordinates, options),
            tileProvider: this,
        );
```
{% endtab %}
{% endtabs %}

{% hint style="info" %}
If developing a plugin, you may wish to adjust the 'User-Agent' header has been to further differentiate your plugin's traffic from vanilla 'flutter\_map' traffic.
{% endhint %}

Tile providers can support the `MapCachingProvider` contract/interface to support built-in caching. See [caching-providers.md](caching-providers.md "mention").

## (Optionally) Override URL Generation

Some custom `TileProvider`s may want to change the way URLs are generated for tiles, given a coordinate.

It's possible to override:

* how the `urlTemplate`'s placeholders are populated: `populateTemplatePlaceholders`
* the values used to populate those placeholders: `generateReplacementMap`
* the generation method itself: `getTileUrl` and/or `getTileFallbackUrl`

{% hint style="warning" %}
Avoid overriding the generation method itself, as it is not usually necessary.
{% endhint %}

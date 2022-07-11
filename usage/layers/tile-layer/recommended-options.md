# Recommended Options

## URL Template (`urlTemplate:`)

_This parameter is not strictly required, but the map is essential useless without it specified to a valid URL._

Takes a string that is a valid URL, which is the template to use when the tile provider constructs the URL to request a tile from a tile server. For example:

```dart
        urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
```

...will use the default OpenStreetMap tile server. If using this tile server, you must conform to their [Terms of Service](https://operations.osmfoundation.org/policies/tiles/).

The '{s}', '{z}', '{x}' & '{y}' parts indicate where to place the subdomain, zoom level, x coordinate, and y coordinate respectively. Not providing at least the latter 3 parts won't necessarily throw an error, but the map won't show anything.

## Package Name (`userAgentPackageName:`)

Takes a `String`, which should be the unique package name (eg. com.example.app). For example:

```dart
        userAgentPackageName: 'com.example.app',
```

This string is used to construct a 'User-Agent' header, sent with all tile requests (on platforms other than the web, due to Dart limitations), necessary to prevent blocking by tile servers.

Constructed agents are in the format: 'flutter\_map (packageName)'. If the package name is not specified, 'unknown' is used in place.

{% hint style="warning" %}
Although it is not required, not specifying the correct package name will/may group your applications traffic with other application's traffic. If the total traffic exceeds the server's limits, they may choose to block all traffic with that agent, leading to a 403 HTTP error.
{% endhint %}

## Tile Provider (`tileProvider:`)

For more information, see:

{% content-ref url="tile-providers.md" %}
[tile-providers.md](tile-providers.md)
{% endcontent-ref %}

## Retina Mode (`retinaMode:`)

A `bool` flag to enable or disable (default) makeshift retina mode, recommended on supporting devices. If the tile server supports retina mode natively ('@2' tiles), you should use them instead.

If `true`, the providers should request four tiles of half the specified size and a bigger zoom level in place of one to utilize the high resolution. In this case, you should set `MapOptions`'s `maxZoom` should be `maxZoom - 1` instead.

For example, this is the recommended setup:

```dart
        retinaMode: true && MediaQuery.of(context).devicePixelRatio > 1.0,
```

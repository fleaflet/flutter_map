# Using Stadia Maps

{% hint style="info" %}
'flutter\_map' is in no way associated or related with Stadia Maps.

Stadia Maps' home page: [stadiamaps.com](https://stadiamaps.com/)\
Stadia Maps' pricing page: [stadiamaps.com/pricing](https://stadiamaps.com/pricing/)\
Stadia Maps' documentation page: [docs.stadiamaps.com](https://docs.stadiamaps.com/)
{% endhint %}

Stadia Maps is a popular tiered-payment (with free-tier) tile provider solution, especially for generic mapping applications. Setup with 'flutter\_map' is relatively straightforward, but this page provides an example anyway.

## Pre-made Styles

Stadia Maps offers a variety of [map styles](https://docs.stadiamaps.com/themes) out of the box, that don't require customization.

For normal usage with raster tiles, use the Raster URL for the style you like, then follow the [#normal-raster](using-stadia-maps.md#normal-raster "mention") instructions.

For more information about using the vector tiles, see [#vector-usage](using-stadia-maps.md#vector-usage "mention").

## Custom Styles

You can find details on Stadia Maps' support for custom styles at the bottom of the [map styles documentation](https://docs.stadiamaps.com/themes/#custom-styles).

## Usage

### Normal (raster)

You should remove the 'api\_key' (found at the end of the URL) from the URL for readability. Instead, pass it to `additionalOptions`.

```dart
FlutterMap(
    options: MapOptions(
      center: LatLng(51.5, -0.09),
      zoom: 13.0,
    ),
    nonRotatedChildren: [
        AttributionWidget.defaultWidget(
            source: 'Stadia Maps © OpenMapTiles © OpenStreetMap contributors',
            onSourceTapped: () async {
                // Requires 'url_launcher'
                if (!await launchUrl(Uri.parse("https://stadiamaps.com/attribution"))) {
                    if (kDebugMode) print('Could not launch URL');
                }
            },
        )
    ],
    children: [
      TileLayer(
        urlTemplate: "https://tiles.stadiamaps.com/tiles/alidade_smooth_dark/{z}/{x}/{y}{r}.png?api_key={api_key}",
        additionalOptions: {
            "api_key": "<API-KEY>",
        },
        userAgentPackageName: 'com.example.app',
        maxNativeZoom: 20,
      ),
    ],
);
```

### Vector Usage

Stadia Maps' also provides vector tiles. For more information about using vector tiles, please see [#using-vector-tiles](../getting-started/explanation/raster-vs-vector-tiles.md#using-vector-tiles "mention").&#x20;

However, please note that this method of integration is still experimental. Many of the Stadia Maps styles utilize advanced features of the Mapbox GL JSON style language which are not yet well-supported.

If you are interested in contributing to this, please join the [Discord server](https://discord.gg/egEGeByf4q).

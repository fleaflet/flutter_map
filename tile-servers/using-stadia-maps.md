# Using Stadia Maps

{% hint style="info" %}
'flutter\_map' is in no way associated or related with Stadia Maps.

Stadia Maps' map tiles page: [stadiamaps.com/products/map-tiles/](https://stadiamaps.com/products/map-tiles/)\
Stadia Maps' pricing page: [stadiamaps.com/pricing/](https://stadiamaps.com/pricing/)\
Stadia Maps' style library: [docs.stadiamaps.com/themes](https://docs.stadiamaps.com/themes)
{% endhint %}

## Getting an API Key

Stadia Maps provides both raster and vector map tiles. They have a free tier for development and non-commercial use,
and usage-based commercial pricing. You can sign up for an API key for free (no card required) at
[client.stadiamaps.com](http://client.stadiamaps.com/).

## Map Styles

### Pre-made Styles

Stadia Maps offers a variety of [map styles](https://docs.stadiamaps.com/themes) out of the box. If you are using
`flutter_map` with raster tiles (the default), you generally need to use one of these. If you're using raster tiles,
use the Raster (XYZ PNGs) URL for the style you like. Similarly, for vector tiles, simply use the vector
JSON URL.

### Custom Styles

You can find details on Stadia Maps' support for custom styles at the bottom of the
[map styles documentation](https://docs.stadiamaps.com/themes/#custom-styles).

## Usage

Below is an example instantiation of the `FlutterMap` widget for Stadia Maps with raster
tiles. Be sure to fill in the API key.

```dart
FlutterMap(
    options: MapOptions(
      center: LatLng(51.5, -0.09),
      zoom: 13.0,
    ),
    children: [
      TileLayer(
        urlTemplate: "https://tiles.stadiamaps.com/tiles/alidade_smooth_dark/{z}/{x}/{y}{r}.png?api_key={api_key}",
        additionalOptions: {
            "api_key": "<YOUR-STADIA-MAPS-API-KEY>"
        },
        maxZoom: 20,
        maxNativeZoom: 20,
      ),
    ],
);
```

Stadia Maps' vector tiles also work with the [vector_map_tiles](https://github.com/greensopinion/flutter-vector-map-tiles)
plugin. However, please note that this plugin is still experimental. Many of the Stadia Maps styles utilize advanced
features of the Mapbox GL JSON style language which are not yet well-supported. If you are interested in contributing
to this, please join the [Discord server](https://discord.gg/egEGeByf4q).

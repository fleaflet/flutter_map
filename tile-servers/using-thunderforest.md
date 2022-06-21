# Using Thunderforest

{% hint style="info" %}
'flutter\_map' is in no way associated or related with Thunderforest (or Gravitystorm Limited).

Thunderstorm's home page: [thunderforest.com](https://www.thunderforest.com)\
Thunderstorm's pricing page: [thunderforest.com/pricing](https://www.thunderforest.com/pricing)\
Thunderstorm's documentation page: [thunderforest.com/docs/map-tiles-api](https://www.thunderforest.com/docs/map-tiles-api)
{% endhint %}

Thunderforest is a popular tiered-payment tile provider solution, especially for generic mapping applications. Setup with 'flutter\_map' is relatively straightforward, but this page provides an example anyway. Note that this method uses up your 'Map Tiles API' requests.

First, find the style you want. We'll be using OpenCycleMap to demonstrate.

Under 'Use this style' there should be a URL: copy this. You should remove the 'apikey' (found at the end of the URL, usually beginning with 'pk.') from the URL for security; pass it to `additionalOptions` instead.

```dart
FlutterMap(
    options: MapOptions(
      center: LatLng(51.5, -0.09),
      zoom: 13.0,
    ),
    layers: [
      TileLayerOptions(
        urlTemplate: "https://tile.thunderforest.com/cycle/{z}/{x}/{y}.png?apikey={apikey}",
        additionalOptions: {
            "apikey": "<your-api-key>"
        },
      ),
    ],
);
```

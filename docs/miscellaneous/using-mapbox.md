---
id: using-mapbox
sidebar_position: 3
---

# Using Mapbox

:::note Not Sponsored
`flutter_map` is in no way sponsored by or sponsoring Mapbox. As such, there are no links to Mapbox, only to Mapbox's documentation.

This page is provided purely to give help to those using this popular tile server/provider.
:::

Mapbox is a popular pay-as-you-go tile provider solution, especially for commerical applications. However, setup with `flutter_map` can be a bit finicky, so this page is here to help you get going with Mapbox. Note that this method uses up your 'Static Tiles API' quota.

First, create a custom map Style in the Studio. You can personalise to your heart's content, or leave it at default for a more vanilla feeling. You'll also need an [access token](https://docs.mapbox.com/help/getting-started/access-tokens/).

Then make the map style public, and open the share dialog, as seen below:
![Mapbox Map Style Share Dialog](flutter_map-wiki-mapbox1.jpg)

Scroll to the bottom of the dialog, and select Third Party. Then from the drop down box, select 'CARTO':
![Mapbox Map Style Share Dialog](flutter_map-wiki-mapbox2.jpg)

You'll then need to copy the URL and use it in `flutter_map`, like in the code below. You should remove the 'access_token' (found at the end of the URL, usually beginning with 'pk.') from the URL for security; pass it to `additionalOptions` instead.

``` dart
FlutterMap(
    options: MapOptions(
      center: LatLng(51.5, -0.09),
      zoom: 13.0,
    ),
    layers: [
      TileLayerOptions(
        urlTemplate: "https://api.mapbox.com/styles/v1/<user>/<tile-set-id>/tiles/256/{z}/{x}/{y}@2x?access_token={access_token}",
        additionalOptions: {
            "access_token": "<the-access-token-from-the-end-of-the-url"
        },
      ),
    ],
);
```

More information is available here: [https://docs.mapbox.com/help/glossary/style-url/](https://docs.mapbox.com/help/glossary/style-url/).

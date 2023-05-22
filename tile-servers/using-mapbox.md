# Using Mapbox

{% hint style="info" %}
'flutter\_map' is in no way associated or related with Mapbox.

Mapbox's Maps home page: [mapbox.com/maps](https://www.mapbox.com/maps)\
Mapbox's Maps pricing page: [mapbox.com/pricing#maps](https://www.mapbox.com/pricing#maps)\
Mapbox's Maps documentation: [docs.mapbox.com/api/maps/static-tiles](https://docs.mapbox.com/api/maps/static-tiles)
{% endhint %}

To integrate with 3rd party mapping libraries, Mapbox provides an alternative to the normal 'Style URL' for each map style (and any custom map styles).

The 'CARTO' 'Integration URL' contains all the information and placeholders that flutter\_map requires to display a map. Tiles requested through this endpoint consume the 'Static Tiles API' quota.

Once you have the appropriate URL for your desired map style (see [#styles](using-mapbox.md#styles "mention")), use it in a `TileLayer`'s `urlTemplate` as normal.

Retina tiles (high-DPI) tiles are used by default ('@2x'). The maximum zoom level that Mapbox supports is 22, so it is recommended to set `maxNativeZoom` or `maxZoom` as such.

{% hint style="warning" %}
Attribution is required, see [docs.mapbox.com/help/getting-started/attribution](https://docs.mapbox.com/help/getting-started/attribution/).

Consider using the [#richattributionwidget](../layers/attribution-layer.md#richattributionwidget "mention"), which meets the requirements by supporting both logo and text attribution.
{% endhint %}

## Styles

### Custom (Studio)

Mapbox supports creating and using custom styled maps through Studio. These are compatible with flutter\_map.

Once you've found a style that suits your needs, or created your own, make it public, then open the 'Share & develop' modal:

![](<../.gitbook/assets/flutter\_map wiki mapbox1>)

Scroll to the bottom of the modal, and select 'Third party'. Then from the drop down box, select 'CARTO'. Copy the 'Integration URL' to your clipboard, and use as above.&#x20;

<div align="center">

<img src="../.gitbook/assets/flutter_map wiki mapbox2" alt="">

</div>

### Prebuilt

Mapbox offers a variety of ready-made map styles that don't require customization. An example URL can be found in [the example here](https://docs.mapbox.com/api/maps/static-tiles/#example-request-retrieve-raster-tiles-from-styles).

This URL should be used as above, although you may need to insert the placeholders manually.

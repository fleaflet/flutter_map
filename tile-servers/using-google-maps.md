# Using Google Maps

{% hint style="info" %}
'flutter\_map' is in no way associated or related with Google Maps

Google Maps' home page: [https://developers.google.com/maps](https://developers.google.com/maps)\
Google Maps' pricing page: [https://mapsplatform.google.com/pricing/](https://mapsplatform.google.com/pricing/)\
Google Maps' documentation page: [https://developers.google.com/maps/documentation/tile/2d-tiles-overview](https://developers.google.com/maps/documentation/tile/2d-tiles-overview)
{% endhint %}

{% hint style="success" %}
Raster 2D tiles from Google Maps is a relatively new offering, which makes Google Maps directly compatible with flutter\_map, whilst abiding by the Google Maps' ToS (which the previous method did not).
{% endhint %}

{% hint style="warning" %}
Tile providers that also provide their own SDK solution to display tiles will often charge a higher price to use 3rd party libraries like flutter\_map to display their tiles. Just another reason to switch to an alternative provider.
{% endhint %}

To display map tiles from Google Maps, a little more effort is needed, as they require a complex session token system.

Therefore, we haven't yet constructed a full guide, so please read the Google Developers documentation for more info:

{% embed url="https://developers.google.com/maps/documentation/tile/2d-tiles-overview" %}

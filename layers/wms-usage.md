# WMS Usage

flutter\_map supports WMS tile servers through `WMSTileLayerOptions` - `wmsOptions` in `TileLayer`s.

For usage, please refer to the Full API Reference, and the examples in the example app.

{% embed url="https://pub.dev/documentation/flutter_map/latest/flutter_map.plugin_api/WMSTileLayerOptions-class.html" %}

{% hint style="success" %}
Omit `urlTemplate` if using WMS tiles. The template is now specified in the `baseUrl` property of `WMSTileLayerOptions`.
{% endhint %}

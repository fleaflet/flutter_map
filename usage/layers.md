# Layers

To display anything on the map, you'll need to include at least one "layer"!

Multiple layers can be used - similar to a `Stack` - each one showing different data in different ways, from actual map tiles ([tile-layer](../layers/tile-layer/ "mention")) to shapes on top of them ([polygon-layer.md](../layers/polygon-layer.md "mention")), and even just your own custom layers ([creating-new-layers.md](../plugins/making-a-plugin/creating-new-layers.md "mention")).

{% content-ref url="broken-reference" %}
[Broken link](broken-reference)
{% endcontent-ref %}

<figure><img src="../.gitbook/assets/ExampleMap.png" alt="A map with multiple overlaid widgets"><figcaption><p>Example <code>FlutterMap</code>, containing a <code>Marker</code>, <code>Polyline</code>, <code>Polygon</code>, and <code>RichAttributionLayer</code></p></figcaption></figure>

Each layer has its own configuration and handling, but can also access the map's state/configuration, as well as be controlled by it.

Layers are usually defined in the `children` property of the `FlutterMap` - as is with the `TileLayer`, for example.&#x20;

However, the `nonRotatedChildren` property can be used for layers which shouldn't move with the map, but still require access to the map's state/configuration - for example, the `AttributionLayer`s.

{% hint style="warning" %}
Do not use `nonRotatedChildren` to enforce a non-rotatable map/`TileLayer`.

Instead, use [#interactivity-settings-interactiveflags](options/other-options.md#interactivity-settings-interactiveflags "mention"). These apply to the entire map and all layers.
{% endhint %}

# Layers

To display anything on the map, you'll need to include at least one layer. This is usually a [`TileLayer`](../layers/tile-layer/), which displays the map tiles themselves: without it, the map isn't really a very good map!

<div align="center" data-full-width="false">

<figure><img src="../.gitbook/assets/ExampleMap.jpg" alt="Example FlutterMap widget, containing multiple feature layers, atop a TileLayer" width="563"><figcaption><p>Example <code>FlutterMap</code> widget, containing multiple feature layers, atop a <code>TileLayer</code></p></figcaption></figure>

</div>

To insert a layer, add it to the `children` property. Other layers (sometimes referred to as 'feature layers', as they are map features) can then be stacked on top, where the last widget in the `children` list is topmost. For example, you might display a [`MarkerLayer`](../layers/marker-layer.md), or any widget as your own custom layer ([creating-new-layers.md](../plugins/making-a-plugin/creating-new-layers.md "mention"))!

{% hint style="info" %}
It is possible to add more than one `TileLayer`! Transparency in one layer will reveal the layers underneath.
{% endhint %}

{% hint style="info" %}
To display a widget in a sized and positioned box, similar to [overlay-image-layer.md](../layers/overlay-image-layer.md "mention"), try the community maintained [flutter\_map\_polywidget plugin](https://github.com/TimBaumgart/flutter\_map\_polywidget)!
{% endhint %}

Each layer is isolated from the other layers, and so handles its own independent logic and handling. However, they can access and modify the internal state of the map, as well as respond to changes.

## Mobile vs Static Layers

Most layers are 'mobile', such as the `TileLayer`. These use a `MobileLayerTransformer` widget internally, which enables the layer to properly move and rotate with the map's current camera.

However, some layers are 'static', such as the [`AttributionLayer`](../layers/attribution-layer.md)s. These aren't designed to move nor rotate with the map, and usually make use of a widget like `Align` and/or `SizedBox.expand` to achieve this.

Both of these layer types are defined in the same `children` list. Most of the time, static layers go atop mobile layers, so should be at the end of the list.

## Layers With Elements

Some layers - such as `PolygonLayer` - take 'elements' - such as `Polygon`s - as an argument, which are then displayed by the layer. They are usually displayed bottom-to-top in the order of the list (like a `Stack`).

{% hint style="info" %}
Since v7, it has not been possible to add elements to layers in an imperative style.

Flutter is a [declarative UI](https://docs.flutter.dev/data-and-backend/state-mgmt/declarative) framework: the UI is a function of the state. It is not necessarily the state's job to change the UI, the state just requests the UI rebuild itself using the new state. Since v7, FM also now mostly follows this convention (although with the exception of the `MapController`, which is a special exception to this rule).

This means that code such as `MarkerLayer.children.add(newElement)` is invalid.

Instead, in this case, a list of the coordinates (and any extra information required to build each `Marker`) should be maintained, then this list used to build a list of `Markers` at build time, for example, by using `List.map` directly in the `MarkerLayer.children` argument.
{% endhint %}

### Hit Testing & Interactivity

Some layers that use elements also support interactivity via hit testing. This is described in more detail on another page:

{% content-ref url="../layers/layer-interactivity/" %}
[layer-interactivity](../layers/layer-interactivity/)
{% endcontent-ref %}

# Layer Interactivity

{% hint style="info" %}
Layer interactivity is different to map interactivity. See [interaction-options.md](../../usage/options/interaction-options.md "mention") to control map interactivity.
{% endhint %}

{% hint style="info" %}
For information about how hit testing behaves in flutter\_map, see [hit-testing-behaviour.md](hit-testing-behaviour.md "mention").

It is important to note that hit testing != interactivity, and hit testing is always executed on interactable layers by default.
{% endhint %}

The following layers are interactable - they have specialised `hitTest`ers and support external hit detection:

* [polyline-layer.md](../polyline-layer.md "mention")
* [polygon-layer.md](../polygon-layer.md "mention")
* [circle-layer.md](../circle-layer.md "mention")

These all follow roughly the same pattern to setup hit detection/interactivity, and there's three or four easy steps to setting it up.&#x20;

## 1. Attach A Hit Notifier

{% hint style="info" %}
Direct callbacks, such as `onTap,`aren't provided on layers or individual elements, to maximize flexibility.
{% endhint %}

Pass a `LayerHitNotifier` to the `hitNotifier` parameter of the layer. The `LayerHitNotifier` should be created as a `ValueNotifier` defaulting to `null`, but strongly typed to `LayerHitNotifier`.

This notifier will be notified whenever a hit test occurs on the layer, with a  `LayerHitResult` when an element (such as a `Polyline` or `Polygon`) within the layer is hit, and with `null` when an element is not hit (but the layer is).

<pre class="language-dart"><code class="lang-dart">final LayerHitNotifier hitNotifier = ValueNotifier(null);

// Inside the map build...
PolylineLayer( // Or any other supported layer
<strong>  hitNotifier: hitNotifier,
</strong>  polylines: [], // Or any other supported elements
);
</code></pre>

It is possible to listen to the notifier directly with `addListener`, if you want to handle all hit events (including, for example, hover events).\
However, most use cases just need to handle particular gestures (such as taps). This can be done with a wrapper widget to 'filter' the events appropriately: [#id-3.-gesture-detection](./#id-3.-gesture-detection "mention").

## 2. Add `hitValue` To Elements

To identify which particular element was hit (which will be useful when handling the hit events in later steps), supported elements have a `hitValue` property.

This can be set to any object, but if one layer contains all the same type, type casting can be avoided (if the type is also specified in the `LayerHitNotifier`'s type argument).

{% hint style="warning" %}
The equality of the element depends on the equality of the `hitValue`.

Therefore, any object passed to the `hitValue` should have a valid and useful equality method.\
Objects such as [records](https://dart.dev/language/records) do this behind the scenes, and can be a good choice to store small amounts of uncomplicated data alongside the element.
{% endhint %}

## 3. Gesture Detection

To only handle certain hits based on the type of gesture the user performed (such as a tap), wrap the layer with a gesture/hit responsive widget, such as `GestureDetector` or `MouseRegion`.&#x20;

These widgets are smart enough to delegate whether they detect a hit (and therefore whether they can detect a gesture) to the child - although `HitTestBehavior.deferToChild` may be required for some widgets to enable this functionality.

This means the layer can report whether it had any form of hit, and the handler widget can detect whether the gesture performed on it actually triggered a hit on the layer below.

```dart
// Inside the map build...
MouseRegion(
  hitTestBehavior: HitTestBehavior.deferToChild,
  cursor: SystemMouseCursors.click, // Use a special cursor to indicate interactivity
  child: GestureDetector(
    onTap: () {
      // Handle the hit, which in this case is a tap
      // For example, see the example in Hit Handling (below)
    },
    // And/or any other gesture callback
    child: PolylineLayer(
      hitNotifier: hitNotifier,
      // ...
    ),
  ),
),
```

## 4. Hit Handling

Once a `LayerHitResult` object is obtained, through the hit notifier, you can retrieve:

* `hitValues`: the `hitValue`s of all elements that were hit, ordered by their corresponding element, first-to-last, visually top-to-bottom
* `coordinate`: the geographic coordinate of the hit location (which may not lie on any element)
* `point`: the screen point of the hit location

{% hint style="success" %}
If all the `hitValue`s in a layer are of the same type, and the created hit notifier specifies that type in the type argument, typing is preserved all the way to retrieval.
{% endhint %}

Because the `HitNotifier` is a special type of `ValueNotifier`, it can be both listened to (like a `Stream`), and its value instantly retrieved (like a normal variable).\
Therefore, there are two ways to retrieve a `LayerHitResult` (or `null`) from the notifier:

* Using `.value` to instantly retrieve the value\
  This is usually done within a gesture handler, such as `GestureDetector.onTap`, as demonstrated below.
* Adding a listener (`.addListener`) to retrieve all hit results\
  This is useful where you want to apply some custom/advanced filtering to the values, and is not a typical usecase.

<pre class="language-dart" data-overflow="wrap"><code class="lang-dart">// Inside a gesture detector/handler

<strong>final LayerHitResult? hitResult = hitNotifier.value;
</strong>if (hitResult == null) return;

// If running frequently (such as on a hover handler), and heavy work or state changes are performed here, store each result so it can be compared to the newest result, then avoid work if they are equal 

for (final hitValue in hitResult.hitValues) {}
</code></pre>

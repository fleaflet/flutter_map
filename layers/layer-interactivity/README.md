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

These all follow roughly the same pattern to setup hit detection/interactivity, and there's three or four easy steps to setting it up.&#x20;

## 1. Attach A Hit Notifier

{% hint style="info" %}
Direct callbacks, such as `onTap,`aren't provided on layers or features, to maximize flexibility.
{% endhint %}

Pass a `LayerHitNotifier` to the `hitNotifier` parameter of the layer. The `LayerHitNotifier` should be created as a `ValueNotifier` defaulting to `null`, but strongly typed to `LayerHitNotifier`.

This notifier will be notified whenever a hit test occurs on the layer, with a  `LayerHitResult` when a feature within the layer is hit, and with `null` when a feature is not hit (but the layer is).

{% code title="hit_notifier.dart" %}
```dart
final LayerHitNotifier hitNotifier = ValueNotifier(null);

// Inside the map build...
PolylineLayer( // Or any other supported layer
  hitNotifier: hitNotifier,
  polylines: [], // Or any other supported feature
);
```
{% endcode %}

It is possible to listen to the notifier directly with `addListener` - don't forget to remove the listener once you no longer need it! Alternatively, you can use another [#id-3.-gesture-detection](./#id-3.-gesture-detection "mention") widget to filter the events appropriately.

## 2. Add `hitValue` To Features

Although this step is technically optional, it's not very useful if you have multiple features if you can't detect which feature has been hit!

To identify features, pass a `hitValue`. This can be any object, but if one layer contains all the same type, type casting can be avoided (if the type is also specified in the `LayerHitNotifier`'s type argument). These objects should have a valid and useful equality method to avoid breaking the equality of the feature.

## 3. Gesture Detection

Events can be 'filtered', to only detect taps or long presses for example, using another gesture/hit responsive widget such as `GestureDetector` or `MouseRegion`. In this case, wrap the layer with other hit detection widgets as you would do normally to detect taps.

{% code title="tappable_polyline.dart" %}
```dart
// Inside the map build...
MouseRegion(
  hitTestBehavior: HitTestBehavior.deferToChild,
  cursor: SystemMouseCursors.click, // Use a special cursor to indicate interactivity
  child: GestureDetector(
    onTap: () {
      // Handle the hit, which in this case is a tap, as below
    },
    onLongPress: () {
      // Handle the hit, which in this case is a long press, as below
    },
    child: PolylineLayer(
      hitNotifier: hitNotifier,
      // ...
    ),
  ),
),
```
{% endcode %}

## 4. Hit Handling

Once a `LayerHitResult` object is obtained, through the hit notifier (either from `.value` inside a gesture detecting widget callback, or from a registered notifier listener callback), you can retrieve:

* `hitValues`: the `hitValue`s of all the features that were hit, ordered by their corresponding feature, first-to-last, visually top-to-bottom
* `coordinate`: the geographic coordinate of the hit location (which may not lie on any feature)
* `point`: the screen point of the hit location

{% hint style="success" %}
If all the `hitValue`s in a layer are of the same type, and the created hit notifier specifies that type in the type argument, typing is preserved all the way to retrieval.
{% endhint %}

{% code title="layer_hit_result.dart" overflow="wrap" %}
```dart
final LayerHitResult? hitResult = hitHandler.value;
if (hitResult == null) return;

// If running frequently (such as on a hover handler), and heavy work or state changes are performed here, store each result so it can be compared to the newest result, then avoid work if they are equal 

for (final hitValue in hitResult.hitValues) {}
```
{% endcode %}

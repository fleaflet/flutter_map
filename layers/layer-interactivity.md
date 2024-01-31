# Layer Interactivity

Some layers, (currently only the [polyline-layer.md](polyline-layer.md "mention")), support hit detection and interactivity. These all follow roughly the same pattern, and there's three or four easy steps to setting it up.

{% hint style="info" %}
To detect hits/interactions on `Markers` in a `MarkerLayer`, simply use a `GestureDetector` or similar widget in the `Marker.child`.
{% endhint %}

{% hint style="info" %}
Direct callbacks on layers or features aren't provided, to maximize flexibility.
{% endhint %}

## 1. Attach A Hit Notifier

Hit detection is achieved by passing a `LayerHitNotifier` to the `hitNotifier` parameter of the layer.\
This will be notified with a `LayerHit` result when a hit is detected on a feature within the layer, and with `null` when a hit is detected on the layer but not on a feature.

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

It is possible to listen to the notifier directly with `addListener` - don't forget to remove the listener once you no longer need it! Alternatively, you can use another [#id-3.-gesture-detection](layer-interactivity.md#id-3.-gesture-detection "mention") widget to filter the events appropriately.

## 2. Add `hitValue` To Features

Hits on features will only be detected on features that have a `hitValue` assigned. This can be used to hold any custom object, but these objects should have a valid and useful equality method to avoid breaking the equality of the feature.

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
* `point`: the geographic coordinate of the hit location (which may not lie on any feature)

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

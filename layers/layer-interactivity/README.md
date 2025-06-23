# Layer Interactivity

{% hint style="info" %}
Layer interactivity is different to map interactivity. See [interaction-options.md](../../usage/options/interaction-options.md "mention") to control map interactivity.
{% endhint %}

The following layers support 'interactivity':

* [polyline-layer.md](../polyline-layer.md "mention")
* [polygon-layer.md](../polygon-layer.md "mention")
* [circle-layer.md](../circle-layer.md "mention")

***

* These layers don't provide their own 'gesture' callbacks, such as `onTap`
* These layers automatically perform [hit testing](#user-content-fn-1)[^1] with Flutter APIs
  * This means layers report hit on elements through the standard Flutter hit system, and can therefore be detected & handled externally through standard widgets: see [#detecting-hits-and-gestures](./#detecting-hits-and-gestures "mention")
  * For advanced information about how flutter\_map hit tests, see [hit-testing-behaviour.md](hit-testing-behaviour.md "mention")
* This may optionally be combined with flutter\_map APIs
  * This allows individual hit elements to be identified externally, through a mechanism of a notifier and element metadata: see [#identifying-hit-elements](./#identifying-hit-elements "mention")

## Detecting hits & gestures

You may be used to using widgets such as `GestureDetector` or `MouseRegion` to detect gestures on other normal widgets. These widgets ask the child to decide whether they were hit, before doing their own logic - e.g. converting the hit to the appropriate callback depending on the gesture.

Because flutter\_map's layers are just widgets, they can also be wrapped with other widgets and inserted into the map's `children`.

This means you can simply wrap layers with `GestureDetector`s (for example) which will execute callbacks when the layer is hit. Layers tell Flutter they were hit _only_ if at least one of their elements (such as a `Polygon`) were hit.

Here's an example of how you would detect taps/clicks on polygons, and convert a cursor to a click indicator when hovering over a polygon:

<pre class="language-dart"><code class="lang-dart">class _InteractivityDemoState extends State&#x3C;InteractivityDemo> {
    Widget build(BuildContext context) {
        return FlutterMap(
            // ...
            children: [
                // ...
<strong>                MouseRegion(
</strong><strong>                    hitTestBehavior: HitTestBehavior.deferToChild,
</strong><strong>                    cursor: SystemMouseCursors.click,
</strong><strong>                    child: GestureDetector(
</strong><strong>                        onTap: () {
</strong><strong>                            // ...
</strong><strong>                        },
</strong>                        child: PolygonLayer(
                            // ...
                        ),
                    ),
                ),
            ],
        );
    }
);
</code></pre>

## Identifying hit elements

To identify which elements (such as `Polygon`s) were hit, flutter\_map APIs are required:

* A `LayerHitNotifier` exposes results of hit tests
* Elements may have metadata known as `hitValue`s attached, which identify that specific element - these are then exposed by the hit notifier's events/values.
* The entire system may be strongly typed through type parameters on various parts, if all the `hitValue`s within a layer share the same type

{% stepper %}
{% step %}
### Create a hit notifier

In your widget, define a new field to hold the notifier:

<pre class="language-dart"><code class="lang-dart">class _InteractivityDemoState extends State&#x3C;InteractivityDemo> {
<strong>    final LayerHitNotifier&#x3C;String> hitNotifier = ValueNotifier(null);
</strong>}
</code></pre>

In this example, the types of the `hitValue` identifiers will be `String`s.

<details>

<summary>(Advanced) Listening to the notifier directly</summary>

If you wish to be notified about all\* hit testing events, you could use the `Listener` widget.

If you need to identify hit elements and don't necessarily need the output of a `Listener`, it's possible to listen to the notifier directly:

<pre class="language-dart"><code class="lang-dart">class _InteractivityDemoState extends State&#x3C;InteractivityDemo> {
    final LayerHitNotifier&#x3C;String> hitNotifier = ValueNotifier(null)
<strong>        ..addListener(() {
</strong><strong>            final LayerHitResult&#x3C;String>? result = hitNotifier.value;
</strong><strong>            // ...
</strong><strong>        });
</strong>}
</code></pre>

This also allows handling of `null` notifier `value`s (results). A `null` result means that the last hit test executed determined there was no hit on the layer at all. Note that the listener's callback is only executed if the previous value was not `null` (i.e. it will not be repeatedly executed for every missed hit).

</details>
{% endstep %}

{% step %}
### Attach the hit notifier to a layer

Pass the notifier to the `hitNotifier` parameter of supported layers. You'll also need to set the type parameter of the layer.

For example, for the `PolygonLayer`:

<pre class="language-dart"><code class="lang-dart">class _InteractivityDemoState extends State&#x3C;InteractivityDemo> {
    Widget build(BuildContext context) {
        return FlutterMap(
            // ...
            children: [
                // ...
<strong>                PolygonLayer&#x3C;String>(
</strong><strong>                    hitNotifier: hitNotifier,
</strong>                    polygons: [
                        // ...
                    ],
                ),
            ],
        );
    }
}
</code></pre>
{% endstep %}

{% step %}
### Add hit values to elements

These can be anything useful, and are exposed when their element is hit. Remember to set the element's type parameter.

<pre class="language-dart"><code class="lang-dart">polygons: [
<strong>    Polygon&#x3C;String>(
</strong>        points: [],
        label: "Horse Field",
<strong>        hitValue: "Horse",
</strong>    ),
<strong>    Polygon&#x3C;String>(
</strong>        points: [],
        label: "Hedgehog House",
<strong>        hitValue: "Hedgehog",
</strong>    ),
    // ...
],
</code></pre>
{% endstep %}

{% step %}
### Detect hits

Follow  <a href="./#detecting-hits-and-gestures" class="button primary" data-icon="arrow-progress">Detecting hits &#x26; gestures</a>.
{% endstep %}

{% step %}
### Handle hits

Once you have a callback (such as the callback to `GestureDetector.onTap`), you can handle individual hit events.

To do this, the notifier exposes events of type `LayerHitResult` when the layer is hit. These results can be retrieved through the notifier's `value` getter:

```dart
final LayerHitResult<String>? result = hitNotifier.value;
```

{% hint style="info" %}
Most users can ignore results which are `null` (when getting the result within a gesture callback, for example).
{% endhint %}

The result exposes 3 properties:

* `hitValues`: the hit values of all elements that were hit, ordered by their corresponding element, first-to-last, visually top-to-bottom
* `coordinate`: the geographic coordinate of the hit location (which may not lie on any element)
* `point`: the screen point of the hit location

Therefore, it's unnecessary to use `MapOptions.on...` in combination with layer interactivity to detect the position of a tap.

Elements without a hit value are not included in `hitValues`. Therefore, it may be empty if elements were hit but no `hitValue`s were defined.
{% endstep %}
{% endstepper %}

## Example

```dart
class _InteractivityDemoState extends State<InteractivityDemo> {
    final LayerHitNotifier<String> hitNotifier = ValueNotifier(null);

    Widget build(BuildContext context) {
        return FlutterMap(
            // ...
            children: [
                // ...
                MouseRegion(
                    hitTestBehavior: HitTestBehavior.deferToChild,
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                        onTap: () {
                            final LayerHitResult<String>? result = hitNotifier.value;
                            if (result == null) return;
                            
                            for (final hitValue in result.hitValues) {
                                print('Tapped on a $hitValue');
                            }
                            print('Eating the grass at ${result.coordinate}');
                        },
                        child: PolygonLayer<String>(
                            hitNotifier: hitNotifier,
                            polygons: [
                                Polygon<String>(
                                    points: [], // overlapping coordinates with 2nd
                                    label: "Horse Field",
                                    hitValue: "Horse",
                                ),
                                Polygon<String>(
                                    points: [], // overlapping coordinates with 1st
                                    label: "Hedgehog House",
                                    hitValue: "Hedgehog",
                                ),
                            ],
                        ),
                    ),
                ),
            ],
        );
    }
);
```

[^1]: Determining whether the position resulting from a pointer event is within one or more elements of the layer, or within the layer at all.

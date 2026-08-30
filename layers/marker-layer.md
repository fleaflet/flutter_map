---
layout:
  width: default
  title:
    visible: true
  description:
    visible: true
  tableOfContents:
    visible: true
  outline:
    visible: true
  pagination:
    visible: true
  metadata:
    visible: true
  tags:
    visible: true
  actions:
    visible: true
---

# Marker Layer

You can add single point features - including arbitrary widgets - to maps using `MarkerLayer` and `Marker`s.

{% hint style="success" %}
No more image only markers! [Unlike _other_ ](https://github.com/flutter/flutter/issues/24213)😉[^1][ popular mapping libraries](https://github.com/flutter/flutter/issues/24213), we allow usage of any widget as the marker.
{% endhint %}

<figure><img src="../.gitbook/assets/Markers Example.png" alt=""><figcaption><p>A variety of <code>Marker</code>s on a rotated map</p></figcaption></figure>

{% embed url="https://pub.dev/documentation/flutter_map/latest/flutter_map/MarkerLayer-class.html" %}

{% embed url="https://pub.dev/documentation/flutter_map/latest/flutter_map/Marker-class.html" %}

```dart
MarkerLayer(
  markers: [
    Marker(
      point: LatLng(30, 40),
      width: 80,
      height: 80,
      child: FlutterLogo(),
    ),
  ],
),
```

{% hint style="warning" %}
Excessive use of markers may create performance issues.

Consider using a clustering plugin to merge nearby markers together, reducing the work that needs to be done when rendering: [#marker-clustering](../plugins/list.md#marker-clustering "mention").
{% endhint %}

## Size

The `height` and `width` parameters are required to enable the positioning and culling of the markers to work correctly.

The marker child will be sized to these parameters, which default to 30 logical pixels. If the child will change size, set the size to the largest size and control the size of the child within a widget which allows it to be smaller than the constraints set.

## Alignment & Counter-Rotation

By default, the marker's child is centered over the `point`, and will always remain upright relative to the North when the map is rotated.

This can be changed using `alignment` and `rotate`.&#x20;

To keep the child upright relative to the screen (counter-rotate it compared to any map rotation), set `rotate` to `true`.

To change the pivot point for the counter-rotation and the alignment of the child to the `point`, set the `alignment` accordingly.

For example:

```dart
Marker(
    rotate: true,
    alignment: Alignment.topCenter,
    // ...
),
```

These parameters can also be set directly on the `MarkerLayer` to change the default for all of its markers.

{% hint style="info" %}
There is no built-in support to rotate markers to a specific degree. However, this is easy to implement through a rotating widget, such as `Transform.rotate`.
{% endhint %}

## Handling State

Often, marker children do not have their own internal state (they are `StatelessWidget`s). However, some use-cases may require them to be stateful.

{% hint style="warning" %}
Markers are culled when they go offscreen, and the marker child is not built when culled. Therefore, any widget state is lost when culling.

When multiple of the same marker is visible at once, across multiple worlds, the marker child is built multiple times. Therefore, the widget states are not synchronized, and any keys in the child subtree may not be unique.
{% endhint %}

Marker children should not be `StatefulWidget`s, and keys should not be used in the child's tree. Instead, the state should be detached and moved up in the tree, using an inherited approach. For example, a state management package, or Flutter's built-in options like `InheritedWidget` or `ValueNotifier` - remember that `FlutterMap.children` can contain widgets wrapped around layers like this.

Then, some map should be kept linking a unique property of the marker (its `point` could be suitable and easily accessed in most dynamic marker layer systems) to its state. The marker child can then lookup this state.

For example:

```dart
children: [
    // TileLayer(), etc...
    
    MyInheritedStateApproach(
        states: <LatLng, MyMarkerState>{
            LatLng(0, 0): MyMarkerState(),
            // These could be dynamically generated from a source,
            // for example using `Map.fromEntries`
        },
        child: MarkerLayer(
            markers: [
                Marker(
                    point: LatLng(0, 0),
                    child: MyMarker(point: LatLng(0, 0)),
                ),
                // These could be dynamically generated from a source,
                // for example using `List.generate`
            ],
        ),
    ),
],

// ...

class MyMarker extends StatelessWidget {
    const MyMarker({
        super.key,
        required this.point,
    });
    
    final LatLng point;
    
    @override
    Widget build(BuildContext context) {
        final MyMarkerState state = MyInheritedStateApproach.of(context).state[point];
        return GestureDetector(
            onTap: () {},
            child: Text(state.label),
        );
    }
}
```

{% hint style="info" %}
The maintainer team is looking into improving the `MarkerLayer` to improve this situation:

* Providing a `keepAlive` option directly on `Marker`s - although this means culled markers still need to be built (although not necessarily painted), which could be expensive compared to the solution above (which requires more boilerplate but should scale better)
* Painting a marker multiple times across worlds while only building it once - although this is fairly complicated, but in combination with the option above could eventually allow the `Marker` size parameters to become unnecessary/optional

Any contributors would be appreciated, although the second point is quite complicated to implement!
{% endhint %}

[^1]: [Google Maps \*wink \*wink](https://github.com/flutter/flutter/issues/24213)

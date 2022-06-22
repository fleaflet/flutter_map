# Attribution Layer

Before publishing your app to users, you should credit the tile server you use, this library, and potentially and plugins you use.

```dart
FlutterMap(
    options: MapOptions(),
    nonRotatedChildren: [
      AttributionWidget.defaultWidget(
        source: 'OpenStreetMap contributors',
        onSourceTapped: () {},
      ),
    ],
),
```

{% hint style="success" %}
Please credit flutter\_map, it helps us to gain more developers that we can help!

You should also credit your tile server if it says to in the server's terms of service. You must credit OpenStreetMap if using it.
{% endhint %}

## Default Builder

The default builder, as shown above, can be used to get a classic attribution box appearance quickly without much setup. Just add a source and a function (if you want a clickable link to appear), and 'flutter\_map' automatically gets credited.

## Custom Builder

Alternatively, create your own box from scratch by omitting the `defaultWidget` constructor from the widget.

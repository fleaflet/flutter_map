# Creating New Layers

Creating a new map layer is just as easy as it is to create a normal `Widget`.

Only one line differs from what you might expect (see below), and this connects the `Widget` to the map. This means that the layer will automatically rebuild when necessary, and it also exposes the `FlutterMapState` to the `Widget`, so you can access current information about the map.

Here's the recommended configuration for a map layer:

```dart
class CustomLayer extends StatelessWidget {
  const CustomLayer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final mapState = FlutterMapState.maybeOf(context)!; // Inherit the map's state
    // Use `mapState` as necessary, for example `mapState.zoom`
  }
}
```

{% hint style="warning" %}
Attempting to use the widget above outside of a `FlutterMap` will result in an error, as the `FlutterMapState` will be inaccessible.
{% endhint %}

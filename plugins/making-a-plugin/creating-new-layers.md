# Creating New Layers

Creating a new map layer is just as easy as it is to create a normal `StatelessWidget` or `StatefulWidget`.

Only one method call is needed to 'connect' the widget to the map state: `FlutterMapState.maybeOf()`. This call does two important things:

* Cause the widget/layer to rebuild automatically when required (if in the `build` method)
* Expose the map's internal state, meaning that it's information (such as zoom) can be accessed

You can see an example of how this is done below:

```dart
class CustomLayer extends StatelessWidget {
  const CustomLayer({super.key});

  @override
  Widget build(BuildContext context) {
    final mapState = FlutterMapState.maybeOf(context)!;
    // Use `mapState` as necessary, for example `mapState.zoom`
  }
}
```

{% hint style="warning" %}
Attempting to use the widget above outside of a `FlutterMap` widget will result in an error.

The `FlutterMapState.maybeOf` method will return `null`, because it cannot locate a parent/inherited state, and therefore cause a null exception.
{% endhint %}

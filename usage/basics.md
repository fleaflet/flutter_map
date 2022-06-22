# The Basics

The main widget for the map is easy to remember. It's just:

```dart
FlutterMap(
    controller: ...
    options: MapOptions(),
    children: [

    ],
),
```

We recommend placing it on it's own page and not restricting it's size, because a map needs to be quite large to display much useful information easily. As such, you won't find a height or width property. If you need to do this, use a `Column()` or `Row()` and place the map under an `Expanded()` widget, or use a `SizedBox()`.

However, if you wanted to show a widget that didn't need to interact with the map (but was related to the map) on top of the map (such as a compass), it would be recommended to place the `FlutterMap()` inside a `Stack()`, and then display that widget over the map in the stack.

It takes three main properties: options, children/layers, and a map controller which you can use to control the map from behind the scenes. These will be described in the following sections.

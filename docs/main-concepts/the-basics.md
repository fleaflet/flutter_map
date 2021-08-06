---
id: the-basics
sidebar_position: 1
---

# The Basics

The main widget for the map is easy to remember. It's just:

``` dart
import 'package:flutter_map/flutter_map.dart';

FlutterMap(
    controller: ...
    options: MapOptions(),
    children: [

    ],
),
```

We recommend placing it on it's own page and not restricting it's size, because a map needs to be quite large to display much useful information easily. As such, you won't find a height or width property. If you need to do this, use a Column() or Row() and place the map under an Expanded() widget, or use a SizedBox().

You should place this widget inside the build method of a stateful widget. However, avoid rebuilding this widget unnecessarily, and wherever possible use a [`MapController`](controller) instead of changing state directly; this won't be possible for changing layer properties however.

It takes three main properties: options, children, and a map controller which you can use to control the map from behind the scenes. These will be described in the following sections.

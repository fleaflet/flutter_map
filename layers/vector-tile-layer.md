---
tags:
  - tag: beta
    primary: true
---

# Vector Tile Layer

flutter\_map considers [vector layer](../why-and-how/how-does-it-work/raster-vs-vector-tiles.md) support as out of scope for the core.

However, flutter\_map's strong community-based ecosystem is continuously developing solutions! Some production apps do use vector with flutter\_map.

{% hint style="warning" %}
The information provided on this page is to the best of our understanding - we have not yet independently verified all of these plugins or our descriptions.

Use community-maintained plugins at your own risk.
{% endhint %}

{% hint style="info" icon="burst-new" %}
There's a lot happening in the flutter\_map ecosystem around vector support right now, and it's becoming more of a viable option for production readiness!&#x20;

Historically, vector support has had major limitations:

* The original vector plugin ('[pkg:(flutter-)vector-map-tiles](https://pub.dev/packages/vector_map_tiles)') struggled to provide performance suitable for production use.
* That plugin has a [beta version](https://github.com/greensopinion/flutter-vector-map-tiles) using [FlutterGPU](https://github.com/flutter/flutter/blob/66b3ad90177ccbd2963836a5556076b370622fe4/docs/engine/impeller/Flutter-GPU.md), showing much improved performance, potentially suitable for production use. However, FlutterGPU is in beta and currently has major limitations.

More recently, two new plugins have been released. We haven't yet tested these independently, but they are very promising!

* '[pkg:mapigrade](https://github.com/greensopinion/mapigrade)' (from the same authors)\
  Allows embedding MapLibre Native layers into the flutter\_map stack without a platform view, mitigating most of the previous issues with this approach.
* '[pkg:flutter\_map\_vector\_tiles](https://pub.dev/packages/flutter_map_vector_tiles)' (from a different author)\
  A re-invented plugin following more conventional approaches.

The maintainer team, and the authors of each plugin, would appreciate your feedback! Let us know on the Discord server or in our GitHub Discussions.

We plan to update this page with more concrete documentation and options once things have cooled a bit and once we've conducted independent testing of these plugins so we can provide a more informed comparison.
{% endhint %}

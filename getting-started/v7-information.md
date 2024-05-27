# v7 Information

{% hint style="success" %}
**v7 should be a pain free upgrade!** Although some breaking changes have been made, most applications shouldn't see any effects or need to make any changes in their code.

For this reason, we have not included migration instructions. If you run into a specific issue, please get in touch on the Discord server, where we'll be happy to help you migrate!
{% endhint %}

{% hint style="success" %}
This update has resolved our oldest open issue: [#385](https://github.com/fleaflet/flutter\_map/issues/385)! We now support hit detection/interactivity on the `PolygonLayer`, `PolylineLayer`, and `CircleLayer`. For more information, check out [layer-interactivity](../layers/layer-interactivity/ "mention").

Additionally, we've been focusing hard on performance improvements, and we've added (in collaboration with the excellent open source community) two stress testing pages to the example application, so you can really strain FM to see how it handles huge datasets. Check out the performance sections of the [polygon-layer.md](../layers/polygon-layer.md "mention") and [polyline-layer.md](../layers/polyline-layer.md "mention") for more information.

The last major change is the introduction of `StrokePattern`: we now support solid, dashed, and dotted lines in all sorts of different arrangements and configurations - again thanks to our community! See [#pattern](../layers/polyline-layer.md#pattern "mention") for more details.

For a curated list of changes, check out our changelog. Alternatively, for a full breakdown, check out the releases and commits on our GitHub repository.
{% endhint %}

{% hint style="warning" %}
v7 supports Flutter 3.22. However, if performing the upgrade to v7 is prohibitive for whatever reason (such as waiting for dependencies to upgrade), but you would like to use Flutter 3.22, we've also released v6.2.1.

v6.2.1 only contains the necessary changes on top of v6.1.0 to support Flutter 3.22, and so we recommend upgrading to v7 to experience all the new functionality and fixes!

_Version 6.2.0 has been retracted from pub.dev. For more information, please see_ [_https://github.com/fleaflet/flutter\_map/pull/1891#issuecomment-2134069848_](https://github.com/fleaflet/flutter\_map/pull/1891#issuecomment-2134069848)_._
{% endhint %}

{% embed url="https://github.com/fleaflet/flutter_map/blob/master/CHANGELOG.md" %}
Full Changelog
{% endembed %}

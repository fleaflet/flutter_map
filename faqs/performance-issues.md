# Performance Issues

{% hint style="success" %}
These issues appear significantly less after v3.0.0, due to the reworking of the internal implementations and public APIs. For more information, see [this comment on GitHub](https://github.com/fleaflet/flutter\_map/issues/1165#issuecomment-1217155883).

If you are experiencing these errors, please consider updating to this version or later.
{% endhint %}

This library does not use native widgets (such as GL), which keeps installation simple and makes the project easier to maintain. However, this does mean performance issues are more likely to appear than some other mapping libraries available for Flutter.

For more information, see  [issue #1165 on GitHub](https://github.com/fleaflet/flutter\_map/issues/1165). If you have any ideas on how to help, please leave a comment or PR: it's greatly appreciated!

If you're having performance issues, there are a few things you can try to help out:

* Reduce the number of extra features on the map, such as `Marker`s and `Polyline`s
* Make full use of plugins, such as clustering plugins

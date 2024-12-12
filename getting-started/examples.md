# Examples

flutter\_map provides an example application showcasing much of its functionality. In some cases, the example app contains undocumented functionality, so it's definitely worth checking out!

## Live Web Demo

{% hint style="info" %}
Note that the web demo is built automatically from the ['master' branch](https://github.com/fleaflet/flutter_map), so may not reflect the the latest release on pub.dev.
{% endhint %}

{% hint style="warning" %}
Please don't abuse the web demo! It runs on limited bandwidth and won't hold up to thousands of loads.

If you're going to be straining the application, please see [#prebuilt-artifacts](examples.md#prebuilt-artifacts "mention"), and serve the application yourself.
{% endhint %}

{% embed url="https://demo.fleaflet.dev" %}

## Prebuilt Artifacts

If you can't build from source for your platform, our GitHub Actions CI system compiles the example app to GitHub Artifacts for Windows, Web, and Android.

The Windows and Android artifacts just require unzipping and installing the .exe or .apk found inside.

The Web artifact requires unzipping and serving, as it contains more than one unbundled file. You may be able to use [dhttpd](https://pub.dev/packages/dhttpd) for this purpose.

{% hint style="info" %}
Note that these artifacts are built automatically from the ['master' branch](https://github.com/fleaflet/flutter_map), so may not reflect the the latest release on pub.dev.
{% endhint %}

{% embed url="https://nightly.link/fleaflet/flutter_map/workflows/master/master" %}
Latest Build Artifacts (thanks [nightly](https://nightly.link/))
{% endembed %}

## Build From Source

If you need to use the example app on another platform, you can build from source, using the 'example' directory of the repository.

{% @github-files/github-code-block url="https://github.com/fleaflet/flutter_map/tree/master/example" %}

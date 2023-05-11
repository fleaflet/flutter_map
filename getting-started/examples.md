# Examples

flutter\_map provides an example application showcasing much of its functionality. In some cases, the example app contains undocumented functionality, so it's definitely worth checking out!

## Build From Source

It's best to build from source for your platform, using the 'example' directory of the repository.

{% embed url="https://github.com/fleaflet/flutter_map/tree/master/example" %}
Example Application Source
{% endembed %}

## Prebuilt Artifacts

If you can't build from source for your platform, our GitHub Actions CI system compiles the example app to GitHub Artifacts for Windows, Web, and Android.

Note that these reflect the latest commits to the 'master' branch - not necessarily the latest release on pub.dev.

The Windows and Android artifacts just require unzipping and installing the .exe or .apk found inside.

The Web artifact requires unzipping and serving, as it contains more than one unbundled file. You may be able to use [dhttpd](https://pub.dev/packages/dhttpd) for this purpose.

{% embed url="https://nightly.link/fleaflet/flutter_map/workflows/main/master" %}
Latest Build Artifacts (thanks [nightly](https://nightly.link/))
{% endembed %}

{% hint style="warning" %}
Note that these artifacts may become unavailable a while, in which case you'll need to build from source.
{% endhint %}

## Web Demo

{% hint style="info" %}
A hosted web demo is coming soon!
{% endhint %}

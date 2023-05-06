---
description: >-
  Mapping package for Flutter, based off of 'leaflet.js'. Simple and easy to
  learn, yet completely customizable and configurable, it's the best choice for
  mapping in your Flutter app.
cover: >-
  https://3967342857-files.gitbook.io/~/files/v0/b/gitbook-x-prod.appspot.com/o/spaces%2FYFI6k92MXbd87FM5cPCk%2Fuploads%2FIkeWyssNqkcXDOHjw3Rn%2FOpenStreetMap%20Screenshot.jpg?alt=media&token=71bbb4f1-75f2-4938-99ca-c1e5af8f5477
coverY: -20.411160058737153
---

# flutter\_map

[![Pub.dev](https://camo.githubusercontent.com/a796d19cced2795c62dee9f3b165665449dbfd0bd46bf39beceef3371f14ebee/68747470733a2f2f696d672e736869656c64732e696f2f7075622f762f666c75747465725f6d61702e7376673f6c6162656c3d4c61746573742b56657273696f6e)](https://pub.dev/packages/flutter\_map) [![points](https://camo.githubusercontent.com/2fe0cefb9f575203da4f29269b9d3a06c0b56b0abca74ba77082849f0f852e93/68747470733a2f2f696d672e736869656c64732e696f2f7075622f706f696e74732f666c75747465725f6d61703f6c6f676f3d666c7574746572)](https://pub.dev/packages/flutter\_map/score) [![likes](https://camo.githubusercontent.com/450afb6eb57ffb0e3cdae61f8a90d51541dbe09eaddcc69900cb09a91762363a/68747470733a2f2f696d672e736869656c64732e696f2f7075622f6c696b65732f666c75747465725f6d61703f6c6f676f3d666c7574746572)](https://pub.dev/packages/flutter\_map/score) \
[![stars](https://camo.githubusercontent.com/7e6d80df311cbd5e68edf6994e404a97af85c84f7ec66614875dba12f055c246/68747470733a2f2f62616467656e2e6e65742f6769746875622f73746172732f666c6561666c65742f666c75747465725f6d61703f6c6162656c3d737461727326636f6c6f723d677265656e2669636f6e3d676974687562)](https://github.com/fleaflet/flutter\_map/stargazers) [![Open Issues](https://camo.githubusercontent.com/3f89334e961516c8b3eef4879a287818a2b8e6523e5f9f8d3767e1d98c8a4f44/68747470733a2f2f62616467656e2e6e65742f6769746875622f6f70656e2d6973737565732f666c6561666c65742f666c75747465725f6d61703f6c6162656c3d4f70656e2b49737375657326636f6c6f723d677265656e)](https://github.com/fleaflet/flutter\_map/issues) [![Open PRs](https://camo.githubusercontent.com/2d48f34537361cf13f775e8c88c5884a7a7b280469b319453b2ccdabdee1f2db/68747470733a2f2f62616467656e2e6e65742f6769746875622f6f70656e2d7072732f666c6561666c65742f666c75747465725f6d61703f6c6162656c3d4f70656e2b50527326636f6c6f723d677265656e)](https://github.com/fleaflet/flutter\_map/pulls)

{% embed url="https://discord.gg/egEGeByf4q" %}
With over 1500 members, our Discord server is the best place to get quick support for simpler questions!
{% endembed %}

## Demonstration

Setting up an interactive and compliant map is simpler than making your lunch-time coffee! It can be accomplished in just over 20 lines, as shown below.

This code snippet demonstrates **everything** you need for a simple map, but of course, FM is capable of much more than just this, and you could find yourself lost in the many options available and possibilities opened!

{% code lineNumbers="true" %}
```dart
@override
Widget build(BuildContext context) {
  return FlutterMap(
    options: MapOptions(
      center: LatLng(51.509364, -0.128928),
      zoom: 9.2,
    ),
    children: [
      TileLayer(
        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        userAgentPackageName: 'com.example.app',
      ),
    ],
    nonRotatedChildren: [
      RichAttributionWidget(
        attributions: [
          TextSourceAttribution(
            'OpenStreetMap contributors',
            onTap: () => launchUrl(Uri.parse('https://openstreetmap.org/copyright')),
          ),
        ],
      ),
    ],
  );
}
```
{% endcode %}

## Feature Highlights

<table data-card-size="large" data-view="cards"><thead><tr><th align="center"></th><th align="center"></th><th data-hidden data-card-cover data-type="files"></th></tr></thead><tbody><tr><td align="center"><strong>Supports any* map style</strong></td><td align="center">We natively support any static raster tile server, including from a web server or even from the local file system or app asset store.<br>No more vendor lock-in!</td><td></td></tr><tr><td align="center"><strong>Stress-free setup</strong></td><td align="center">Migrating from a commercial library such as Google Maps has never been easier! No more complex platform-specific setup, no more API keys: just add a widget and you're done.</td><td></td></tr><tr><td align="center"><strong>Wide ecosystem of plugins</strong></td><td align="center">In the unlikely event that flutter_map doesn't natively contain something you need, just check to see if there's a community maintained plugin that does what you need!</td><td></td></tr><tr><td align="center"><strong>Add other map features</strong></td><td align="center">Add polygons, polylines, and markers/pins to your map easily and quickly. Markers support displaying any widget you might want.</td><td></td></tr></tbody></table>

{% embed url="https://docs.fleaflet.dev/frequently-asked-questions#how-does-flutter_map-compare-to-other-libraries" %}
How does flutter\_map compare to other mapping libraries?
{% endembed %}

## Get Help

If you're not sure where to get help, feel free to ask anywhere, and we'll try to point you in the right direction.

### General Support

If you're not sure how to do something, the best place to get help is on the Discord server! We're here to answer your questions as quickly as possible, so please give us as much information as you can! Please remember that we are volunteers, so we cannot guarantee (fast) support.

Use the link/button at the top of this page, or the link in the footer on all pages to join.

### Bugs & Feature Requests

For suspected bugs or feature requests, visit the issue tracker on GitHub and ask away! We'll try to get back to you relatively quickly, but it may take longer for larger issues.

{% embed url="https://github.com/fleaflet/flutter_map/issues" %}

{% hint style="info" %}
Due to time shortages and other internal matters, wait times for feature request implementations are currently extremely long and may not happen at all.

We'd love to have your contributions to add your own or others' pull requests!
{% endhint %}

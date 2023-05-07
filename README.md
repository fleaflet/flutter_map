---
description: >-
  Mapping package for Flutter, based off of 'leaflet.js'. Simple and easy to
  learn, yet completely customizable and configurable, it's the best choice for
  mapping in your Flutter app.
cover: .gitbook/assets/Cover.png
coverY: -35
---

# flutter\_map

[![Pub.dev](https://camo.githubusercontent.com/a796d19cced2795c62dee9f3b165665449dbfd0bd46bf39beceef3371f14ebee/68747470733a2f2f696d672e736869656c64732e696f2f7075622f762f666c75747465725f6d61702e7376673f6c6162656c3d4c61746573742b56657273696f6e)](https://pub.dev/packages/flutter\_map) [![points](https://camo.githubusercontent.com/2fe0cefb9f575203da4f29269b9d3a06c0b56b0abca74ba77082849f0f852e93/68747470733a2f2f696d672e736869656c64732e696f2f7075622f706f696e74732f666c75747465725f6d61703f6c6f676f3d666c7574746572)](https://pub.dev/packages/flutter\_map/score) [![likes](https://camo.githubusercontent.com/450afb6eb57ffb0e3cdae61f8a90d51541dbe09eaddcc69900cb09a91762363a/68747470733a2f2f696d672e736869656c64732e696f2f7075622f6c696b65732f666c75747465725f6d61703f6c6f676f3d666c7574746572)](https://pub.dev/packages/flutter\_map/score) \
[![stars](https://camo.githubusercontent.com/7e6d80df311cbd5e68edf6994e404a97af85c84f7ec66614875dba12f055c246/68747470733a2f2f62616467656e2e6e65742f6769746875622f73746172732f666c6561666c65742f666c75747465725f6d61703f6c6162656c3d737461727326636f6c6f723d677265656e2669636f6e3d676974687562)](https://github.com/fleaflet/flutter\_map/stargazers) [![Open Issues](https://camo.githubusercontent.com/3f89334e961516c8b3eef4879a287818a2b8e6523e5f9f8d3767e1d98c8a4f44/68747470733a2f2f62616467656e2e6e65742f6769746875622f6f70656e2d6973737565732f666c6561666c65742f666c75747465725f6d61703f6c6162656c3d4f70656e2b49737375657326636f6c6f723d677265656e)](https://github.com/fleaflet/flutter\_map/issues) [![Open PRs](https://camo.githubusercontent.com/2d48f34537361cf13f775e8c88c5884a7a7b280469b319453b2ccdabdee1f2db/68747470733a2f2f62616467656e2e6e65742f6769746875622f6f70656e2d7072732f666c6561666c65742f666c75747465725f6d61703f6c6162656c3d4f70656e2b50527326636f6c6f723d677265656e)](https://github.com/fleaflet/flutter\_map/pulls)

## Demonstration

Setting up an interactive and compliant[^1] map is simpler than making your lunch-time coffee! It can be accomplished in just over 20 lines, as shown below.

This code snippet demonstrates **everything** you need for a simple map, but of course, FM is capable of much more than just this, and you could find yourself lost in the many options available and possibilities opened!

<pre class="language-dart" data-line-numbers><code class="lang-dart">@override
Widget build(BuildContext context) {
  return <a data-footnote-ref href="#user-content-fn-2">FlutterMap</a>(
    options: MapOptions(
      center: LatLng(51.509364, -0.128928),
      zoom: 9.2,
    ),
    <a data-footnote-ref href="#user-content-fn-3">children</a>: [
      TileLayer(
        <a data-footnote-ref href="#user-content-fn-4">urlTemplate:</a> 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        userAgentPackageName: 'com.example.app',
      ),
    ],
    nonRotatedChildren: [
      <a data-footnote-ref href="#user-content-fn-5">RichAttributionWidget</a>(
        attributions: [
          TextSourceAttribution(
            'OpenStreetMap contributors',
            onTap: () => <a data-footnote-ref href="#user-content-fn-6">launchUrl</a>(Uri.parse('https://openstreetmap.org/copyright')),
          ),
        ],
      ),
    ],
  );
}
</code></pre>

## Feature Highlights

<table data-card-size="large" data-view="cards"><thead><tr><th align="center"></th><th align="center"></th><th data-hidden data-card-cover data-type="files"></th></tr></thead><tbody><tr><td align="center"><strong>Supports any* map style</strong></td><td align="center">We natively support any static raster tile server, including from a web server or even from the local file system or app asset store.<br>No more vendor lock-in!</td><td></td></tr><tr><td align="center"><strong>Stress-free setup and use</strong></td><td align="center">Migrating from a commercial library such as Google Maps has never been easier! No more complex platform-specific setup, no more API keys: just add a widget and you're done.</td><td></td></tr><tr><td align="center"><strong>Wide ecosystem of plugins</strong></td><td align="center">In the unlikely event that flutter_map doesn't natively contain something you need, just check to see if there's a community maintained plugin that does what you need!</td><td></td></tr><tr><td align="center"><strong>Add other map features</strong></td><td align="center">Add polygons, polylines, and markers/pins to your map easily and quickly. Markers support displaying any widget you might want.</td><td></td></tr></tbody></table>

<details>

<summary>How does flutter_map compare to other mapping libraries?</summary>

This usually refers to libraries such as 'mapbox\_gl' and 'google\_maps\_flutter'. In some ways, it is better, in some it is worse.

flutter\_map wins on:

* Less vendor lock-in\
  You're not locked into a particular tile server with us - choose from hundreds of options, or build your own!
* Customizability & extensibility\
  Add all sorts of layers to display custom widgets and data on top of your map, and choose from flutter\_map's many community maintained plugins to add even more functionality!
* Ease of use/setup\
  We don't require any API keys or platform specific setup (other than enabling the Internet permission!), so you can get started quicker, and make changes without fear of breaking your release application.
* Support quality and frequency\
  Most questions are answered and resolved within 12-24 hours, thanks to our dedicated maintainers and community.&#x20;

However, alternatives may win on:

* Performance\*\
  flutter\_map's performance is very adequate for the vast majority of applications, and many big businesses use FM to provide maps in their Flutter app.\
  However, if you're using high-thousands of `Markers` or `Polygons` and such like, alternatives may win, purely because they use platform views and GL, and so can do calculations outside of Dart.
* ... and that's pretty much it 😉

</details>

## Get Help

Not quite sure about something? No problem. Please get in touch via any of these methods, and we'll be with you as soon as possible. Please remember that we are volunteers, so we cannot guarantee (fast) support.

{% content-ref url="frequently-asked-questions.md" %}
[frequently-asked-questions.md](frequently-asked-questions.md)
{% endcontent-ref %}

* For bug reports & feature requests: [GitHub Issues](https://github.com/fleaflet/flutter\_map/issues)
* For general support & everything else: [flutter\_map Discord server](https://discord.gg/egEGeByf4q)

{% hint style="info" %}
Due to time shortages and other internal matters, wait times for feature request implementations are currently extremely long and may not happen at all.

We'd love to have your contributions to add your own or others' pull requests!
{% endhint %}

[^1]: (includes necessary attribution)

[^2]: As simple as just another widget...

[^3]: ... but with a whole host of features to display on your map!

[^4]: Connect to any\* map server/provider

[^5]: Stylish attribution required? No problem!

[^6]: _Requires url\_launcher to be installed separately_

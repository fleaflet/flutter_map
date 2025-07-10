# Installation

## Depend On It

Depend on flutter\_map from [pub.dev](https://pub.dev/packages/flutter_map/install) as normal! Use the command line or add the dependency manually to your pubspec.yaml.

```sh
flutter pub add flutter_map latlong2
```

<details>

<summary>Depend from GitHub</summary>

{% hint style="warning" %}
Unreleased commits from the source repo may be unstable.
{% endhint %}

If you urgently need the latest version, a specific branch, or a specific fork, you can use this method.

We recommend depending on us as normal, then adding the following lines to your pubspec, as a new root object:

{% code title="pubspec.yaml" %}
```yaml
dependency_overrides:
    flutter_map:
        git:
            url: https://github.com/fleaflet/flutter_map.git
            # ref: master (or commit hash, branch, or tag)
```
{% endcode %}

</details>

## Platform Configuration

{% hint style="success" %}
Most apps that already communicate over the Internet won't need to change their configuration.
{% endhint %}

{% tabs %}
{% tab title="Android" %}
Add the following line to `android\app\src\main\AndroidManifest.xml` to enable the INTERNET permission in release builds.

<pre class="language-xml"><code class="lang-xml">&#x3C;manifest xmlns:android="http://schemas.android.com/apk/res/android">
    ...
<strong>    &#x3C;uses-permission android:name="android.permission.INTERNET"/>
</strong>    ...
&#x3C;/manifest>
</code></pre>
{% endtab %}

{% tab title="Web" %}
#### Wasm/Renderer

{% hint style="success" %}
We support Wasm! Build and run your app with the '-wasm' flag and benefit from potentially improved performance when the browser can handle Wasm.
{% endhint %}

#### CORS

On the web platform, [CORS ](https://en.wikipedia.org/wiki/Cross-origin_resource_sharing)restrictions designed to protect resources on websites and control where they can be loaded from. Some tile servers may not be intended for external consumption, or may be incorrectly configured, which could prevent tiles from loading. If tiles load correctly on platforms other than the web, then this is likely the cause.

See the [Flutter documentation](https://docs.flutter.dev/platform-integration/web/web-images#cross-origin-resource-sharing-cors) for more details. We load images using a standard `Image` widget.
{% endtab %}

{% tab title="MacOS" %}
Add the following lines to `macos/Runner/Release.entitlements`**:**

<pre class="language-xml"><code class="lang-xml">...
&#x3C;dict>
    ...
<strong>    &#x3C;key>com.apple.security.network.client&#x3C;/key>
</strong><strong>    &#x3C;true/>
</strong>    ...
&#x3C;/dict>
...
</code></pre>
{% endtab %}
{% endtabs %}

{% hint style="info" %}
## Having issues loading tiles?

1. Check you've correctly configured your `TileLayer`: [tile-layer](../layers/tile-layer/ "mention")
2. Check you've followed the steps above for your platform
3. Use Flutter DevTools on native platforms, or the browser devtools on web, and check the HTTP responses of tile requests
4. Try requesting a tile manually using your browser or a command line utility which supports setting any required headers (for example, for authorization)
{% endhint %}

{% hint style="info" %}
## Map looking wrong or layers glitching?

If you're testing on a platform which is using [Impeller](https://docs.flutter.dev/perf/impeller), try running the app without Impeller.

If you're not sure whether you're running with Impeller on mobile (particularly on Android devices where support is patchy), check the first lines of the console output when you run your app in debug mode.

```sh
flutter run --no-enable-impeller
```

If this resolves the issue, unfortunately there's nothing flutter\_map can do. We recommend reporting the issue to the Flutter team, and reaching out to us on the flutter\_map Discord server so we can support reproduction and resolution.

***

If you're running on the web, some features may not work as expected due to limitations or bugs within Flutter. For example, check the [polygon-layer.md](../layers/polygon-layer.md "mention") documentation.
{% endhint %}

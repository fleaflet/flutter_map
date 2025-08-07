# Using OpenStreetMap (direct)

{% hint style="info" %}
This does not apply to users using OpenStreetMap data through other tile servers, only to users using the public OpenStreetMap tile servers directly.
{% endhint %}

{% hint style="danger" %}
## The OSMF[^1] have blocked inadequately identified requests to the public OpenStreetMap tile servers

See [#what-has-osmf-done](using-openstreetmap-direct.md#what-has-osmf-done "mention") & [#what-should-i-do](using-openstreetmap-direct.md#what-should-i-do "mention") if your app has suddenly stopped working.
{% endhint %}

flutter\_map wants to help keep map data available for everyone. One of the largest sources of this data is OpenStreetMap. OpenStreetMap data powers the majority of non-proprietary maps - from actual map tiles/images to navigation data - in existence today. The data itself is free for everyone under the [ODbL](https://opendatacommons.org/licenses/odbl/).

The OpenStreetMap Foundation run OpenStreetMap as a not-for-profit. They also provide a public tile server at [https://tile.openstreetmap.org](https://tile.openstreetmap.org), which is run on donations and volunteering time. This server is used throughout this documentation for code examples, and in our demo app, and is available at the following template URL:

```
https://tile.openstreetmap.org/{z}/{x}/{y}.png
```

{% hint style="warning" %}
## The OpenStreetMap public tile server is NOT free to use by everyone

{% embed url="https://operations.osmfoundation.org/policies/tiles/" %}
OpenStreetMap public tile server usage policy
{% endembed %}

flutter\_map can be setup to conform to these requirements - but it may not conform by default.
{% endhint %}

The OpenStreetMap public tile server is without cost (for users), but, "without cost" ≠ "without restriction" ≠ "open".

## What is flutter\_map doing?

{% hint style="success" %}
## We're adding automatically enabled [caching.md](../layers/tile-layer/caching.md "mention"), available from v8.2 with compatible tile providers

This reduces the strain on tile servers, improves compliance with their policies, and has numerous other benefits for your app!
{% endhint %}

{% hint style="warning" %}
## From v8.2, information will appear in console when a `TileLayer` is loaded using one of the OpenStreetMap tile servers (in debug mode)

Additionally, where an appropriate User-Agent header (which identifies your app to the server) is not set - for example, through `TileLayer.userAgentPackageName`, or directly through the tile provider's HTTP headers configuration - a warning will appear in console (in debug mode), advising you to set a UA.
{% endhint %}

## What has OSMF done?

{% hint style="danger" %}
## Requests to the public OpenStreetMap tile servers from User-Agents which are not properly set have been blocked

Due to excessive usage, the OpenStreetMap Foundation have blocked requests with one of the following configurations:

* No specified `TileLayer.userAgentPackageName` (recommended setup) & no manually specified "User-Agent" header
* `userAgentPackageName` set to <kbd>'com.example.app'</kbd> (or equivalent manual config)

This does not apply to web users, who cannot set a User-Agent different to what is provided by the browser.

See [https://github.com/fleaflet/flutter\_map/issues/2123#issuecomment-3062197581](https://github.com/fleaflet/flutter_map/issues/2123#issuecomment-3062197581) for more information.

To restore access, follow [#what-should-i-do](using-openstreetmap-direct.md#what-should-i-do "mention").
{% endhint %}

## Why?

The OpenStreetMap tile server is NOT free to use by everyone.

[Data collected by OSM](https://planet.openstreetmap.org/tile_logs/) on 2025/06/09 shows flutter\_map as the largest single user-agent in terms of the average number of tile requests made per second over the day. Whilst it is true that there are multiple user agents smaller who make up an overall much larger portion of total usage - for example, leaflet.js's usage is split across the browsers' user-agents, as is flutter\_map usage on the web - the usage of flutter\_map cannot be ignored.

The top 7 user-agents are shown below, in order (with traffic rounded to the nearest whole tile). ('Missed' tiles are those which required fresh rendering, and are more expensive than most other requests.)

<table><thead><tr><th width="518">User-Agent</th><th width="120">tiles/second</th><th width="110">"missed" t/s</th></tr></thead><tbody><tr><td><mark style="background-color:green;"><strong>flutter_map (*)</strong></mark><br><em>This represents the</em> <a data-footnote-ref href="#user-content-fn-2"><em>majority</em></a> <em>of FM users on non-web platforms.</em></td><td>1610</td><td>53</td></tr><tr><td>Mozilla/5.0 QGIS/*</td><td>1155</td><td>358</td></tr><tr><td>Mozilla/5.0 ...</td><td>476</td><td>33</td></tr><tr><td>com.facebook.katana</td><td>263</td><td>3</td></tr><tr><td><mark style="background-color:green;"><strong>Dart/* (dart:io)</strong></mark><br><em>This represents FM users on older versions (not on web) &#x26; other Flutter mapping libraries not using FM (not on web).</em></td><td>182</td><td>17</td></tr><tr><td>Mozilla/5.0 ...</td><td>175</td><td>6</td></tr><tr><td>Mozilla/5.0 ...</td><td>171</td><td>14</td></tr></tbody></table>

And looking in more detail at the User-Agent's making up the primary 'flutter\_map (\*)' agent, on 2025/05/28:

<table><thead><tr><th width="580">Specific User-Agent</th><th>Daily tile requests</th></tr></thead><tbody><tr><td>flutter_map (<strong>unknown</strong>)<br><em>This represents users failing to use <code>TileLayer.userAgentPackageName</code>.</em> </td><td>99,258,371</td></tr><tr><td>flutter_map (<strong>com.example.app</strong>)<br><em>This is likely a combination of users copy-pasting from the docs &#x26; personal projects.</em></td><td>7,808,777</td></tr><tr><td>flutter_map (<strong>dev.fleaflet.flutter_map.example</strong>)<br><em>This is likely a combination of users using the Demo app (primarily), and users copy-pasting from the example app.</em></td><td>6,402,576</td></tr><tr><td><em>Next largest User-Agent is an adequately identified app</em></td><td><em>3,953,312</em></td></tr></tbody></table>

We are extremely proud to see flutter\_map being used so much! At the same time, we are aware that there are many users placing a potential strain on OpenStreetMap, which we want to minimize:

* We do not want to discourage legitimate use-cases from using the OpenStreetMap tile servers
* We want to help users who may be accidentally or unknowingly breaking the OpenStreetMap usage policies adjust their project so they can continue to benefit from cost-free tiles
* However, we do wish to discourage illegitimate use-cases or users who are intentionally breaking the OpenStreetMap usage policies

Therefore, we are introducing measures to force users to read the OpenStreetMap Tile Usage Policy before allowing them to use the servers in release builds:

* This is easy for legitimate users who have already read the policy and follow it
* It helps users accidentally breaking the policies to see why it's so important to follow them, and what they can do to fix any issues
* It adds friction for users intentionally breaking the policies

{% hint style="warning" %}
Ultimately however, it is your own responsibility to comply with any appropriate restrictions and requirements set by your chosen tile server/provider. Always read their Terms of Service. Failure to do so may lead to any punishment, at the tile server's discretion.
{% endhint %}

## What should I do?

{% stepper %}
{% step %}
### Consider switching tile servers

Our docs list multiple alternatives, many of which have free tiers suitable for hobbyists, affordable pricing for commercial usage, and one which is extremely flexible.

Most of these are built off the same OpenStreetMap data, so the actual information contained within the map won't change (although a change in style may not show some data).

If you're a commercial user and want the best balance of flexibility and affordability, consider setting up your own private tile server, based on the OpenStreetMap data! In any case, the OpenStreetMap tile server doesn't offer uptime guarantees, which may be important to your business.

If you're sticking with OpenStreetMap's server, consider preparing a backup.
{% endstep %}

{% step %}
### Read the OpenStreetMap Tile Usage Policy

If you still want to use OpenStreetMap, you must read the policy and comply with its restrictions and requirements. It also contains some background info as to why this is important.

{% embed url="https://operations.osmfoundation.org/policies/tiles/" %}
OpenStreetMap public tile server usage policy
{% endembed %}

To note two important general terms:

> Should any users or patterns of usage nevertheless cause problems to the service, access may still be blocked without prior notice.

> This policy may change at any time subject to the needs and constraints of the project. Commercial services, or those that seek donations, should be especially aware that access may be withdrawn at any point: you may no longer be able to serve your paying customers if access is withdrawn.

Also note all the other requirements, which may require you to make adjustments to your project...
{% endstep %}

{% step %}
### Make all necessary adjustments

Check the OSM policy for all the adjustments you might need to make. Here's some common ones:

*   **Enable conforming caching**

    {% hint style="success" %}
    v8.2.0 introduces automatically enabled [caching.md](../layers/tile-layer/caching.md "mention")! This is designed to meet the caching requirements of the usage policy. Upgrade to v8.2.0 to enable this functionality.
    {% endhint %}

    There's also other options to implement [#caching](offline-mapping.md#caching "mention") to meet the requirements, and go beyond the capabilities of the built-in caching.
*   **Add sufficient attribution**

    {% hint style="success" %}
    The `RichAttributionWidget` or `SimpleAttributionWidget` can both be used to setup attribution which looks great, is unintrusive, and is conforming - provided you add the necessary sources. See [attribution-layer.md](../layers/attribution-layer.md "mention") for more info and a simple code snippet you can add to meet the attribution requirement.
    {% endhint %}

    You can also add attribution in any other way that meets the requirements.
*   **Set a more specific user-agent to identify your client**

    {% hint style="success" %}
    flutter\_map provides its own user-agent on native platforms, but this isn't enough to meet the requirements. You should set `TileLayer.userAgentPackageName`: see the [#recommended-setup](../layers/tile-layer/#recommended-setup "mention") for the `TileLayer`.\
    This is not necessary when running solely on the web, where it is not possible to set a User-Agent manually.
    {% endhint %}
{% endstep %}

{% step %}
### Disable the console messages

We show a console message as a reminder and reference if you're using the servers, even if you're in compliance. You can disable this info - if flutter\_map implements further blocks in future, this may also disable those.

{% hint style="warning" %}
This will not disable any blocks enforced by the OpenStreetMap foundation.
{% endhint %}

To do this, set the `flutter.flutter_map.unblockOSM` environment variable when building/running/compiling. Use the `dart-define` flag to do this.

To evidence that you've read and understood the tile policy, you should set it to the exact string (excluding any surrounding whitespace, including all other punctuation) following the phrase from the policy:

> OpenStreetMap data is free for everyone to use. **\_\_\_\_\_**

For example, to run the project:

```sh
flutter run --dart-define=flutter.flutter_map.unblockOSM="_____"
```

You can also add this to your IDE's configuration to automatically pass this argument when running from your IDE. For example, in VS Code:

{% code title=".vscode/launch.json" %}
```json
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "app",
            "request": "launch",
            "type": "dart",
            "args": [
                "--dart-define",
                "flutter.flutter_map.unblockOSM=_____" // no inner quotes
            ]
        }
    ]
}
```
{% endcode %}
{% endstep %}
{% endstepper %}

## I have more questions

If you've got a question or comment regarding this new policy, or if you think we've missed something, please reach out to us on Discord (or via GitHub Discussions).

[^1]: OpenStreetMap Foundation (the operators of the tile server)

[^2]: Some users may use an entirely custom User-Agent. Most users using FMTC are not included.

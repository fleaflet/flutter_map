---
hidden: true
noIndex: true
---

# ⚠️ Using OpenStreetMap (direct)

{% hint style="info" %}
This does not apply to users using OpenStreetMap data through other tile servers, only to users using the public OpenStreetMap tile servers directly.
{% endhint %}

.flutter\_map wants to help keep map data available for everyone. One of the largest sources of this data is OpenStreetMap. OpenStreetMap data powers the majority of non-proprietary maps - from actual map tiles/images to navigation data - in existence today. The data itself is free for everyone under the [ODbL](https://opendatacommons.org/licenses/odbl/).

The OpenStreetMap Foundation run OpenStreetMap as a not-for-profit. They also provide a public tile server at [https://tile.openstreetmap.org](https://tile.openstreetmap.org). This server is used throughout this documentation for code examples, and in our demo app.

{% hint style="warning" %}
The OpenStreetMap tile server is NOT free to use by everyone.
{% endhint %}

{% embed url="https://operations.osmfoundation.org/policies/tiles/" %}
OpenStreetMap Tile Usage Policy
{% endembed %}

Tile servers require complex management and expensive hardware. OpenStreetMap's tile servers are run entirely on donations.

## What is flutter\_map doing?

{% hint style="warning" %}
From v8.2.0, warnings will appear in console when a `TileLayer` is loaded using one of the OpenStreetMap tile servers.
{% endhint %}

{% hint style="danger" %}
## A near-future non-major version of flutter\_map will block all tiles from these servers in release/profile builds by default

In debug mode, the console warning will be changed.

_The exact date of this version's release is to-be-confirmed, but will be a minimum of 30 days from the release of v8.2.0._
{% endhint %}

The maintainers and community are also actively looking into ways to improve compliance by default:

* Introducing automatic basic caching into the core\
  This will likely massively reduce the number of tile requests and improve app performance (at the expense of consuming storage space)
* Checking for adequate and stable HTTP/2 & HTTP/3 support (HTTP/2 is already used on web)
* Making an attribution to OpenStreetMap the default

## Why are we doing this?

The OpenStreetMap tile server is NOT free to use by everyone.

[Data collected by OSM](https://planet.openstreetmap.org/tile_logs/) on 2025/04/08 shows flutter\_map as the second largest 'whole' user-agent in terms of the average number of tile requests made per second over the day. Whilst it is true that there are multiple user agents smaller who make up an overall much larger portion of total usage - for example, leaflet.js's usage is split across the browsers' user-agents, as is flutter\_map usage on the web - the usage of flutter\_map cannot be ignored.

The top 10 user-agents are shown below, in order.

<table><thead><tr><th width="575">User-Agent</th><th data-type="number">Tiles/second</th></tr></thead><tbody><tr><td>Mozilla/5.0 QGIS/*</td><td>1958.78</td></tr><tr><td><mark style="background-color:green;"><strong>flutter_map (*)</strong></mark><br><em>This represents the</em> <a data-footnote-ref href="#user-content-fn-1"><em>majority</em></a> <em>of FM users on non-web platforms. <code>*</code> represents the <code>TileLayer.userAgentPackageName</code>.</em></td><td>1414.97413</td></tr><tr><td>Mozilla/5.0 ...</td><td>375.2936227</td></tr><tr><td>Mozilla/5.0 ...</td><td>302.7196412</td></tr><tr><td><mark style="background-color:green;"><strong>Dart/* (dart:io)</strong></mark><br><em>This represents FM users on older versions &#x26; other Flutter mapping libraries not using FM.</em></td><td>209.9140856</td></tr><tr><td>Mozilla/5.0 ...</td><td>203.3502431</td></tr><tr><td>Mozilla/5.0 ...</td><td>175.8431366</td></tr><tr><td>Mozilla/5.0 ...</td><td>162.7784028</td></tr><tr><td>Mozilla/5.0 ...</td><td>126.3630556</td></tr><tr><td>com.facebook.katana</td><td>99.72585648</td></tr></tbody></table>

We are extremely proud to see flutter\_map being used so much! At the same time, we are aware that there are many users placing a potential strain on OpenStreetMap.

> We do not want to discourage legitimate use-cases from using the OpenStreetMap tile servers.
>
> We want to help users who may be accidentally or unknowingly breaking the OpenStreetMap usage policies adjust their project so they can continue to benefit from cost-free tiles.
>
> However, we do wish to discourage illegitimate use-cases or users who are intentionally breaking the OpenStreetMap usage policies.

Therefore, we are introducing measures to force users to read the OpenStreetMap Tile Usage Policy before allowing them to use the servers in release builds.&#x20;

> This is easy for legitimate users who have already read the policy and follow it.
>
> It helps users accidentally breaking the policies to see why it's so important to follow them, and what they can do to fix any issues.
>
> It adds friction to users intentionally breaking the policies.

{% hint style="warning" %}
Ultimately however, it is your own responsibility to comply with any appropriate restrictions and requirements set by your chosen tile server/provider. Always read their Terms of Service. Failure to do so may lead to any punishment, at the tile server's discretion.
{% endhint %}

This policy is completely unrelated to the OpenStreetMap Foundation, and was the sole collective decision of the maintainers.

## What should I do?

{% stepper %}
{% step %}
### Consider switching tile servers

Our docs list multiple alternatives, many of which have free tiers suitable for hobbyists, affordable pricing for commercial usage, and one which is extremely flexible.

Most of these are built off the same data, so the actual information contained within the map won't change (although a change in style may not show some data).

If you're a commercial user and want the best balance of flexibility and affordability, consider setting up your own private tile server! In any case, the OpenStreetMap tile server doesn't offer uptime guarantees, which may be important to your business.
{% endstep %}

{% step %}
### Read the OpenStreetMap Tile Usage Policy

If you still want to use OpenStreetMap, you must read the policy and comply with its restrictions and requirements. It also contains some background info as to why this is important.

{% embed url="https://operations.osmfoundation.org/policies/tiles/" %}
OpenStreetMap Tile Usage Policy
{% endembed %}

To note,

> Should any users or patterns of usage nevertheless cause problems to the service, access may still be blocked without prior notice.

If your project uses a very large number of tiles, even if it would otherwise meet the requirements, consider switching to a different server.
{% endstep %}

{% step %}
### Make all necessary adjustments

{% hint style="warning" %}
By default, flutter\_map does NOT meet all of the requirements. We are actively looking into ways to improve compliance without further action from users.
{% endhint %}

One common adjustment on non-web platform is to introduce caching. This step alone reduces the number of requests massively. There are currently 2 plugins designed to offer the functionality, and it's easy to create your own. See [#caching](offline-mapping.md#caching "mention") for more info.

Another is attribution. There are built-in attribution widgets to make this easy: see [attribution-layer.md](../layers/attribution-layer.md "mention") for more info.

You should also check you've set `TileLayer.userAgentPackageName`.
{% endstep %}

{% step %}
### Re-enable the OpenStreetMap tile servers

If you're eligible to use the servers, you can re-enable them in release mode and disable the console warnings in debug mode.

To do this, set the <kbd>flutter.flutter\_map.unblockOSM</kbd> environment variable when building/running/compiling. Use the `dart-define` flag to do this.

To evidence that you've read and understood the tile policy, you should set it to the exact string (excluding any leading or trailing whitespace, including all other punctuation) following the phrase from the policy:

> OpenStreetMap data is free for everyone to use. **\_\_\_\_\_**

For example, to run the project:

```sh
flutter run --dart-define=flutter.flutter_map.unblockOSM="_____"
```

You can also add this to your IDE's configuration to automatically pass this argument when running from your IDE.
{% endstep %}
{% endstepper %}

## I have more questions

If you've got a question or comment regarding this new policy, or if you think we've missed something, please reach out to us.&#x20;

The best way to do this is on the dedicated GitHub issue, or on the Discord server.

[^1]: Some users may use an entirely custom User-Agent. Most users using FMTC are not included.

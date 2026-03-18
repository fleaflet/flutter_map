# Using OpenStreetMap (direct)

{% hint style="info" %}
This does not apply to users using OpenStreetMap data through other tile servers, only to users using the public OpenStreetMap tile servers directly.
{% endhint %}

{% hint style="danger" %}
## On non-web platforms, the inadequately identified requests to the public OpenStreetMap tile servers are blocked

Due to excessive usage, requests where the 'User-Agent' header is inadequately set have been blocked by the OpenStreetMap Foundation (who operate the tile servers).

The UA can be set through the `TileLayer.userAgentPackageName` argument (or manually).

**If this is either unspecified or set to a generic string (like 'com.example.app'), then requests will return a** [**blocked tile**](https://wiki.openstreetmap.org/wiki/Blocked_tiles)**.**

This does not apply to the web, where the UA cannot be set differently to what is provided by the browser.

To restore access, follow [#what-should-i-do](using-openstreetmap-direct.md#what-should-i-do "mention").
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

It is your own responsibility to comply with any appropriate restrictions and requirements set by your chosen tile server/provider. Always read their Terms of Service. Failure to do so may lead to any punishment, at the tile server's discretion.
{% endhint %}

The OpenStreetMap public tile server is without cost (for users), but, "without cost" ≠ "without restriction" ≠ "open".

<details>

<summary>Why has unidentified traffic been blocked?</summary>

[Data collected by OSM](https://planet.openstreetmap.org/tile_logs/) on 2025-06-09 shows flutter\_map as the largest single user-agent in terms of the average number of tile requests made per second over the day.

Whilst it is true that there are multiple user agents smaller who make up an overall much larger portion of total usage - for example, leaflet.js's usage is split across the browsers' user-agents, as is flutter\_map usage on the web - the usage of flutter\_map cannot be ignored.

The top 7 user-agents are shown below, in order (with traffic rounded to the nearest whole tile). ('Missed' tiles are those which required fresh rendering, and are more expensive than most other requests.)

<table><thead><tr><th width="453.3333740234375">User-Agent</th><th width="120">tiles/second</th><th width="110">"missed" t/s</th></tr></thead><tbody><tr><td><mark style="background-color:green;"><strong>flutter_map (*)</strong></mark><br><em>This represents the</em> <a data-footnote-ref href="#user-content-fn-1"><em>majority</em></a> <em>of FM users on non-web platforms.</em></td><td>1610</td><td>53</td></tr><tr><td>Mozilla/5.0 QGIS/*</td><td>1155</td><td>358</td></tr><tr><td>Mozilla/5.0 ...</td><td>476</td><td>33</td></tr><tr><td>com.facebook.katana</td><td>263</td><td>3</td></tr><tr><td><mark style="background-color:green;"><strong>Dart/* (dart:io)</strong></mark><br><em>This represents FM users on older versions (not on web) &#x26; other Flutter mapping libraries not using FM (not on web).</em></td><td>182</td><td>17</td></tr><tr><td>Mozilla/5.0 ...</td><td>175</td><td>6</td></tr><tr><td>Mozilla/5.0 ...</td><td>171</td><td>14</td></tr></tbody></table>

Looking at data revealed on 2025-05-28, the vast majority of daily tile requests (more than 99 million) came from unidentified apps using flutter\_map. Nearly 8 million came from apps using the 'com.example.app' identifier (which is inadequate), and around 6.5 million came from apps copying the example app's identifier (which caused OSM to block that identifier as well).

</details>

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

    <div data-gb-custom-block data-tag="hint" data-style="success" class="hint hint-success"><p>v8.2.0 introduces automatically enabled <a data-mention href="../layers/tile-layer/caching.md">caching.md</a>! This is designed to meet the caching requirements of the usage policy. Upgrade to v8.2.0 to enable this functionality.</p></div>

    There's also other options to implement caching or offline mapping to meet the requirements, and go beyond the capabilities of the built-in caching.
*   **Add sufficient attribution**

    <div data-gb-custom-block data-tag="hint" data-style="success" class="hint hint-success"><p>The <code>RichAttributionWidget</code> or <code>SimpleAttributionWidget</code> can both be used to setup attribution which looks great, is unintrusive, and is conforming - provided you add the necessary sources. See <a data-mention href="../layers/attribution-layer.md">attribution-layer.md</a> for more info and a simple code snippet you can add to meet the attribution requirement.</p></div>

    You can also add attribution in any other way that meets the requirements.
*   **Set a more specific user-agent to identify your client**

    <div data-gb-custom-block data-tag="hint" data-style="success" class="hint hint-success"><p>You should set <code>TileLayer.userAgentPackageName</code>: see the <a data-mention href="../layers/tile-layer/#recommended-setup">#recommended-setup</a> for the <code>TileLayer</code>.<br>This is not necessary when running solely on the web, where it is not possible to set a User-Agent manually.</p></div>
{% endstep %}
{% endstepper %}

[^1]: Some users may use an entirely custom User-Agent. Most users using FMTC are not included.

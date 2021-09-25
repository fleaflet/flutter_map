---
id: go
sidebar_position: 1
---

# Getting Started

:::danger Unofficial Documentation
This documentation is currently being written and should not be used unless directed. It's contents may have not yet been verified, and therefore certain parts may be factually incorrect, incomplete, or otherwise misleading. You should not raise issues about documentation in the issue tracker, unless otherwise directed. Ignore any instructions within these docs to report issues.

For all documentation, use the official README at [https://github.com/fleaflet/flutter_map](https://github.com/fleaflet/flutter_map), until further notice.

_This is a temporary notice_
:::

`flutter_map` is a mapping package for Flutter, based off of 'leaflet.js'. Simple and easy to learn, yet completely customizable and configurable, it's the best choice for mapping in your Flutter app.

[![Pub](https://img.shields.io/pub/v/flutter_map.svg)](https://pub.dev/packages/flutter_map) [![likes](https://badges.bar/flutter_map/likes)](https://pub.dev/packages/flutter_map/score) [![pub points](https://badges.bar/flutter_map/pub%20points)](https://pub.dev/packages/flutter_map/score)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[![CI](https://github.com/fleaflet/flutter_map/workflows/Tests/badge.svg?)](https://github.com/fleaflet/flutter_map/actions?query=branch%3Amaster) [![GitHub stars](https://img.shields.io/github/stars/fleaflet/flutter_map.svg?label=Stars)](https://GitHub.com/fleaflet/flutter_map/stargazers/) [![GitHub issues](https://img.shields.io/github/issues/fleaflet/flutter_map.svg?label=Issues)](https://GitHub.com/fleaflet/flutter_map/issues/) [![GitHub PRs](https://img.shields.io/github/issues-pr/fleaflet/flutter_map.svg?label=Pull%20Requests)](https://GitHub.com/fleaflet/flutter_map/pulls/)

<hr></hr>

:::note Version 0.13.1
This documentation applies to the version of `flutter_map`: 0.13.1, and some content may not apply to older versions. If the version number (<) is less than the latest version available on pub.dev ([![Pub](https://img.shields.io/pub/v/flutter_map.svg)](https://pub.dev/packages/flutter_map)), the documentation may not have been changed, in which case it should still apply.

If you are migrating from an older major version of `flutter_map`, there have likely been breaking changes. See the [Migration guides](/migration/to-v0.13.1) for more information.
:::

## Installation

### From pub.dev

This is the recommended method of installing this package as it ensures you only receive stable versions, and you can be sure pub.dev is reliable. It also keeps the size of your pubspec.yaml small.
Just import the package as you would normally, from the command line:

``` shell
    > flutter pub add flutter_map
```

:::tip Auto Install
This should automatically import the latest version of the package, create an entry for it in your 'pubspec.yaml' file, and run `flutter pub get`.

Otherwise follow the old method and add the latest version of the 'flutter_map' dependency to the 'pubspec.yaml' file manually, then update the dependencies.
:::

### From github.com

Only use this method if you haven't used the recommended method above. If you urgently need the latest version, a specific branch, or a specific fork, you should use this method.

:::caution
Be warned that this means any bugs that get through may get through to you immediately. It may also cause conflicts with other packages that depend on flutter_map.
:::

Add the following lines to your 'pubspec.yaml' file under the 'dependencies' section:

``` yaml
    flutter_map:
        git:
            url: https://github.com/fleaflet/flutter_map.git
```

If you need to use a specific branch, you can use this method, and add the following line beneath the 'url' field (at the same indentation):

``` yaml
            ref: <branch-name>
```

You can also use this method to reference your a fork of the project, just change the 'url' to the appropriate repo.

### Setup on Android

On Android, additional setup may be required.
To access the Internet to reach tile servers, ensure your app is configured to use the INTERNET permission. Check (if necessary add) the following lines in the manifest file located at/android/app/src/main/AndroidManifest.xml:

``` xml
<uses-permission android:name="android.permission.INTERNET"/>
```

You may also need to do this in any other applicable manifests, such as the debug one, if not already in there.

### Import & Start Coding

Importing the package to use in your code is as usual as well, but an extra import is recommended (you won't need to add this extra package to your 'pubspec.yaml' file, `flutter_map` exports it automatically for you). Just add these lines to the top every file to do with the map, and you'll have access to everything you need:

``` dart
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
```

:::tip Start Coding
The rest of this documentation will take you through what most developers need to know to setup an advanced `flutter_map` experience for their users.

However, not every detail of `flutter_map`'s extensive functionality can be documented here. So, to help you with all of the public APIs, check-out the [Full API Reference](https://pub.dev/documentation/flutter_map/latest/flutter_map/flutter_map-library.html) available at any time in the sidebar/navbar, and also while you code in your favourite IDE.
:::

## Support & Contact

Having trouble with `flutter_map`? Check the [Full API Reference](https://pub.dev/documentation/flutter_map/latest/flutter_map/flutter_map-library.html) first to see if you can spot your issue, otherwise visit [StackOverflow](https://stackoverflow.com/search?q=flutter_map) or the [GitHub Issue Tracker](https://github.com/fleaflet/flutter_map/issues), and ask away! The community will try to get back to you as soon as possible.

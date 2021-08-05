---
id: getting-started
sidebar_position: 1
---

# Getting Started

:::danger Unofficial Documentation
This documentation is currently being written and should not be used unless directed. It's contents may have not yet been verified, and therefore certain parts may be factually incorrect, incomplete, or otherwise misleading. You should not raise issues about documentation in the issue tracker, unless otherwise directed. Ignore any instructions within these docs to report issues.

For all documentation, use the official README at https://github.com/fleaflet/flutter_map, until further notice.
:::

`flutter_map` is a mapping package for Flutter, based off of 'leaflet.js'. Simple and easy to learn, yet completely customizable and configurable, it's the best choice for Flutter if Google Maps isn't your target map.

[![Pub](https://img.shields.io/pub/v/flutter_map.svg)](https://pub.dev/packages/flutter_map) [![likes](https://badges.bar/flutter_map/likes)](https://pub.dev/packages/flutter_map/score) [![pub points](https://badges.bar/flutter_map/pub%20points)](https://pub.dev/packages/flutter_map/score)
[![CI](https://github.com/fleaflet/flutter_map/workflows/Tests/badge.svg?)](https://github.com/fleaflet/flutter_map/actions?query=branch%3Amaster) [![GitHub stars](https://img.shields.io/github/stars/fleaflet/flutter_map.svg?label=Stars)](https://GitHub.com/fleaflet/flutter_map/stargazers/) [![GitHub issues](https://img.shields.io/github/issues/fleaflet/flutter_map.svg?label=Issues)](https://GitHub.com/fleaflet/flutter_map/issues/) [![GitHub PRs](https://img.shields.io/github/issues-pr/fleaflet/flutter_map.svg?label=Pull%20Requests)](https://GitHub.com/fleaflet/flutter_map/pulls/)

## Installation

### From pub.dev

This is the recommended method of installing this package as it ensures you only receive stable versions, and you can be sure pub.dev is reliable. It also keeps the size of your pubspec.yaml small.
Just import the package as you would normally, from the command line:

``` shell
    > flutter pub add flutter_map
```

:::tip Auto Install
This should automatically import the latest version of the package and create an entry for it in your 'pubspec.yaml' file. Otherwise follow the old method and add the latest version of the 'flutter_map' dependency to the pubspec.yaml manually.
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

### Import

Importing the package to use in your code is as usual as well. Just add this to the top of your file and you'll have access to everything you need:

``` dart
import 'package:flutter_map/flutter_map.dart';
```

You don't even need to create a special instance!

## Support & Contact

Having trouble with `flutter_map`? Visit [StackOverflow](https://stackoverflow.com/search?q=flutter_map) or the [GitHub Issue Tracker](https://github.com/fleaflet/flutter_map/issues), and ask away! The community will try to get back to you as soon as possible.

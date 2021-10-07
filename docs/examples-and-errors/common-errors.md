---
id: common-errors
sidebar_position: 3
---

# Common Errors

Due to the complex internal structure and composition of `flutter_map`, maps with controllers and maps using other 'advanced' features, are unfortunately prone to small, albeit annoying, errors - particularly after the null safety update v0.13.0. These errors are either:

- a consequence of many rushed changes, and as such, are well hidden away throughout the library
- a consequence of bad documentation
- a potential problem with your code (may be because of a mixture of the above)

This page aims to cover some of the more common errors you may encounter.

## `LateInitializationError`

Often happens with maps using controllers. This error is usually not your fault, and comes about because the library was expecting a value that hasn't been created yet. This is rife with controllers because of the semi-`Future`-based implementation that sometimes works and sometimes doesn't.

Should you find an error like this, use these steps:

1. Define and assign the controller like in the example on [the Controller page](../main-concepts/controller)
2. Use `MapController.onReady` inside a `FutureBuilder` wrapped around the map widget (this should fix most issues with the map controller)
3. Look through the [issues page on GitHub for error/bug reports related to `LateInitializationError`](https://github.com/fleaflet/flutter_map/issues?q=is%3Aissue+LateInitializationError)
4. If you didn't find an already opened/closed issue that worked, open a new issue
5. If you think you can fix it, [see the Contributing page](../miscellaneous/contributing)

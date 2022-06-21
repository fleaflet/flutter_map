# Common Issues

Due to the complex internal structure and composition of 'flutter\_map', maps with controllers and maps using other 'advanced' features, are unfortunately prone to small, albeit annoying, errors - particularly after the null safety update v0.13.0. These errors are either:

* a consequence of many rushed changes, and as such, are well hidden away throughout the library
* a consequence of bad documentation
* a potential problem with your code (may be because of a mixture of the above)

This page aims to cover some of the more common errors you may encounter.

## `LateInitializationError`

Often happens with maps using controllers. This error is usually not your fault, and comes about because the library was expecting a value that hasn't been created yet. This is rife with controllers because of the semi-`Future`-based implementation that sometimes works and sometimes doesn't.

Should you find an error like this, use these steps:

1. Define and assign the controller like in the example on the Controller page
2. Use `MapController.onReady` inside a `FutureBuilder` wrapped around the map widget (this should fix most issues with the map controller)
3. Look through the [issues page on GitHub for error/bug reports related to `LateInitializationError`](https://github.com/fleaflet/flutter\_map/issues?q=is%3Aissue+LateInitializationError)
4. If you didn't find an already opened/closed issue that worked, open a new issue
5. If you think you can fix it, see the Contributing page

## Performance Issues

'flutter\_map' does not use any platform specific code. This is intended to make your development experience easier and more seamless, by reducing setup/installation time and complexity.\
However, this means that some of the more complicated calculations are slower than other libraries.

We're slowly tracking and resolving these issues: see [issue #1165 on GitHub](https://github.com/fleaflet/flutter\_map/issues/1165). Please bear with us whilst we do this: maintainer efforts are stretched at the moment.

If you have any ideas on how to help, please leave a comment: it's greatly appreciated!

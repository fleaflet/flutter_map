# To v1.0.0

This documentation was partially written during this update's lifetime.

Some breaking changes were implemented. Notably:

* `placeholderImage` was deprecated with no replacement or workaround. Remove it from your code before the next major release.
* Some streams were changed from `Stream<Null>` to `Stream<void>`. These changes are simple to reflect in your code should you need to.

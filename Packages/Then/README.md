# Then

An updated version of the original [Then](https://github.com/devxoul/Then).

New features include:

* All functions are now annotated with `@inline(__always)` to force SwiftC to inline all calls, resulting in minimal performance differences between using and not using Then
* All functions are now annotated with `@discardableResult` to make Xcode shut up
* The `withIf`, `doIf`, and `thenIf` functions are now available
* The `let` idiom is now introduced (Kotlin programmers, rejoice!)
* A new initializer-based syntax for `then` is now available on any `NSObject` (must be manually applied by extending from `ThenInitializer`)
* `do` returns `T` now (similar to `let`; pick your poison)

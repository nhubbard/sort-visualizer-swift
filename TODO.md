# TODO List

## General

* [x] Migrate manual layout engine to use HStack with alignment bottom and no spacing
* [x] Wire up array size and delay changes
* [x] Separate algorithm implementations into separate files
* [x] Clean up any dead code from prior changes
* [x] Make sure that stopping an in-progress sort functions as expected
* [x] Make sure operations counter is updated by all algorithms
* [ ] Implement step functionality, possibly using delay as a catalyst?
* [ ] Write lots of tests for everything in the app
* [ ] Set up Prettier to keep algorithm example code properly formatted
* [ ] Set up a testing system that validates algorithm example code results

## Algorithms

* [x] Implement and validate all algorithms:
  * [x] Quick Sort
  * [x] Merge Sort
  * [x] Heap Sort
  * [x] Bubble Sort
  * [x] Selection Sort
  * [x] Insertion Sort
  * [x] Gnome Sort
  * [x] Shaker Sort
  * [x] Odd-Even Sort
  * [x] Pancake Sort
  * [x] Bitonic Sort
  * [x] Radix Sort
  * [x] Shell Sort
  * [x] Comb Sort
  * [x] Bogo Sort
  * [x] Stooge Sort
    
## Visualization Improvements

* [x] Merge Sort: Still not stopping correctly... my fault again, trying to get merge sort to actually work correctly.
* [x] Merge Sort: Mark the previous comparison for each group.
* [x] Selection Sort: Clear green items for each iteration, it looks really weird
* [x] Shell Sort: Not incrementing operation counter correctly

## Audio

* [x] Replace custom implementation with AudioKit
* [x] Wire up audio capabilities in all operations
* [ ] Start up and shut down the synthesizer automatically to prevent popping and other audio weirdness∑

## User Interface

* [x] Icons in navigation
* [x] Add warning to Bogo Sort
* [x] Add transparency to Settings panel
* [ ] *Big project:* Enhance sort algorithm pages with descriptions of algorithms, big-O notation values, and implementation code for various languages
  * [x] Create initial concept
  * [x] Implement description
  * [x] Implement big-O values
  * [x] Implement top 10 programming language examples for QuickSort as test
  * [ ] Implement top 10 programming language examples for all other algorithms
    * [x] Merge Sort
    * [x] Heap Sort
    * [x] Bubble Sort
    * [x] Selection Sort
    * [x] Insertion Sort
    * [x] Gnome Sort
    * [x] Shaker Sort
    * [ ] Odd-Even Sort
    * [ ] Pancake Sort
    * [ ] Bitonic Sort
    * [ ] Radix Sort
    * [ ] Shell Sort
    * [ ] Comb Sort
    * [ ] Bogo Sort
    * [ ] Stooge Sort
* [ ] String resources/localization for all strings throughout the app.
* [ ] Settings panel that allows you to change various defaults, like the sound tuning, note range, and more settings.
* [ ] Replace homepage content with Wikipedia text for "Sorting algorithm". Only necessary for localization purposes.

## Future Ideas from WWDC 2022

*Warning:* These features won't be available until Swift 5.7 becomes a *usable* beta (not this kinda-usable but also not usable at all custom toolchain crap I have to deal with right now) and we switch to targeting iPadOS 16/macOS Ventura beta for the SwiftUI 4 changes. I'd be on the bleeding edge, and might get cut.

* [ ] Regex literals, regex builders, and other enhancements!
  * Praise be to the Apple gods! They must have read my mind with all of the annoying frustrations I've been dealing with...
* [ ] Grid API for SwiftUI 4
  * Could alleviate performance concerns for the code views, unless I implement some kind of cacheing in the ScrollingSortView.
  * For now, the plan is to introduce some kind of caching.
* [ ] Swift Charts for SwiftUI 4
  * Could we replace our custom grid type, while magically introducing animations? We'll see...
* [ ] Navigation API for SwiftUI 4
  * I will not implement this until I retarget the app to iPadOS 16/macOS Ventura, since the old navigation components are deprecated in these releases.

## Far-Out Ideas

* [ ] Reimplement the entire Pygments stack in Swift to reduce preprocessing and assets size?
  * Could call it something like `PygmentsUI` or whatnot. Sounds like a **not** fun project.
  * *Project update:* Currently abandoned. I was sinking an insane amount of time into directly porting Pygments to Swift. I would probably re-architect it to make it more reasonable and easier to use if I were to proceed forward.
* [ ] Reimplement iosMath in Swift because I really want to?
  * Could call it something like `MathUI`. Sounds like a less fun project because Objective-C bad.
  * Swiftify is really expensive too, so I would have to do a manual conversion process, or complete the entire conversion process within their free limits (super annoying)
* [ ] Rewrite selected packages, since they haven't been frequently updated and will probably break in Swift 5.7/SwiftUI 4
  * [x] CollectionConcurrencyKit
  * [ ] MarkdownUI
* [ ] Allow for data collection for ensuring that algorithms always finish sorting correctly?
  * App tracking transparency, server spinups, data collection apparatus, etc. are going to be difficult. That's why this is a far-out idea.

## BizDev

* [ ] Implement Apple crash reporting (if I have to do anything)
* [ ] Implement StoreKit
  * I've settled on between a $1.99 and $4.99 one-time purchase, with an education discount of 50% if desired.

# TODO List

## General

* [x] Migrate manual layout engine to use HStack with alignment bottom and no spacing
* [x] Wire up array size and delay changes
* [x] Separate algorithm implementations into separate files
* [x] Clean up any dead code from prior changes
* [x] Make sure that stopping an in-progress sort functions as expected
* [x] Make sure operations counter is updated by all algorithms
* [ ] Implement step functionality, if possible
* [ ] Write lots of tests for everything

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

* [ ] Merge Sort: Mark the previous comparison for each group
* [ ] Merge Sort: Create a visualization for copying from cache array
* [ ] Selection Sort: Clear green items for each iteration, it looks really weird
* [ ] Radix Sort: Might need to adjust the nanoseconds delay to 10 or 100 instead of 1, it might cause seizures otherwise 😬
* [ ] Shell Sort: Why does it repeat the process multiple times after the sort is finished?
* [ ] Bogo Sort: Might add a modified bogo sort, which only randomizes the segments that aren't in order, or maybe moves one item to the correct position and randomizes the rest of the array every 50K operations? idk.

## Audio

* [x] Replace custom implementation with AudioKit
* [x] Wire up audio capabilities in all operations
* [ ] Start up and shut down the synthesizer automatically to prevent popping and other audio weirdness

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
* [ ] Set up Prettier to keep algorithm example code properly formatted
* [ ] Set up a testing system that validates algorithm example code results
* [ ] String resources/localization for all strings throughout the app.
* [ ] Settings panel that allows you to change various defaults, like the sound tuning, note range, and more settings.

## Future Ideas from WWDC 2022

*Warning:* These features won't be available until Swift 5.7 enters actual, usable beta and we switch to targeting iPadOS 16/macOS Ventura beta for the SwiftUI 4 changes. Also, doing that will require that the absolute latest versions of iPadOS and macOS are required. I'd be on the bleeding edge, and might get cut.

* [ ] Regex literals, regex builders, and other enhancements!
  * Praise be to the Apple gods! They must have read my mind with all of the annoying frustrations I've been dealing with...
  * Sounds awesome in theory, but will conflict with the Regex module.
* [ ] Grid API for SwiftUI 4
  * Could alleviate performance concerns for the code views, unless I implement some kind of cacheing in the ScrollingSortView.
* [ ] Swift Charts for SwiftUI 4
  * Could we replace our custom grid type, while magically introducing animations?
  * We'll see!
* [ ] Navigation API for SwiftUI 4
  * I will not implement this until I retarget the app to iPadOS 16/macOS Ventura, since the old navigation components are deprecated in these releases.

## Far-Out Ideas

* [ ] Reimplement the entire Pygments stack in Swift to reduce preprocessing and assets size?
  * Could call it something like `PygmentsUI` or whatnot. Sounds like a really fun project.
  * It hasn't been a fun project so far. Regex is driving me insane, and this isn't going to get any easier until Swift 5.7 is actually usable.
* [ ] Reimplement iosMath in Swift because I really want to?
  * Could call it something like `MathUI`. Sounds like a less fun project because Objective-C bad.
  * Swiftify is really expensive too, so I would have to do a manual conversion process, or complete the entire conversion process within their free limits (super annoying)
* [ ] Rewrite MarkdownUI, CollectionConcurrencyKit, Then, and maybe the Regex module, since they haven't been frequently updated and will probably break in Swift 5.7/SwiftUI 4

## BizDev

* [ ] Implement Apple crash reporting (if I have to do anything)
* [ ] Implement StoreKit
  * I've settled on between a $1.99 and $4.99 one-time purchase, with an education discount of 50% if desired.

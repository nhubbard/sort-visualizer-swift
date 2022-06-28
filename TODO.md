# TODO List

## General

* [x] Migrate manual layout engine to use HStack with alignment bottom and no spacing
* [x] Wire up array size and delay changes
* [x] Separate algorithm implementations into separate files
* [x] Clean up any dead code from prior changes
* [x] Make sure that stopping an in-progress sort functions as expected
* [x] Make sure operations counter is updated by all algorithms
* [x] Add error to bitonic sort if the array size isn't a power of 2
* [x] *Urgent:* Rewrite CodeView to use AttributedString instead of a reduce operation.
  * This is what was causing the crashes on mom's iPad. It was overflowing the stack with too many variables.
* [ ] Implement step functionality, possibly using delay as a catalyst?
* [ ] Unit testing and UI testing
  * I tried doing unit testing with a protocol and a separate implementation in the unit tests target, but it just... failed over and over and over again.
* [ ] Set up Unibeautify to keep algorithm example code properly formatted
* [x] Set up a testing system that validates algorithm example code results

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
* [x] Start up and shut down the synthesizer automatically to prevent popping and other audio weirdness

## User Interface

* [x] Icons in navigation
* [x] Add warning to Bogo Sort
* [x] Add transparency to Settings panel
* [x] Fix jumping on Scrolling Sort View
  * The issue was the LazyVGrid. Replacing it with a really ugly VStack+HStack combo eliminated the problem.
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
    * [x] Odd-Even Sort
    * [x] Pancake Sort
    * [x] Bitonic Sort
    * [x] Radix Sort
    * [x] Shell Sort
    * [x] Comb Sort
    * [ ] Bogo Sort
    * [ ] Stooge Sort
* [ ] Add copy/paste floating button to AttributedCodeView
* [ ] String resources/localization for all strings throughout the app.
* [ ] Settings panel that allows you to change lots of options
  * Synthesizer: note range, attack, decay, sustain, release
  * Sort view: auto-enable sound, default delay, default array size, array size range
  * Bogo sort: disable bogo sort prompt
  * Bitonic sort: disable bitonic sort warning
* [ ] Replace homepage content with Wikipedia text for "Sorting algorithm". Only necessary for localization purposes.

## Future Ideas from WWDC 2022

*Warning:* These features won't be available until Swift 5.7 becomes a *usable* beta (not this kinda-usable but also not usable at all custom toolchain crap I have to deal with right now) and we switch to targeting iPadOS 16/macOS Ventura beta for the SwiftUI 4 changes. I'd be on the bleeding edge, and might get cut.

* [ ] Regex literals, regex builders, and other enhancements!
  * Praise be to the Apple gods! They must have read my mind with all of the annoying frustrations I've been dealing with...
* [ ] Swift Charts for SwiftUI 4
  * Could we replace our custom sorting rectangles implementation, while magically introducing animations? We'll see...
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

## BizDev

* [ ] Implement Apple crash reporting (if I have to do anything)
* [ ] Implement StoreKit
  * I've settled on between a $1.99 and $4.99 one-time purchase, with an education discount of 50% if desired.

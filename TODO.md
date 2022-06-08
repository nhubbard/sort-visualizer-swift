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
        * [ ] Shaker Sort
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

* [ ] Regex literals, builders, and other enhancements! Praise be to the Apple gods, they must have read my mind!
* [ ] New Grid API for Code Previews... this is a game changer for my use case!
* [ ] New Swift Charts API!
* [ ] All-new *Typed* Navigation System for SwiftUI!

## Far-Out Ideas

* [ ] Reimplement the entire Pygments stack in Swift to reduce preprocessing and assets size?
    * Could call it something like `PygmentsUI` or whatnot. Sounds like a really fun project.
    * It hasn't been a fun project so far. Regex is driving me insane, and this isn't going to get any easier.
    * Fun fact: Apple must have read my mind, because Swift is apparently gaining a regex literal and several convenience features for regex support in v5.7 (can't use it yet because there's an AudioKitEX bug 😢)
* [ ] Reimplement iosMath in Swift because I really want to?
    * Could call it something like `MathUI`. Sounds like a less fun project because Objective-C bad.
    * Swiftify is really expensive too, so I would have to do a manual conversion process, or complete the entire conversion process within their free limits (super annoying)

## BizDev and Analytics

* [ ] Implement Crashlytics
    * This is really important, but will also necessitate app tracking transparency, privacy policy, terms and conditions, and more otherwise unnecessary content because Apple demands it.
* [ ] Implement StoreKit
    * I've settled on between a $1.99 and $4.99 one-time purchase, with an education discount of 50% if desired.

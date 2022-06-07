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
        * [ ] Bubble Sort
        * [ ] Selection Sort
        * [ ] Insertion Sort
        * [ ] Gnome Sort
        * [ ] Shaker Sort
        * [ ] Odd-Even Sort
        * [ ] Pancake Sort
        * [ ] Bitonic Sort
        * [ ] Radix Sort
        * [ ] Shell Sort
        * [ ] Comb Sort
        * [ ] Bogo Sort
        * [ ] Stooge Sort
* [ ] String resources for all strings throughout the app. Sounds like a pain in the butt to do...
* [ ] Settings panel that allows you to change various defaults, like the sound tuning, or the lowest and highest notes.    

## Future Ideas from WWDC 2022

* [ ] Regex literals, builders, and other enhancements! Praise be to the Apple gods, they must have read my mind!
* [ ] New Grid API for Code Previews... this is a game changer for my use case!
* [ ] New Swift Charts API!

## Far-Out Ideas

* [ ] Reimplement the entire Pygments stack in Swift to reduce preprocessing and assets size?
    * Could call it something like `PygmentsUI` or whatnot. Sounds like a really fun project.
    * It hasn't been a fun project so far. Regex is driving me insane, and this isn't going to get any easier.
    * Fun fact: Apple must have read my mind, because Swift is apparently gaining a regex literal and several convenience features for regex support soon!
* [ ] Reimplement iosMath in Swift because I really want to?
    * Could call it something like `MathUI`. Sounds like a less fun project because Objective-C bad.
    * Swiftify is really expensive too, so I would have to do a manual conversion process... 😳

## External Services (Crash Reporting, Monetization)

* [ ] Implement Crashlytics
* [ ] Implement StoreKit: either a $0.99/month subscription, or a one-time purchase (~$5)

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

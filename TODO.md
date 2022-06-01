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
        * [x] Quick Sort
        * [ ] Merge Sort
        * [ ] Heap Sort
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

## Far-Out Ideas

* [ ] Reimplement the entire Pygments stack in Swift to reduce preprocessing and assets size?
    * Could call it something like `PygmentsUI` or whatnot. Sounds like a really fun project.
* [ ] Reimplement iosMath in Swift because I really want to?
    * Could call it something like `MathUI`. Sounds like a less fun project because Objective-C bad.
    * Swiftify is really expensive too, so I would have to do a manual conversion process... 😳
    
## External Services (Ads, Crash Reporting)

* [ ] Implement crash reporting
    * Crashlytics?
* [ ] Implement advertisements
    * *Pro:* Automatic passive revenue
    * *Con:* Privacy policy and stuff
* [ ] If implementing advertisements, implement in-app purchase using StoreKit (App Store) and/or Paddle (Self-Distribution)
    * Allows users to opt-out of advertisements and not give up their private information

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

# TODO List

## General

* [x] Migrate manual layout engine to use HStack with alignment bottom and no spacing
* [x] Wire up array size and delay changes
* [x] Separate algorithm implementations into separate files
* [x] Clean up any dead code from prior changes
* [ ] Make sure that stopping an in-progress sort functions as expected
    * [ ] Merge Sort: No longer crashes, but warning dialog does not appear as expected.
* [x] Make sure operations counter is updated by all algorithms
    * [x] Merge Sort
    * [x] Radix Sort

## Audio

* [x] Replace custom implementation with AudioKit
* [x] Wire up audio capabilities in all operations
    * [x] Radix Sort

## User Interface

* [ ] Add warning to Bogo Sort
* [ ] Enable user to collapse Settings panel
* [ ] Add transparency to Settings panel
* [ ] Replace Step button with Record functionality; maybe use [SwiftUIViewRecorder](https://github.com/frolovilya/SwiftUIViewRecorder) as an example
* [ ] Enhance sort algorithm pages with descriptions of algorithms, big-O notation values, and implementation code for various languages

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

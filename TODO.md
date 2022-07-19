# TODO List

## General

* [x] Migrate manual layout engine to use HStack with alignment bottom and no spacing
* [x] Wire up array size and delay changes
* [x] Separate algorithm implementations into separate files
* [x] Clean up any dead code from prior changes
* [x] Make sure that stopping an in-progress sort functions as expected
* [x] Make sure operations counter is updated by all algorithms
* [x] Add error to bitonic sort if the array size isn't a power of 2
* [x] Rewrite CodeView to use AttributedString instead of a reduce operation.
  * This is what was causing the crashes on Mom's iPad. It was overflowing the stack with too many variables.
* [ ] Unit testing and UI testing
  * I tried doing unit testing with a protocol and a separate implementation in the unit tests target, but it just... failed over and over and over again.
  * This may necessitate creating a brand-new Xcode project with tests enabled by default, copying all of the files and settings from the old project, and working from there. Ugh.
* [x] Set up a testing system that validates algorithm example code results
* [x] Replace manual JSON parsing with Decodable

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

### Completed

* [x] Icons in navigation
* [x] Add warning to Bogo Sort
* [x] Add transparency to Settings panel
* [x] Fix jumping on Scrolling Sort View
  * The issue was the LazyVGrid. Replacing it with a really ugly VStack+HStack combo eliminated the problem.
* [x] *Big project:* Enhance sort algorithm pages with descriptions of algorithms, big-O notation values, and implementation code for various languages
  * [x] Create initial concept
  * [x] Implement description
  * [x] Implement big-O values
  * [x] Implement top 10 programming language examples for QuickSort as test
  * [x] Implement top 10 programming language examples for all other algorithms
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
* [x] Make code copyable and wrapped to container size.
  * Copy: Dead simple!
  * Wrapping: Not so simple. If I try to make it happen, it just... doesn't work as expected.
* [x] Replace simple text in complexity with a WKWebView (wrapped in a UIViewRepresentable) and MathJax, using LaTeX syntax.
  * Following [this guide](https://tiborsimon.io/articles/programming/ios-mathjax-integration/), but modernizing the code by using WKWebView instead of UIWebView. 
  * Alternatively, if the information can be made into a constant, we can render every equation to an SVG file and display it that way. It might be faster in-app, but it will also involve a lot of tooling.
  * *Rant:* I've given up on rewriting iosMath for modern Swift and/or SwiftUI. It's *heavily* bound to very old (OS X El Capitan/iOS 9 era) APIs that have long since been deprecated, and doesn't appear to be actively maintained. Swiftify got my business once, and their software did an excellent job converting the project, but there's too much work to do in order to modernize the library, like type-safe reading of font configuration tables (which I rewrote the generation script for the latest versions of Python), and so many more issues that just can't be fixed.
  
### In Progress

* [ ] Branding and general customization
  * [ ] App icon
  * [x] About dialog (see Shared/Resources/Credits.rtf)
* [ ] Translation/localization
  * [ ] Replace homepage content with Wikipedia text for "Sorting algorithm".
  * [ ] String resources/localization for all strings throughout the app.
  * [ ] Add copyright and license attribution for Wikipedia-sourced content.
* [ ] Settings Panel
  * [ ] First things first: type-safe configuration lookup is an absolute requirement. We might be able to accomplish this using SwiftUI's awesome "environment" dependency injection.
  * [ ] Synthesizer
    * [ ] Note range (use piano control from AudioKitUI, see Cookbook app for examples)
    * [ ] Attack, decay, sustain, release (use freq curve control from AudioKitUI, see Cookbook app for examples)
  * [ ] Sort view
    * [ ] Default sound to on or off (toggle)
    * [ ] Default delay (slider and/or input box)
    * [ ] Default array size (slider and/or input box)
    * [ ] Array size range for normal algorithms (slider and/or input box, result should auto update the default array size constraints)
    * [ ] Code view themes (combo box of some kind)
    * [ ] Code font size (slider, will have to constrain because otherwise we have to resize views)
      * This may also prompt us to actually implement a tabbed view for code, so that we don't have to deal with grids.
    * [ ] Shuffle/generation method?
      * [ ] Random shuffle
      * [ ] Ascending
      * [ ] Descending
      * [ ] Shuffled Cubic
      * [ ] Shuffled Quintic
      * [ ] Shuffled n-2 Equal
  * [ ] Bogo sort
    * [ ] Disable bogo sort warning prompt
  * [ ] Bitonic sort
    * [ ] Disable bitonic sort warning
* [ ] Expand the counters from just "Operations" to the standard set of metrics (array accesses, inversions, reversals, etc.)
* [ ] Add more sorting algorithms? Port them from Gaming32/ArrayV, if possible.
* [x] Add a timer
* [ ] Finally implement step functionality, possibly using delay as a catalyst

## Future Ideas from WWDC 2022

*Warning:* These features won't be available until Swift 5.7 becomes a *usable* beta (not this kinda-usable but also not usable at all custom toolchain crap I have to deal with right now) and we switch to targeting iPadOS 16/macOS Ventura beta for the SwiftUI 4 changes. I'd be on the bleeding edge, and might get cut.

* [ ] Swift Charts for SwiftUI 4
  * [ ] Attempt to use as a replacement for SortView; probably won't work very well, but we won't know until we try it out.
  * [ ] Attempt to add complexity graphs to the ScrollingSortView.
* [ ] Navigation API for SwiftUI 4
  * I will not implement this until I retarget the app to iPadOS 16/macOS Ventura, since the old navigation components are deprecated in these releases.
  * It's also completely different and involves some weird magic that isn't documented yet.
* [ ] ScreenCaptureKit for Record functionality?
  * Looks like exactly what I was looking for with regards to implementing recording functionality.

## Far-Out Ideas

* [ ] Rewrite MarkdownUI, since it hasn't been frequently updated and will probably break in Swift 5.7/SwiftUI 4
* [ ] Implement Fastlane or similar build tooling
* [ ] Implement SwiftLint for build-time code checking

## BizDev

* [ ] Implement Apple crash reporting (if I have to do anything)
* [ ] Implement StoreKit
  * I've settled on between a $1.99 and $4.99 one-time purchase, with an education discount of 50% if I can implement it.
  * Before doing this, make sure to apply to the Apple Small Business program so I only have to pay 15% commissions.
  * I'm okay with the high commission, since I don't want to deal with the absolute hell that is third-party payment systems.

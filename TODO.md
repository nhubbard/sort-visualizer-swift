# TODO List

## General

* [ ] Unit testing and UI testing
  * I tried doing unit testing with a protocol and a separate implementation in the unit tests target, but it just... failed over and over and over again.
  * This may necessitate creating a brand-new Xcode project with tests enabled by default, copying all of the files and settings from the old project, and working from there. Ugh.
* [ ] **Potential performance improvement:** Instead of using an observable list to update the UI, have the sorting algorithm put operations into a queue, and then "replay" them into the UI. Would work wonders for performance for everything except high *n* BogoSort, and also enable step functionality without having to completely rewrite delay handling.

## User Interface
  
### In Progress

* [x] Branding and general customization
  * [x] App icon
  * [x] About dialog (see Shared/Resources/Credits.rtf)
* [x] Settings Panel (use new SwiftUI 4 forms interface)
  * [x] First things first: type-safe configuration lookup is an absolute requirement. We might be able to accomplish this using SwiftUI's awesome "environment" dependency injection.
  * [x] Synthesizer
    * [x] Default to on or off (toggle)
    * [x] Note range (use piano control from AudioKitUI? see Cookbook app for examples)
    * [x] Amplitude, attack, decay, sustain, release (use freq curve control from AudioKitUI, see Cookbook app for examples)
  * [x] Sort view
    * [x] Default delay (slider and/or input box)
    * [x] Default array size (slider and/or input box)
    * [x] Default timer to formatted interval or seconds (toggle?)
    * [x] Code view themes (combo box of some kind)
    * [x] Shuffle/generation method (implementation in SortItem.swift and Shuffle.swift in progress)
      * [x] Random shuffle
      * [x] Ascending
      * [x] Descending
      * [x] Shuffled Cubic
      * [x] Shuffled Quintic
  * [x] Disable bogo sort warning prompt
  * [x] Disable bitonic sort warning
  * [x] Fix layout of settings on Mac Catalyst
  * [x] Make the settings actually apply to the application!
* [ ] Expand the counters from just "Operations" to the standard set of metrics (array accesses, inversions, reversals, etc.)

### Not Started/Future Plans

* [ ] Make navigation three-tiered? Allows for more categories.
* [ ] Add more sorting algorithms? Port them from Gaming32/ArrayV, if possible.
* [ ] Finally implement step functionality, possibly using delay as a catalyst
  * Commented out step functionality with v1.1 to reduce confusion. The code is still there, but the button is not rendered.

## Future Ideas from WWDC 2022+

* [ ] Use Swift Charts to add complexity graphs to the ScrollingSortView.
* [x] Collect up to 10 samples of every size of the algorithms (with the exception of Bogo Sort and Stooge Sort) and place them on the complexity graphs relative to the known size
* [ ] Implement either ScreenCaptureKit or serialized operation recording functionality

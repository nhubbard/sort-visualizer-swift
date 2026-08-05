[Insertion sort](https://en.wikipedia.org/wiki/Insertion_sort) grows a sorted prefix one element at a
time: on each step, the next element is located within the sorted prefix and moved into place, and
every element between the old and new positions is shifted over by one to make room. That shifting is
where the ordinary algorithm spends almost all of its work — for an element that belongs near the
front of a long sorted prefix, every single element after it has to move.

Pancake Insertion Sort keeps insertion sort's overall shape — grow a sorted prefix, fold the next
element into it, repeat — but replaces every shift with a whole-prefix reversal, the same "flip"
move used in [pancake sorting](https://en.wikipedia.org/wiki/Pancake_sorting): reverse the order of
every element from the front of the array up to some index. A single flip can relocate an entire run
of elements at once, so where ordinary insertion sort needs one shift per displaced element, this
variant needs only one to three flips per insertion, regardless of how many elements end up moving.

The trick that makes this work is letting the sorted prefix change its own orientation. After an
insertion, the prefix is *not* forced back into ascending order — it is left running in whichever
direction (ascending or descending) made the fold cheapest, and that direction is recorded for the
next step. Concretely, each insertion looks at the current direction of the prefix:

- If the new element already continues that direction past the last element, nothing needs to move.
- If it belongs at the very front, one flip of the previous prefix is enough to reverse it end-to-end
  and put the new element in place — and this also flips the prefix's running direction for next
  time.
- Otherwise, the new element belongs somewhere in the middle. Its insertion point is located, the new
  element is flipped to the front, and then two more flips — one of the elements that now need to move
  ahead of it, and one of the whole updated prefix — land everything in its final order, again
  flipping the tracked direction.

Because the prefix is allowed to run backward just as often as forward, the algorithm never needs to
"undo" its own orientation before the next insertion — it just remembers which way it is currently
facing and folds accordingly. A short, three-element decision tree handles the very first few
elements by hand before this general loop begins, since there is no established direction to react to
yet.

Locating the insertion point itself uses a binary search technique sometimes called a *monobound*
search: rather than the textbook binary search's two comparisons per halving (one to decide whether to
recurse left or right, one to check for termination), it halves the remaining search width on a single
comparison per step, only performing the second comparison once, at the very end, to resolve the last
element. Because the prefix being searched may currently be running ascending or descending, two
mirror-image versions of the search are used depending on the tracked direction. The technique searches
in exactly the same asymptotic O(log n) comparisons as an ordinary binary search, just with a slightly
lower constant factor.

The net effect is an insertion sort that never shifts a single element — every rearrangement, no matter
how many elements it touches, is expressed as one, two, or three whole-prefix reversals. This does not
change the algorithm's asymptotic complexity: it is still O(n) in the best case, when the input arrives
already sorted (each new element continues the current direction, so no flips are needed at all), and
O(n^2) on average and in the worst case, since a long run of insertions near the front of a large,
unfavorably-ordered prefix still requires flips whose length scales with the size of the prefix. It
uses O(1) additional space, sorting the array in place. Because the prefix is free to reverse itself
between insertions, equal elements can end up reordered relative to one another, so, unlike standard
insertion sort, this variant is not stable.

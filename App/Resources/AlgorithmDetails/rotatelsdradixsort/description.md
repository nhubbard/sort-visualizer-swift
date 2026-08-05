*From Wikipedia, the free encyclopedia*

Radix sort is a non-[comparative](https://en.wikipedia.org/wiki/Comparison_sort) sorting algorithm that sorts integers
(or other fixed-format keys) by processing their digits rather than comparing whole values against one another.
Least-significant-digit (LSD) radix sort visits digit positions starting from the ones place and working toward the
most significant digit; at each position it redistributes the entire array according to just that digit while
preserving whatever relative order the previous, less-significant pass left behind. Because a
[stable](https://en.wikipedia.org/wiki/Sorting_algorithm#Stability) redistribution at every digit position is enough to
guarantee a fully sorted array once every digit has been considered, LSD radix sort never needs to look back at digits
it has already processed.

The textbook way to redistribute by a single digit is [counting sort](https://en.wikipedia.org/wiki/Counting_sort):
tally how many elements carry each digit value, turn those tallies into output offsets, and copy every element into a
fresh array at its computed offset. That approach is fast — linear in the array length plus the radix — but it needs an
auxiliary array as large as the input, plus a small counting table, on every single digit pass.

Rotate LSD Radix Sort achieves the same digit-by-digit result without ever allocating that auxiliary array. Instead of
counting and copying, it treats a single digit pass as a **merge**: the index range is split in half exactly as an
ordinary merge sort would split it, each half is (recursively) made correct with respect to the current digit, and the
two halves are then merged back together in place. The merge step is where the technique departs from ordinary merging.
Because both halves are already arranged by the current digit's value, the point at which one half's low-digit elements
end and its high-digit elements begin can be found directly with a
[binary search](https://en.wikipedia.org/wiki/Binary_search_algorithm), rather than by scanning element by element. The
merge picks a digit value roughly halfway between the smallest and largest possible digit, binary-searches that
threshold into both halves, and then performs a **block rotation** — swapping one contiguous span of elements with an
adjacent equal-length span, with no temporary storage — to bring every element below the threshold, from both halves,
together on the left. The two smaller spans left on either side of that rotation are themselves still unmerged with
respect to a narrower digit range, so the same procedure recurses into each of them, halving the digit range along with
the index range on every call, until a span is trivially small or its digit range has narrowed to a single exact digit
value (at which point every element in it already carries that digit, and nothing more needs to move).

Locating each rotation point by binary search rather than a linear scan, and moving elements only via whole-block
rotations rather than one at a time, keeps a single digit pass to `O(n log n)` work — matching the cost of a full merge
sort over the array for every digit position — while using no auxiliary buffer at all beyond the recursion stack. That
trade replaces counting sort's `O(n + radix)` per-digit cost and its linear auxiliary space with a `O(n log n)`
per-digit cost and constant auxiliary space, which is the entire point of the variant: it is a genuinely in-place LSD
radix sort, at the cost of an extra logarithmic factor per digit compared to the counting-sort version. Because the
underlying merge step never reorders equal elements — an element's digit value alone decides which side of a rotation
it lands on, and elements that were already adjacent and share that digit value are never moved past each other — the
overall sort remains stable, which is essential for an LSD scheme, since later (more significant) digit passes depend
on the ordering left behind by earlier ones.

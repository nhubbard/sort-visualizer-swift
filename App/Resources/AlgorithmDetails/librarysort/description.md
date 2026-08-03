*From Wikipedia, the free encyclopedia*

Library sort takes its name from a librarian shelving books: rather than packing already-sorted
books edge to edge, a librarian leaves a little empty space after each one, so a newly acquired
book can usually just slide into the gap right after its correct neighbor instead of forcing every
book after it to be shifted down the shelf. The algorithm applies the same idea to an array.
Values are inserted one at a time into a backing structure deliberately kept larger than the
number of elements it currently holds, with empty slots spread out among the real ones. A binary
search over the already-placed elements locates where the new value belongs, and if the slot
immediately following its predecessor happens to be empty, the value drops in directly with no
shifting at all.

Gaps don't last forever. Insertions gradually consume the empty slots near a busy region, and
eventually a new value's target slot turns out to already be occupied by another element — or, at
the high end, to sit just past the last slot the structure currently has room for. When that
happens, the nearest empty slot is located by scanning outward in both directions from the target,
and every element between the target and whichever gap turns out closer is shifted over by one to
open room for the new value. Scanning only one direction is not enough: a long run of insertions
can hollow out every gap ahead of a region while leaving the gaps behind it completely untouched,
so the nearer gap is just as likely to be on the left as on the right. Whenever every slot in the
current structure fills up, it is rebuilt at roughly double the size, with its existing elements
spread back out one gap apart, restoring room for cheap, direct insertions again.

Because the binary search always finds the first slot holding a value strictly greater than the
one being inserted, a new value is always placed immediately after any equal values already
present, which preserves their relative order and makes the sort stable. When gaps are plentiful,
most insertions cost only a binary search plus a short shift, giving an average running time of
O(n log n). An input that repeatedly forces long shifts by exhausting the gaps to one side of a
region, though, can degrade this toward O(n²) in the worst case, since a single shift can in
principle move every element already placed.

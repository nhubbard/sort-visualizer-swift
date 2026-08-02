In-Place LSD Radix Sort is a variant of least-significant-digit radix sort that avoids allocating
a second, full-size array to hold each pass's output. An ordinary LSD radix sort processes one
digit at a time, starting from the least significant, by counting how many elements have each
digit value and using those counts to copy every element into its correct position in a fresh
output array. That output array is what this variant does away with, at the cost of doing
noticeably more element movement to make up for it.

For each digit place, this algorithm keeps one small counter per possible nonzero digit value,
each starting at the last index of the array and only ever moving inward — think of each counter
as reserving a landing spot for its digit, counted in from the end. A single left-to-right scan
then does the whole pass: whenever the current position holds a value whose digit is zero, it's
already correctly grouped ahead of every nonzero digit for this pass, so the scan simply moves on.
Anything else gets walked all the way out to its own counter's reserved spot via a chain of
adjacent swaps — shifting everything in between over by one to make room — and every counter
belonging to a smaller nonzero digit shifts one step further inward, since the passing element
just claimed a slot that used to belong to it.

That chain-of-swaps relocation is the trade this algorithm makes: instead of an O(n) auxiliary
array, it spends more time, since a single element can be walked a large stretch of the array in
one step, and that cost is repeated once per digit place. It is nonetheless still built entirely
out of comparisons against a fixed digit-place counter and swaps between array positions — no
value is ever read differently based on where an equal value happens to sit, so equal elements
never trade places relative to each other, and the sort is stable.

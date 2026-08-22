Bogosort's whole premise is a joke: shuffle the array at random, check whether the shuffle happened
to land it in order, and if not, shuffle again. Its expected running time already scales with the
factorial of the input size, which is precisely the point — it exists to be a punchline, a
"generate and test" strategy pushed to its most useless extreme, kept around only to illustrate by
contrast why real sorting algorithms bother being clever.

Bogo Bogo Sort takes that joke and escalates it by attacking the one part of Bogosort that looks
free: the "is it sorted?" check itself. An ordinary Bogosort answers that question with a single
pass over the array. Bogo Bogo Sort refuses to do anything so cheap. Instead, to decide whether a
range is sorted, it copies the range, recursively Bogo-Bogo-sorts the copy's first `n - 1` elements
using this exact same process one level further down, reshuffles the *entire* copy and repeats
until the copy's last two elements land in the correct order relative to each other, and only then
compares the finished copy against the original, element by element. If they match, the original
must have already been sorted — because the copy was built, from scratch, into the one true sorted
arrangement of that multiset, without ever taking the shortcut of just looking at the original's
order directly.

That's the whole trick: the sortedness check is itself a complete sort, computed recursively, at
every smaller scale, all the way down to a single element. Plain Bogosort's expected cost is already
the infamous `O(n × n!)`. Bogo Bogo Sort's is a tower built on top of that — something closer to
`O(n × (n!)²)`, and by some accountings meaningfully worse still, because every failed attempt at
every level of recursion pays for an entire nested sort just to be told "no, shuffle again." Where
Bogosort struggles past a dozen or so elements, Bogo Bogo Sort struggles past four or five.

None of this is an accident or an oversight — it's the entire design goal. Bogo Bogo Sort is an
esoteric novelty algorithm, engineered to be as extravagantly wasteful as possible while remaining,
technically, a correct sort. It earns its place here purely for entertainment value and as a
teaching example: a reminder that even an operation as "obviously cheap" as asking whether a list is
already in order can be made to cost more than almost anything else in computing, if you go far
enough out of your way to make it so. It is not, and was never meant to be, something to actually
run.

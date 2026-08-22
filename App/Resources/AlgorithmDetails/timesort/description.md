Time Sort — better known by its folk nickname "sleep sort" — turns sorting into a race against the
clock instead of a series of comparisons. The idea: launch one independent task per element, have
each task wait for an amount of time proportional to its own value, and then have it report that
value into the next open output slot the moment it wakes up. Because larger values sleep longer,
tasks holding smaller values tend to wake — and therefore report — before tasks holding larger
ones, so simply letting every task "show up whenever it's ready" is often enough to produce a
sorted sequence, with no element ever compared against another.

That "often" is the whole reason this is a novelty rather than a real sorting technique. The
reporting order is only ever an approximation of sorted order, because the gap between "a task
wakes up" and "a task actually reports" depends on how busy the scheduler happens to be at that
exact moment — two tasks whose sleep durations were meant to be milliseconds apart can report in
the opposite order if the system is under load in between, and there is no floor on how much
scheduling jitter a given value gap can absorb before it gets reordered. The approach doesn't scale
either, entirely apart from whether the ordering comes out right: it spawns one concurrent
sleeper per element, so an array of a million values means a million simultaneous waiting tasks, a
resource cost no serious sorting algorithm would tolerate. Its running time is also tied to the
*size* of the values rather than the *count* of elements — a single very large value forces every
task to wait for it, no matter how few elements there are.

Because the reporting order can't be trusted on its own, a version of this algorithm that actually
wants a correct result cannot stop once every task has reported. A robust implementation follows
the race with a real comparison-based cleanup pass — an ordinary insertion sort works well, since
it does the least work when its input is already nearly sorted — over whatever order the wake-up
race produced. On a lucky run that pass finds nothing left to fix, because the reporting order
already happened to be sorted; on a run where the scheduler was unkind to a couple of elements, it
quietly corrects them. Either way, correctness ends up resting on the comparison pass rather than
on the race, which makes the sleeping and reporting mostly a colorful, needlessly expensive way of
producing a starting point that is usually already sorted or very close to it.

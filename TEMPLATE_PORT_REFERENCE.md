# Template Port Reference

Prep work for porting 6 ArrayV `sorts/templates/` base classes and the 12 concrete algorithms
behind them (see `PORT_INVENTORY.md` for the cluster list and reuse-verdict table). This document
exists so the dense, index-arithmetic-heavy algorithms below only have to be transcribed out of
Java **once** — both the Swift template port and the eventual 10-language `AlgorithmDetails`
resource-folder reimplementations should work from the pseudocode here rather than re-deriving it
from source under time pressure.

**How to use this**: every function below is stripped of ArrayV's visualizer instrumentation
(`Reads`/`Writes`/`Highlights`/`Delays` calls) — pure array algorithm only. Arrays are 0-indexed.
Comparisons are plain `<`/`>`/`<=`/`>=`/`==` on values unless noted. "Rotate `[pos, pos+lenA)` and
`[pos+lenA, pos+lenA+lenB)`" always means: swap the two adjacent blocks' contents so the second
block ends up first, in place, without disturbing the sortedness *within* either block. Where the
Swift port needs a real design decision (an outright ArrayV bug, or an assumption that doesn't
hold in this engine), it's called out in a **Design decision** box — these still need empirical
validation when actually implemented (matching how `FunSort`'s and `TableSort`'s fixes were
validated), this document only proposes the fix.

---

## 1. `BinaryQuickSortingTemplate`

Source: `~/ArrayV/.../templates/BinaryQuickSorting.java` (101 lines). Binary MSD radix
sort/quicksort — partitions on one bit at a time, recursing (or queueing) into the two halves with
the next-lower bit. Fully reusable by both concrete algorithms below, no shadowing.

```
function partition(p, r, bit) -> Int:
    // Hoare-style: stuff with `bit` clear goes left, `bit` set goes right
    i = p - 1
    j = r + 1
    loop:
        repeat: i += 1
        while i <= r and bit `bit` of array[i] is 0
        repeat: j -= 1
        while j >= p and bit `bit` of array[j] is 1
        if i < j: swap(array, i, j)
        else: return j

function binaryQuickSortRecursive(p, r, bit):
    if p < r and bit >= 0:
        q = partition(p, r, bit)
        binaryQuickSortRecursive(p, q, bit - 1)
        binaryQuickSortRecursive(q + 1, r, bit - 1)

function binaryQuickSort(p, r, bit):
    // same as above, but iterative via an explicit FIFO queue of (p, r, bit) tasks
    // instead of the call stack
    queue = [(p, r, bit)]
    while queue is not empty:
        (p, r, bit) = queue.removeFirst()
        if p < r and bit >= 0:
            q = partition(p, r, bit)
            queue.append((p, q, bit - 1))
            queue.append((q + 1, r, bit - 1))
```

`bit(value, k) = ((value >> k) & 1) == 1` — plain bit test, no special cases.

**Entry points** (both concrete algorithms are pure one-line wrappers):
- `BinaryQuickSortIterative`: `mostSignificantBit = floor(log2(max(array)))` (if `max == 0`,
  there's nothing to sort — every value is already 0 — so treat this as `bit = -1` and skip
  straight to returning); then `binaryQuickSort(0, n - 1, mostSignificantBit)`.
- `BinaryQuickSortRecursive`: same MSB computation, calls `binaryQuickSortRecursive(0, n - 1,
  mostSignificantBit)` instead.

No fields; no design issues found — this template is a clean, direct port. Values can be
negative in this engine (ArrayV's own array is never negative) — `>> k` on a negative Int in
Swift is an arithmetic (sign-extending) shift same as Java, so the bit-test semantics carry over
correctly as long as `mostSignificantBit` is computed from the actual bit-width needed (safest:
use the highest bit that differs across any two elements, or simply seed from the highest bit set
in `max(abs(every value))` plus a sign-handling pass — needs a real decision at implementation
time if negative-value fuzzing is in scope; ArrayV itself never sorts negatives here).

**Stability expectation**: unstable — a bit-only Hoare partition has no tie-break, equal values
(identical in every bit) can still cross past each other. Verify empirically as always.

---

## 2. `ShatterSortingTemplate`

Source: `~/ArrayV/.../templates/ShatterSorting.java` (102 lines). A two-level bucket/distribution
sort. Fully reusable by both concrete algorithms, no shadowing — **but see the Design decision
below before porting either.**

```
function shatterPartition(length, num):
    // buckets every element by floor(value / num) into `shatters` buckets, then flattens
    // the buckets back into array in bucket order (stable within each bucket: encounter order)
    shatters = ceil(length / num)
    buckets = shatters empty growable lists
    for i in 0..<length:
        buckets[array[i] / num].append(array[i])
    write buckets[0], then buckets[1], ..., then buckets[shatters-1] back into array in order

function shatterSort(length, num):
    shatters = ceil(length / num)
    shatterPartition(length, num)
    tmp = int array of size num
    for i in 0..<shatters:
        // copy this shatter's num-sized window into tmp (pad with a -1 sentinel past the end)
        for j in 0..<num:
            tmp[j] = (i*num + j < length) ? array[i*num + j] : -1
        // place each tmp[j] at offset (tmp[j] mod num) within the window
        for j in 0..<num:
            if tmp[j] == -1 or i*num + (tmp[j] mod num) >= length: break
            array[i*num + (tmp[j] mod num)] = tmp[j]

function simpleShatterSort(length, num, rate):
    // repeated shatterPartition passes with a shrinking divisor, finishing at num=1
    i = num
    while i > 1:
        shatterPartition(length, i)
        i = i / rate     // integer division
    shatterPartition(length, 1)
```

`SimpleShatterSort`'s entry point calls `simpleShatterSort(n, bucketCount, floor(log2(n)) / 2)`.
`ShatterSort`'s entry point calls `shatterSort(n, bucketCount)` directly. In both, `bucketCount` is
ArrayV's own "how many values fall in one bucket" tuning knob — not something this engine
currently threads through `SortAlgorithm`, so the Swift port picks its own reasonable constant
(see design decision below for what it should actually mean).

> **Design decision — required, not faithful-port-optional, VALIDATED**: `shatterPartition`'s
> bucket index (`array[i] / num`) and `shatterSort`'s in-window placement (`tmp[j] mod num`) both
> assume the array holds a **permutation of `0..<length`** — true for every ArrayV visualizer
> array, but **not** true here: `NativeAlgorithmCorrectnessTests.everyAlgorithmSortsRandomInputsCorrectly`
> feeds `Int.random(in: 0...1000)` regardless of array size. A literal port would compute
> out-of-range bucket indices for that, and `shatterSort`'s residue-placement trick relies on each
> `num`-sized window holding a *complete residue system* (only guaranteed when the window's values
> are `num` **consecutive** integers) — with arbitrary or duplicate values, two elements can land
> on the same `mod num` residue within one window and silently overwrite each other.
>
> **Fixed design** (fuzzed clean across ~6,600 Python trials — duplicate-heavy, wide-range
> distinct, sizes 2-256 including the exact `0...1000` range the real test suite uses, and
> adversarial edge cases — zero failures):
> ```
> function shatterPartition(start, length, num) -> offsets:
>     // returns the REAL starting offset of each bucket (relative to `start`) — bucket sizes are
>     // no longer a fixed `num`, they depend on the actual value distribution
>     minV = min(values[start ..< start+length])
>     maxV = max(values[start ..< start+length])
>     valueRange = maxV - minV + 1
>     shatters = ceil(length / num)
>     buckets = shatters empty lists
>     for v in values[start ..< start+length]:
>         idx = min(shatters - 1, (v - minV) * shatters / valueRange)   // range-normalized,
>         buckets[idx].append(v)                                        // NOT value / num
>     offsets = prefix sums of bucket sizes (offsets[0] = 0, offsets[shatters] = length)
>     write buckets back into values[start ..< start+length] in bucket order
>     return offsets
>
> function shatterSort(length, num):
>     offsets = shatterPartition(0, length, num)
>     for i in 0..<shatters:
>         if offsets[i+1] - offsets[i] > 1: insertionSort(offsets[i], offsets[i+1])
>
> function simpleShatterSort(length, num, rate):
>     // same shrinking-divisor structure as the original, preserved for fidelity
>     i = num
>     while i > 1:
>         shatterPartition(0, length, i)
>         i = i / rate
>     offsets = shatterPartition(0, length, 1)
>     for i in 0..<shatters:
>         if offsets[i+1] - offsets[i] > 1: insertionSort(offsets[i], offsets[i+1])
> ```
> The in-window residue trick is replaced with a plain insertion-sort backstop over each bucket's
> *real* size — necessary because even at maximum granularity (`num=1`), a bucket count bounded by
> array length can't guarantee one-bucket-per-distinct-value when the value range exceeds the
> array length (e.g. `0...1000` values in a 16-element array) — no amount of re-bucketing alone
> fixes that, only an exact per-bucket sort does. This is also just the textbook definition of a
> bucket sort (bucket, then sort each bucket) rather than a special ArrayV-only trick, so it isn't
> a loss of faithfulness so much as a return to the standard algorithm the original was
> special-casing away from (safely, under its own permutation assumption).

**Stability expectation**: `shatterPartition` alone (as used partway through `simpleShatterSort`)
is stable — buckets preserve encounter order and are flattened in bucket order. The insertion-sort
backstop is also stable (standard insertion sort, no distinct-tie-break needed). So both
`ShatterSort` and `SimpleShatterSort` are expected to end up stable under the fixed design — still
verify empirically rather than trusting this a priori reasoning outright.

---

## 3. `TwinSortingTemplate`

Source: `~/ArrayV/.../templates/TwinSorting.java` (217 lines). Igor van den Hoven's adaptive
bottom-up merge sort: a pairwise run-detection/local-reversal pre-pass, then a tail-inward bottom-up
merge. Only one real consumer (`TwinSort`), which uses the whole surface unmodified.

```
function twinSwap(left, nmemb) -> Int:
    // scans pairs (index, index+1); ascending pairs are skipped 2 at a time. When a
    // descending run is found, it's tracked until it ends, then reversed in place.
    // Returns 1 if the ENTIRE range turned out to be one single reversed run (nothing
    // more to do — caller should skip the merge phase entirely), else 0.
    index = 0
    end = nmemb - 2
    while index <= end:
        if array[index+left] <= array[index+1+left]:
            index += 2
            continue
        start = index
        index += 2
        loop:
            if index > end:
                if start == 0 and (nmemb is even or array[index-1+left] > array[index+left]):
                    // the whole range is one descending run -- reverse it all and stop
                    end = nmemb - 1
                    reverse array[start+left ... end+left] in place (swap from both ends inward)
                    return 1
                break
            if array[index+left] > array[index+1+left]:
                if array[index-1+left] > array[index+left]:
                    index += 2
                    continue
                swap(array, index+left, index+1+left)
            break
        end = index - 1
        reverse array[start+left ... end+left] in place
        end = nmemb - 2
        index += 2
    return 0

function tailMerge(left, swap[], nmemb, block):
    // bottom-up merge, doubling `block` each pass. Copies the RIGHT block into `swap`,
    // then merges starting from the TAIL ends of both blocks inward (writing the
    // combined result into `array` from the high end down). Needs at most nmemb/2
    // scratch space, reused across the whole sort (passed in by the caller once).
    s = 0
    while block < nmemb:
        offset = 0
        while offset + block < nmemb:
            a = offset
            e = a + block - 1
            if array[e+left] <= array[e+1+left]:
                // this adjacent pair of blocks is already in order -- skip the merge
                offset += block * 2
                continue

            if offset + block*2 <= nmemb:
                cMax = s + block
                dMax = a + block*2
            else:
                cMax = s + nmemb - (offset + block)
                dMax = nmemb

            // shrink the merge if the tail of the right block is already >= the tail
            // of the left block (an early-exit for a partially-already-merged tail)
            d = dMax - 1
            while array[e+left] <= array[d+left]:
                dMax -= 1; d -= 1; cMax -= 1

            // copy the right block into swap[s..<cMax)
            c = s
            d = a + block
            while c < cMax:
                swap[c] = array[d+left]
                c += 1; d += 1
            c -= 1

            d = a + block - 1
            e = dMax - 1

            if array[a+left] <= array[a+block+left]:
                // left block's head is already <= right block's head: merge from the
                // tail of the LEFT block against the buffered right block
                array[e+left] = array[d+left]; e -= 1; d -= 1
                while c >= s:
                    while array[d+left] > swap[c]:
                        array[e+left] = array[d+left]; e -= 1; d -= 1
                    array[e+left] = swap[c]; e -= 1; c -= 1
            else:
                // mirror branch: merge from the tail of the buffered right block first
                array[e+left] = array[d+left]; e -= 1; d -= 1
                while d >= a:
                    while array[d+left] <= swap[c]:
                        array[e+left] = swap[c]; e -= 1; c -= 1
                    array[e+left] = array[d+left]; e -= 1; d -= 1
                while c >= s:
                    array[e+left] = swap[c]; e -= 1; c -= 1

            offset += block * 2
        block *= 2

function twinsortSwap(start, swap[], nmemb):
    // entry point reusing a caller-supplied swap buffer
    if twinSwap(start, nmemb) == 0:
        tailMerge(start, swap, nmemb, 2)

function twinsort(nmemb):
    // top-level entry: allocates its own scratch buffer
    if twinSwap(0, nmemb) == 0:
        swap = int array of size nmemb / 2
        tailMerge(0, swap, nmemb, 2)

function tailsort(nmemb):
    // alternate entry: skips the run-detection pre-pass entirely (treats every
    // element as its own 1-length run) -- currently unused by any ArrayV subclass
    if nmemb < 2: return
    swap = int array of size nmemb / 2
    tailMerge(0, swap, nmemb, 1)
```

**Entry point**: `TwinSort` is a one-line wrapper calling `twinsort(n)`. `twinsortSwap`/`tailsort`
are unreferenced by any current ArrayV subclass — port `twinsort`/`twinSwap`/`tailMerge` for
`TwinSort`; the other two entry points are optional (include them if cheap, since `tailMerge`
already exists — skip if pressed for time, nothing currently needs them).

**Stability expectation**: uncertain — `twinSwap`'s reversal of descending runs and `tailMerge`'s
merge-from-the-tail-inward approach need empirical fuzzing to determine stability, no strong a
priori claim either way (this is exactly the kind of "clever, non-obvious" mechanism the project's
established policy says never to assume about).

---

## 4. `UnstableGrailSortingTemplate`

Source: `~/ArrayV/.../templates/UnstableGrailSorting.java` (355 lines). Astrelin's classic
in-place block-merge sort, the *unstable* variant (no per-block original-stream tracking — see
`GrailSortingTemplate` below for the stable version with that tracking added back in). Only one
consumer (`UnstableGrailSort`), 100% pass-through.

Shared small primitives (identical in spirit to `GrailSortingTemplate`'s, kept separate here since
this is a distinct, self-contained ArrayV class — not literally shared code with `GrailSorting` in
the original):

```
function swap(a, b): swap array[a] and array[b]
function multiSwap(a, b, count): for i in 0..<count: swap(a+i, b+i)

function rotate(pos, lenA, lenB):
    // identical shape to GrailSortingTemplate.rotate — repeated block-swap of the smaller side
    while lenA != 0 and lenB != 0:
        if lenA <= lenB: multiSwap(pos, pos+lenA, lenA); pos += lenA; lenB -= lenA
        else: multiSwap(pos + (lenA-lenB), pos+lenA, lenB); lenA -= lenB

function insertSort(pos, len):
    // base case for len <= 16 -- a plain, real insertion sort over array[pos..<pos+len)
    // (ArrayV delegates to OptimizedGnomeSort's own range-scoped sort here; port as a direct
    // local insertion sort instead of reaching for another shipped algorithm's internals)

function binSearch(pos, len, keyPos, isLeft) -> Int:
    // identical to GrailSortingTemplate.binSearch (see above)

function mergeWithoutBuffer(pos, len1, len2):
    // identical to GrailSortingTemplate.mergeWithoutBuffer (see above) -- NOT reused by
    // grailCommonSort's main path here (only by the len<=16 fallback + the final fold-in),
    // same as GrailSorting
```

The block-merge machinery, simplified (no stream-fragment/key tracking — this is what makes it
*unstable*):

```
function mergeBuffersLeft(pos, blockCount, blockLen, aBlockCount, lastLen):
    if blockCount == 0:
        mergeLeft(pos, aBlockCount * blockLen, lastLen, -blockLen)
        return
    leftOverLen = blockLen
    processIndex = blockLen
    for keyIndex in 1..<blockCount:
        restToProcess = processIndex - leftOverLen
        leftOverLen = smartMergeWithBuffer(pos + restToProcess, leftOverLen, blockLen)
        processIndex += blockLen
    restToProcess = processIndex - leftOverLen
    if lastLen != 0:
        leftOverLen += blockLen * aBlockCount
        mergeLeft(pos + restToProcess, leftOverLen, lastLen, -blockLen)
    else:
        multiSwap(pos + restToProcess, pos + restToProcess - blockLen, leftOverLen)

function mergeLeft(pos, leftLen, rightLen, dist):
    // arr[pos+dist ..< pos] is a free buffer; merges array[pos..<pos+leftLen) (sorted) and
    // array[pos+leftLen..<pos+leftLen+rightLen) (sorted) INTO that buffer region via swaps
    left = 0; right = leftLen; rightLen += leftLen
    while right < rightLen:
        if left == leftLen or array[pos+left] > array[pos+right]:
            swap(pos + dist, pos + right); dist += 1; right += 1
        else:
            swap(pos + dist, pos + left); dist += 1; left += 1
    if dist != left: multiSwap(pos + dist, pos + left, leftLen - left)

function mergeRight(pos, leftLen, rightLen, dist):
    // mirror of mergeLeft, merging from the tail ends backward into a buffer positioned after
    mergedPos = leftLen + rightLen + dist - 1
    right = leftLen + rightLen - 1; left = leftLen - 1
    while left >= 0:
        if right < leftLen or array[pos+left] > array[pos+right]:
            swap(pos + mergedPos, pos + left); mergedPos -= 1; left -= 1
        else:
            swap(pos + mergedPos, pos + right); mergedPos -= 1; right -= 1
    while right != mergedPos and right >= leftLen:
        swap(pos + mergedPos, pos + right); mergedPos -= 1; right -= 1

function smartMergeWithBuffer(pos, leftOverLen, blockLen) -> Int:
    // merges a "leftover" fragment of length leftOverLen with the next regular block of
    // length blockLen, using the blockLen-sized region immediately before pos as a buffer
    // (via swaps, so the buffer's old contents end up wherever they sorted to). Returns the
    // new leftover length to carry into the NEXT call in the chain.
    dist = -blockLen; left = 0; right = leftOverLen; leftEnd = right; rightEnd = right + blockLen
    while left < leftEnd and right < rightEnd:
        if array[pos+left] <= array[pos+right]: swap(pos+dist, pos+left); dist += 1; left += 1
        else: swap(pos+dist, pos+right); dist += 1; right += 1
    if left < leftEnd:
        length = leftEnd - left
        while left < leftEnd: leftEnd -= 1; rightEnd -= 1; swap(pos+leftEnd, pos+rightEnd)
    else:
        length = rightEnd - right
    return length

function buildBlocks(pos, len, buildLen):
    // bottom-up run construction, no external buffer (unlike GrailSortingTemplate's version,
    // which can use one): pairwise-sorts adjacent elements with a 4-slot shuffle trick, then
    // doubles block size via mergeLeft/rotate until buildLen is reached
    for dist in stride(1, <len, by: 2):
        extraDist = (array[pos+dist-1] > array[pos+dist]) ? 1 : 0
        swap(pos + dist - 3, pos + dist - 1 + extraDist)
        swap(pos + dist - 2, pos + dist - extraDist)
    if len is odd: swap(pos + len - 1, pos + len - 3)
    pos -= 2
    part = 2
    while part < buildLen:
        left = 0; right = len - 2*part
        while left <= right:
            mergeLeft(pos + left, part, part, -part)
            left += 2 * part
        rest = len - left
        if rest > part: mergeLeft(pos + left, part, rest - part, -part)
        else: rotate(pos + left - part, part, rest)
        pos -= part
        part *= 2
    restToBuild = len mod (2 * buildLen)
    leftOverPos = len - restToBuild
    if restToBuild <= buildLen: rotate(pos + leftOverPos, restToBuild, buildLen)
    else: mergeRight(pos + leftOverPos, buildLen, restToBuild - buildLen, buildLen)
    while leftOverPos > 0:
        leftOverPos -= 2 * buildLen
        mergeRight(pos + leftOverPos, buildLen, buildLen, buildLen)

function combineBlocks(pos, len, buildLen, regBlockLen):
    // combines pairs of buildLen-sized super-blocks: within each 2*buildLen-sized super-block,
    // selection-sorts the regBlockLen-sized sub-blocks by their (first, last) element pair,
    // then merges them via mergeBuffersLeft
    combineLen = len / (2 * buildLen)
    leftOver = len mod (2 * buildLen)
    if leftOver <= buildLen: len -= leftOver; leftOver = 0
    for i in 0...combineLen:
        if i == combineLen and leftOver == 0: break
        blockPos = pos + i * 2 * buildLen
        blockCount = (i == combineLen ? leftOver : 2*buildLen) / regBlockLen
        // selection sort of the blockCount sub-blocks, comparing each block's first element,
        // tie-breaking on each block's LAST element (not an original-index/stability tie-break
        // -- this is what makes the whole sort unstable)
        for index in 1..<blockCount:
            leftIndex = index - 1
            for rightIndex in index..<blockCount:
                cmp = compare(array[blockPos + leftIndex*regBlockLen], array[blockPos + rightIndex*regBlockLen])
                if cmp > 0 or (cmp == 0 and array[blockPos + (leftIndex+1)*regBlockLen - 1] > array[blockPos + (rightIndex+1)*regBlockLen - 1]):
                    leftIndex = rightIndex
            if leftIndex != index - 1:
                multiSwap(blockPos + (index-1)*regBlockLen, blockPos + leftIndex*regBlockLen, regBlockLen)
        aBlockCount = 0
        lastLen = (i == combineLen) ? (leftOver mod regBlockLen) : 0
        if lastLen != 0:
            while aBlockCount < blockCount and array[blockPos + blockCount*regBlockLen] < array[blockPos + (blockCount-aBlockCount-1)*regBlockLen]:
                aBlockCount += 1
        mergeBuffersLeft(blockPos, blockCount - aBlockCount, regBlockLen, aBlockCount, lastLen)
    while len > 0:
        len -= 1
        swap(pos + len, pos + len - regBlockLen)

function commonSort(pos, len):
    // top-level entry point
    if len <= 16:
        insertSort(pos, len)
        return
    blockLen = 1
    while blockLen * blockLen < len: blockLen *= 2
    buildLen = blockLen
    buildBlocks(pos + blockLen, len - blockLen, buildLen)
    while len - blockLen > (buildLen *= 2):
        combineBlocks(pos + blockLen, len - blockLen, buildLen, blockLen)
    insertSort(pos, blockLen)
    mergeWithoutBuffer(pos, blockLen, len - blockLen)
```

**Entry point**: `UnstableGrailSort` is a one-line wrapper calling `commonSort(0, n)`.

**Stability expectation**: **unstable by construction and by name** — `combineBlocks`'s
selection-sort-of-blocks has no original-index tie-break, only first/last element value. Confirm
empirically that it actually IS unstable (matching the "never trust a name" policy even when the
name says "unstable" — verify the fuzz test actually finds reordering, don't just assume).

---

## 5. `PDQSortingTemplate`

Source: `~/ArrayV/.../templates/PDQSorting.java` (570 lines). Orson Peters' pattern-defeating
quicksort. Fully reusable, cleanest case — both concrete algorithms are pure configuration
wrappers around one shared `pdqLoop`.

```
// Tuning constants (all fixed, not exposed to subclasses in ArrayV either)
insertSortThreshold = 24
nintherThreshold = 128
partialInsertSortLimit = 8
blockSize = 64
cachelineSize = 64   // only used to size the branchless-mode offset buffers

function pdqLog(n) -> Int:
    // floor(log2(n)), assumes n > 0
    log = 0
    while (n >>= 1) != 0: log += 1
    return log

function insertSort(begin, end):
    // guarded insertion sort (checks the "hit the left edge" case every step)
    for cur in (begin+1)..<end:
        if array[cur] < array[cur-1]:
            tmp = array[cur]
            sift = cur; siftMinusOne = cur - 1
            repeat:
                array[sift] = array[siftMinusOne]; sift -= 1; siftMinusOne -= 1
            while sift != begin and tmp < array[siftMinusOne]
            array[sift] = tmp

function unguardInsertSort(begin, end):
    // same as insertSort but assumes array[begin-1] <= everything in [begin,end), so the
    // "sift != begin" edge check can be skipped -- only valid when NOT the leftmost partition
    for cur in (begin+1)..<end:
        if array[cur] < array[cur-1]:
            tmp = array[cur]
            sift = cur; siftMinusOne = cur - 1
            repeat:
                array[sift] = array[siftMinusOne]; sift -= 1; siftMinusOne -= 1
            while tmp < array[siftMinusOne]
            array[sift] = tmp

function partialInsertSort(begin, end) -> Bool:
    // like insertSort, but bails out (returns false, array left partially modified) if the
    // total number of shifted elements exceeds partialInsertSortLimit
    limit = 0
    for cur in (begin+1)..<end:
        if limit > partialInsertSortLimit: return false
        if array[cur] < array[cur-1]:
            tmp = array[cur]
            sift = cur; siftMinusOne = cur - 1
            repeat:
                array[sift] = array[siftMinusOne]; sift -= 1; siftMinusOne -= 1
            while sift != begin and tmp < array[siftMinusOne]
            array[sift] = tmp
            limit += cur - sift
    return true

function sortTwo(a, b):
    if array[b] < array[a]: swap(a, b)

function sortThree(a, b, c):
    sortTwo(a, b); sortTwo(b, c); sortTwo(a, b)
```

**Branch-based partition** (used when `Branchless == false`):

```
function partRight(begin, end) -> (pivotPos: Int, alreadyParted: Bool):
    pivot = array[begin]
    first = begin; last = end
    repeat: first += 1
    while array[first] < pivot
    if first - 1 == begin:
        // guarded: only this first backward scan can walk off the left edge (nothing has
        // swapped a sentinel into place yet), so check `first < last` on every step
        repeat: last -= 1
        while first < last and not(array[last] < pivot)
    else:
        // unguarded: a previous partition's swap already guarantees a stopping point
        repeat: last -= 1
        while not(array[last] < pivot)
    alreadyParted = (first >= last)
    while first < last:
        swap(first, last)
        repeat: first += 1
        while array[first] < pivot
        repeat: last -= 1
        while not(array[last] < pivot)
    pivotPos = first - 1
    array[begin] = array[pivotPos]
    array[pivotPos] = pivot
    return (pivotPos, alreadyParted)
```

**Branchless (block quicksort) partition** (used when `Branchless == true`) — the densest code in
this whole batch, port close to verbatim rather than restructuring:

```
function partRightBranchless(begin, end) -> (pivotPos: Int, alreadyParted: Bool):
    pivot = array[begin]
    first = begin; last = end

    repeat: first += 1
    while array[first] < pivot
    if first - 1 == begin:
        // guarded (see partRight above for why only this branch needs the `first < last` check)
        repeat: last -= 1
        while first < last and not(array[last] < pivot)
    else:
        repeat: last -= 1
        while not(array[last] < pivot)

    alreadyParted = (first >= last)
    if not alreadyParted:
        swap(first, last)
        first += 1

    // leftOffsets/rightOffsets: two scratch Int buffers of size blockSize + cachelineSize,
    // allocated once per sort call (see "Aux buffers" note below), reused across this whole
    // partition call
    leftNum = 0; rightNum = 0; leftStart = 0; rightStart = 0

    while last - first > 2 * blockSize:
        if leftNum == 0:
            // scan blockSize elements from `first` forward, recording the OFFSETS (not
            // values) of every element that's >= pivot (i.e. on the wrong side for the left
            // scan) into leftOffsets[0..<leftNum)
            leftStart = 0
            it = first
            for i in 0..<blockSize:
                leftOffsets[leftNum] = i
                if not (array[it] < pivot): leftNum += 1
                it += 1
            // (ArrayV unrolls this loop 8x for performance; behavior is identical unrolled
            // or not)
        if rightNum == 0:
            // mirror: scan blockSize elements from `last` backward, recording offsets of
            // every element that's < pivot (wrong side for the right scan)
            rightStart = 0
            it = last
            for i in 0..<blockSize:
                it -= 1
                i += 1
                rightOffsets[rightNum] = i
                if array[it] < pivot: rightNum += 1

        // swap num = min(leftNum, rightNum) pairs of wrong-side elements across the two
        // offset lists (see swapOffsets below), then slide the block boundary forward on
        // whichever side got fully consumed
        num = min(leftNum, rightNum)
        swapOffsets(first, last, leftStart, rightStart, num, useSwaps: leftNum == rightNum)
        leftNum -= num; rightNum -= num; leftStart += num; rightStart += num
        if leftNum == 0: first += blockSize
        if rightNum == 0: last -= blockSize

    // handle the final partial block (< 2*blockSize remaining) with one-off scans sized to
    // whatever's left, then a final swapOffsets, then finish off any still-unmatched
    // offsets by swapping them directly across the first==last boundary, and finally place
    // the pivot at its resting position (first - 1)
    // -- (see PDQSorting.java lines 299-365 for the exact leftover-block bookkeeping;
    //     this part is pure index arithmetic with no new algorithmic idea beyond the loop
    //     above, safe to transcribe directly from source when implementing)

    pivotPos = first - 1   // (after the leftover-handling above resolves first/last)
    array[begin] = array[pivotPos]
    array[pivotPos] = pivot
    return (pivotPos, alreadyParted)

function swapOffsets(first, last, leftOffsetsPos, rightOffsetsPos, num, useSwaps):
    if useSwaps:
        // needed specifically for descending input, to keep this O(n) -- plain pairwise swap
        for i in 0..<num:
            swap(first + leftOffsets[leftOffsetsPos+i], last - rightOffsets[rightOffsetsPos+i])
    elif num > 0:
        // cyclic single-pass move -- same net effect as the swaps above but ~half the writes
        // when leftNum != rightNum (some elements get written to their final spot directly
        // instead of round-tripping through a swap)
        left = first + leftOffsets[leftOffsetsPos]
        right = last - rightOffsets[rightOffsetsPos]
        tmp = array[left]
        array[left] = array[right]
        for i in 1..<num:
            left = first + leftOffsets[leftOffsetsPos+i]
            array[right] = array[left]
            right = last - rightOffsets[rightOffsetsPos+i]
            array[left] = array[right]
        array[right] = tmp
```

**Many-equal-elements partition** (equal elements go LEFT of the pivot instead of right; no
`alreadyParted` tracking needed since it's only used in the "we already know we have a big run of
duplicates" fast path):

```
function partLeft(begin, end) -> Int:
    pivot = array[begin]
    first = begin; last = end
    repeat: last -= 1
    while pivot < array[last]
    if last + 1 == end:
        repeat: first += 1
        while first < last and not(pivot < array[first])
    else:
        repeat: first += 1
        while not(pivot < array[first])
    while first < last:
        swap(first, last)
        repeat: last -= 1
        while pivot < array[last]
        repeat: first += 1
        while not(pivot < array[first])
    pivotPos = last
    array[begin] = array[pivotPos]
    array[pivotPos] = pivot
    return pivotPos
```

**Main driver** (iterative with tail-call elimination on the right partition, real recursion only
on the left):

```
function pdqLoop(begin, end, branchless, badAllowed):
    leftmost = true
    loop:
        size = end - begin
        if size < insertSortThreshold:
            if leftmost: insertSort(begin, end)
            else: unguardInsertSort(begin, end)
            return

        halfSize = size / 2
        if size > nintherThreshold:
            // "pseudomedian of 9": pick 9 sample points, median-of-three them down to 3
            // candidates, median-of-three those down to 1, swap it to `begin`
            sortThree(begin, begin+halfSize, end-1)
            sortThree(begin+1, begin+halfSize-1, end-2)
            sortThree(begin+2, begin+halfSize+1, end-3)
            sortThree(begin+halfSize-1, begin+halfSize, begin+halfSize+1)
            swap(begin, begin+halfSize)
        else:
            sortThree(begin+halfSize, begin, end-1)   // plain median-of-3

        // "many equal elements" fast path: if this partition's lower boundary is known to
        // already be <= everything ahead of it (i.e. not the leftmost partition) AND the
        // pivot compares equal to that boundary value, the whole left region is already
        // correctly placed -- partition left-heavy instead and skip recursing on the left
        if not leftmost and not (array[begin-1] < array[begin]):
            begin = partLeft(begin, end) + 1
            continue

        (pivotPos, alreadyParted) = branchless ? partRightBranchless(begin, end) : partRight(begin, end)

        leftSize = pivotPos - begin
        rightSize = end - (pivotPos + 1)
        highUnbalance = leftSize < size/8 or rightSize < size/8

        if highUnbalance:
            badAllowed -= 1
            if badAllowed == 0:
                // guarantee O(n log n): give up on quicksort entirely for this range
                heapSort(begin, end)
                return
            // scramble a handful of elements near both partition boundaries to break
            // adversarial patterns (organ-pipe, median-of-3 killer, etc.) -- see
            // PDQSorting.java lines 531-553 for the exact swap offsets, safe to transcribe
            // directly (pure index arithmetic, no new algorithmic idea)
        else:
            if alreadyParted and partialInsertSort(begin, pivotPos) and partialInsertSort(pivotPos+1, end):
                return

        pdqLoop(begin, pivotPos, branchless, badAllowed)   // real recursion, left side
        begin = pivotPos + 1                                // tail-loop, right side
        leftmost = false
```

**Aux buffers**: `leftOffsets`/`rightOffsets` (size `blockSize + cachelineSize` each) only need to
exist for the branchless variant, allocated once per top-level sort call (not per `pdqLoop`
recursion) and passed down, matching ArrayV's `visualizeAux()`/`deleteAux()` bracket around the
whole sort. `heapSort(pos, len)` is a plain range-scoped max-heap sort (same shape as this
codebase's own `MaxHeapSort.swift`, just scoped to `[pos, pos+len)` instead of the whole array —
write a small local version rather than trying to reuse the whole-array `MaxHeapSort` struct).

**Entry points**:
- `PDQBranchedSort`: `pdqLoop(0, n, branchless: false, pdqLog(n))`. Also exposes a public
  `customSort(array, low, high)` variant (same call, different range) for potential reuse by other
  future hybrid sorts as a subroutine — port if convenient, not required for this batch.
- `PDQBranchlessSort`: allocate the aux offset buffers, `pdqLoop(0, n, branchless: true,
  pdqLog(n))`, free the aux buffers.

**Stability expectation**: unstable — standard quicksort partitioning crosses equal elements past
each other freely (no tie-break anywhere in this algorithm). Verify empirically as always, but
this one has a strong a priori expectation of instability unlike some of the others.

---

## 6. `GrailSortingTemplate`

Source: `~/ArrayV/.../templates/GrailSorting.java` (780 lines). Astrelin's classic in-place
block-merge sort, the **stable** variant — same shape as `UnstableGrailSortingTemplate` above but
with explicit key-tagging so blocks remember which "stream" (A or B) they originally came from,
preserving relative order of equal elements. Confirmed genuine reuse across all 4 subclasses (see
`PORT_INVENTORY.md`/cross-agent research) — `~55` lines of `grailInPlaceMergeSort`/
`grailInPlaceMerge` are **confirmed dead code** in ArrayV itself (no caller anywhere in the source
tree) — skip porting them.

Small primitives — identical in shape to `UnstableGrailSortingTemplate`'s own (`swap`,
`multiSwap`, `rotate`, `insertSort`, `binSearch`, `mergeWithoutBuffer`) — port those the same way,
they don't differ here. New/different pieces below.

`findKeys` — see full pseudocode already written out under §4's sibling discussion above; it's
identical in `GrailSortingTemplate` too (same function, same file lineage) — collects up to
`numKeys` distinct values into a sorted key region at the front of the range, returns how many
were actually found.

**Block-merge-with-buffer family** (this is what carries the stream-membership tracking that
makes this variant stable — contrast with `UnstableGrailSortingTemplate.mergeBuffersLeft`'s lack
of any `leftOverFrag`/`midkey` bookkeeping):

```
function mergeBuffersLeft(keysPos, midkey, pos, blockCount, blockLen, havebuf, aBlockCount, lastLen):
    // keysPos/midkey: `array[keysPos + i]` is the key of the i-th block; a key < array[midkey]
    // means that block originally came from "stream A", >= means "stream B" -- this fragment
    // tracking is exactly what preserves original relative order across the merge
    if blockCount == 0:
        aBlocksLen = aBlockCount * blockLen
        if havebuf: mergeLeft(pos, aBlocksLen, lastLen, -blockLen)
        else: mergeWithoutBuffer(pos, aBlocksLen, lastLen)
        return

    leftOverLen = blockLen
    leftOverFrag = (array[keysPos] < array[midkey]) ? 0 : 1
    processIndex = blockLen
    for keyIndex in 1..<blockCount:
        restToProcess = processIndex - leftOverLen
        nextFrag = (array[keysPos+keyIndex] < array[midkey]) ? 0 : 1
        if nextFrag == leftOverFrag:
            // same stream as the leftover fragment -- no merge needed, just slide the
            // buffer past this whole block
            if havebuf: multiSwap(pos + restToProcess - blockLen, pos + restToProcess, leftOverLen)
            restToProcess = processIndex
            leftOverLen = blockLen
        else:
            // different stream -- smart-merge the leftover fragment with this block,
            // carrying forward both a new leftover LENGTH and its new stream FRAGMENT
            if havebuf:
                (leftOverLen, leftOverFrag) = smartMergeWithBuffer(pos + restToProcess, leftOverLen, leftOverFrag, blockLen)
            else:
                (leftOverLen, leftOverFrag) = smartMergeWithoutBuffer(pos + restToProcess, leftOverLen, leftOverFrag, blockLen)
        processIndex += blockLen
    restToProcess = processIndex - leftOverLen

    if lastLen != 0:
        if leftOverFrag != 0:
            if havebuf: multiSwap(pos + restToProcess - blockLen, pos + restToProcess, leftOverLen)
            restToProcess = processIndex
            leftOverLen = blockLen * aBlockCount
            leftOverFrag = 0
        else:
            leftOverLen += blockLen * aBlockCount
        if havebuf: mergeLeft(pos + restToProcess, leftOverLen, lastLen, -blockLen)
        else: mergeWithoutBuffer(pos + restToProcess, leftOverLen, lastLen)
    else:
        if havebuf: multiSwap(pos + restToProcess, pos + restToProcess - blockLen, leftOverLen)

function mergeLeft(pos, leftLen, rightLen, dist):
    // identical shape to UnstableGrailSortingTemplate.mergeLeft (see §4) -- no stream
    // tracking needed at THIS level, the fragment bookkeeping lives one level up in
    // mergeBuffersLeft/smartMergeWithBuffer

function mergeRight(pos, leftLen, rightLen, dist):
    // identical shape to UnstableGrailSortingTemplate.mergeRight (see §4)

function smartMergeWithoutBuffer(pos, leftOverLen, leftOverFrag, regBlockLen) -> (length: Int, fragment: Int):
    if regBlockLen == 0: return (leftOverLen, leftOverFrag)
    len1 = leftOverLen; len2 = regBlockLen
    typeFrag = 1 - leftOverFrag   // 1 if this merge is "inverted" (comparing the other direction)
    if len1 != 0 and (compare(array[pos+len1-1], array[pos+len1]) - typeFrag) >= 0:
        while len1 != 0:
            foundLen = binSearch(pos+len1, len2, pos, isLeft: typeFrag != 0)
            if foundLen != 0:
                rotate(pos, len1, foundLen)
                pos += foundLen
                len2 -= foundLen
            if len2 == 0: return (len1, leftOverFrag)
            repeat:
                pos += 1; len1 -= 1
            while len1 != 0 and (compare(array[pos], array[pos+len1]) - typeFrag) < 0
    return (len2, typeFrag)

function smartMergeWithBuffer(pos, leftOverLen, leftOverFrag, blockLen) -> (length: Int, fragment: Int):
    // same shape as UnstableGrailSortingTemplate.smartMergeWithBuffer, but the comparison
    // is offset by `typeFrag` (0 or 1) instead of a plain `<=`, and it returns the new
    // FRAGMENT alongside the length
    dist = -blockLen; left = 0; right = leftOverLen; leftEnd = right; rightEnd = right + blockLen
    typeFrag = 1 - leftOverFrag
    while left < leftEnd and right < rightEnd:
        if (compare(array[pos+left], array[pos+right]) - typeFrag) < 0:
            swap(pos+dist, pos+left); dist += 1; left += 1
        else:
            swap(pos+dist, pos+right); dist += 1; right += 1
    fragment = leftOverFrag
    if left < leftEnd:
        length = leftEnd - left
        while left < leftEnd: leftEnd -= 1; rightEnd -= 1; swap(pos+leftEnd, pos+rightEnd)
    else:
        length = rightEnd - right
        fragment = typeFrag
    return (length, fragment)
```

**"XBuf" family** — a real second array (`Writes.write`/`arraycopy`) instead of same-array
swap-scratch. Same algorithm shape as the buffer family above, just overwrite instead of swap
(this genuinely doubles the surface area, per the earlier research — port both, they're used in
different phases):

```
function smartMergeWithXBuf(pos, leftOverLen, leftOverFrag, blockLen) -> (length: Int, fragment: Int):
    // identical to smartMergeWithBuffer, except every `swap(a, b)` becomes `array[a] = array[b]`
    // (destructive overwrite into the buffer region, since XBuf mode doesn't need the buffer's
    // old contents preserved)

function mergeLeftWithXBuf(pos, leftEnd, rightEnd, dist):
    // identical to mergeLeft, except every swap becomes an overwrite (array[dist] = array[...])

function mergeBuffersLeftWithXBuf(keysPos, midkey, pos, blockCount, regBlockLen, aBlockCount, lastLen):
    // identical structure to mergeBuffersLeft, but the "no merge needed, same stream" case uses
    // a real array copy instead of multiSwap, and always calls smartMergeWithXBuf/mergeLeftWithXBuf
    // instead of branching on havebuf (XBuf mode is always "has a real buffer")
```

**Block build/combine** (bottom-up run construction, then pairwise super-block merging):

```
function buildBlocks(pos, len, buildLen, extBuf, extBufPos, extBufLen):
    // like UnstableGrailSortingTemplate.buildBlocks, but can use a REAL external buffer
    // (extBuf) for the early, small-block-size merge levels via mergeLeftWithXBuf, only
    // falling back to swap-based mergeLeft once block size exceeds the buffer
    buildBuf = min(buildLen, extBufLen), rounded DOWN to the nearest power of 2
    if buildBuf != 0:
        copy array[pos-buildBuf ..< pos) into extBuf[extBufPos ..< extBufPos+buildBuf)
        // same pairwise 4-slot shuffle trick as UnstableGrailSortingTemplate.buildBlocks
        for dist in stride(1, <len, by: 2):
            extraDist = (array[pos+dist-1] > array[pos+dist]) ? 1 : 0
            array[pos+dist-3] = array[pos+dist-1+extraDist]
            array[pos+dist-2] = array[pos+dist-extraDist]
        if len is odd: array[pos+len-3] = array[pos+len-1]
        pos -= 2
        part = 2
        while part < buildBuf:
            left = 0; right = len - 2*part
            while left <= right: mergeLeftWithXBuf(pos+left, part, part, -part); left += 2*part
            rest = len - left
            if rest > part: mergeLeftWithXBuf(pos+left, part, rest-part, -part)
            else: for i in left..<len: array[pos+i-part] = array[pos+i]
            pos -= part
            part *= 2
        copy extBuf[extBufPos ..< extBufPos+buildBuf) back into array[pos+len ..< pos+len+buildBuf)
    else:
        // no usable external buffer -- same swap-based 4-slot shuffle as
        // UnstableGrailSortingTemplate.buildBlocks
        for dist in stride(1, <len, by: 2):
            extraDist = (array[pos+dist-1] > array[pos+dist]) ? 1 : 0
            swap(pos+dist-3, pos+dist-1+extraDist)
            swap(pos+dist-2, pos+dist-extraDist)
        if len is odd: swap(pos+len-1, pos+len-3)
        pos -= 2
        part = 2
    // continue doubling with the swap-based mergeLeft/rotate (same as
    // UnstableGrailSortingTemplate.buildBlocks) from `part` up to `buildLen`
    while part < buildLen:
        left = 0; right = len - 2*part
        while left <= right: mergeLeft(pos+left, part, part, -part); left += 2*part
        rest = len - left
        if rest > part: mergeLeft(pos+left, part, rest-part, -part)
        else: rotate(pos+left-part, part, rest)
        pos -= part
        part *= 2
    restToBuild = len mod (2*buildLen)
    leftOverPos = len - restToBuild
    if restToBuild <= buildLen: rotate(pos+leftOverPos, restToBuild, buildLen)
    else: mergeRight(pos+leftOverPos, buildLen, restToBuild-buildLen, buildLen)
    while leftOverPos > 0:
        leftOverPos -= 2*buildLen
        mergeRight(pos+leftOverPos, buildLen, buildLen, buildLen)

function combineBlocks(keyPos, pos, len, buildLen, regBlockLen, havebuf, buffer, bufferPos):
    // like UnstableGrailSortingTemplate.combineBlocks, but:
    //  - block-head keys live in a SEPARATE key array region (keyPos), tagged and
    //    insertion-sorted via insertSort, rather than comparing blocks' own first/last values
    //  - the block selection-sort below tie-breaks on the KEY array (stable!) instead of each
    //    block's last element (unstable) -- this one difference is the crux of what makes
    //    GrailSortingTemplate stable where UnstableGrailSortingTemplate isn't
    //  - `midkey` (the stream A/B boundary index into the key array) has to be tracked and
    //    updated as blocks get shuffled by the selection sort
    combineLen = len / (2*buildLen)
    leftOver = len mod (2*buildLen)
    if leftOver <= buildLen: len -= leftOver; leftOver = 0
    if buffer exists: copy array[pos-regBlockLen ..< pos) into buffer[bufferPos ..< bufferPos+regBlockLen)
    for i in 0...combineLen:
        if i == combineLen and leftOver == 0: break
        blockPos = pos + i*2*buildLen
        blockCount = (i == combineLen ? leftOver : 2*buildLen) / regBlockLen
        insertSort(keyPos, blockCount + (i == combineLen ? 1 : 0))
        midkey = buildLen / regBlockLen
        for index in 1..<blockCount:
            leftIndex = index - 1
            for rightIndex in index..<blockCount:
                rightComp = compare(array[blockPos+leftIndex*regBlockLen], array[blockPos+rightIndex*regBlockLen])
                if rightComp > 0 or (rightComp == 0 and array[keyPos+leftIndex] > array[keyPos+rightIndex]):
                    leftIndex = rightIndex
            if leftIndex != index - 1:
                multiSwap(blockPos+(index-1)*regBlockLen, blockPos+leftIndex*regBlockLen, regBlockLen)
                swap(keyPos+(index-1), keyPos+leftIndex)
                if midkey == index-1 or midkey == leftIndex:
                    midkey = midkey XOR (index-1) XOR leftIndex   // tracks midkey through the swap
        aBlockCount = 0
        lastLen = (i == combineLen) ? (leftOver mod regBlockLen) : 0
        if lastLen != 0:
            while aBlockCount < blockCount and array[blockPos+blockCount*regBlockLen] < array[blockPos+(blockCount-aBlockCount-1)*regBlockLen]:
                aBlockCount += 1
        if buffer exists:
            mergeBuffersLeftWithXBuf(keyPos, keyPos+midkey, blockPos, blockCount-aBlockCount, regBlockLen, aBlockCount, lastLen)
        else:
            mergeBuffersLeft(keyPos, keyPos+midkey, blockPos, blockCount-aBlockCount, regBlockLen, havebuf, aBlockCount, lastLen)
    if buffer exists:
        shift array[pos ..< pos+len) up by regBlockLen (making room), then copy buffer back into
        array[pos-regBlockLen ..< pos)
    elif havebuf:
        swap array[pos ..< pos+len) with array[pos-regBlockLen ..< pos+len-regBlockLen) (block-swap
        restoring the buffer to the front)
```

**Simple alternate path** (no block-merge machinery at all — used directly by `LazyStableSort`,
and overridden entirely by `OptimizedLazyStableSort`):

```
function lazyStableSort(pos, len):
    for dist in stride(1, <len, by: 2):
        if array[pos+dist-1] > array[pos+dist]: swap(pos+dist-1, pos+dist)
    part = 2
    while part < len:
        left = 0; right = len - 2*part
        while left <= right: mergeWithoutBuffer(pos+left, part, part); left += 2*part
        rest = len - left
        if rest > part: mergeWithoutBuffer(pos+left, part, rest-part)
        part *= 2
```

**Top-level entry** (used by `GrailSort` — the ONLY concrete algorithm that exercises the full
block-merge machinery above):

```
function commonSort(pos, len, buffer, bufferPos, bufferLen):
    if len <= 16:
        insertSort(pos, len)
        return
    blockLen = 1
    while blockLen*blockLen < len: blockLen *= 2
    numKeys = (len - 1) / blockLen + 1
    keysFound = findKeys(pos, len, numKeys + blockLen)
    bufferEnabled = true
    if keysFound < numKeys + blockLen:
        if keysFound < 4:
            // not enough distinct values to build the key/block machinery at all --
            // fall back to the simple O(n log n) lazy stable sort entirely
            lazyStableSort(pos, len)
            return
        numKeys = blockLen
        while numKeys > keysFound: numKeys /= 2
        bufferEnabled = false
        blockLen = 0
    dist = blockLen + numKeys
    buildLen = bufferEnabled ? blockLen : numKeys
    buildBlocks(pos+dist, len-dist, buildLen, bufferEnabled ? buffer : null, bufferPos, bufferEnabled ? bufferLen : 0)
    while len - dist > (buildLen *= 2):
        regBlockLen = blockLen
        buildBufEnabled = bufferEnabled
        if not bufferEnabled:
            // not enough keys for a full buffer -- estimate a regBlockLen that still keeps
            // the selection-sort-of-blocks cost bounded (see GrailSorting.java lines 702-715
            // for the exact heuristic; pure arithmetic, transcribe directly)
            ...
        combineBlocks(pos, pos+dist, len-dist, buildLen, regBlockLen, buildBufEnabled,
                      (buildBufEnabled and regBlockLen <= bufferLen) ? buffer : null, bufferPos)
    insertSort(pos, dist)
    mergeWithoutBuffer(pos, dist, len-dist)
```

**Entry points**:
- `BlockInsertionSort` — does **not** call `commonSort` at all. It's a natural-run-detecting
  insertion sort built from just `mergeWithoutBuffer` (+ transitively `binSearch`/`rotate`) as
  primitives, plus its own `findRun`/`insert1`/`insert2`. It also overrides `rotate` with ArrayV's
  `Rotations.holyGriesMills` — functionally equivalent to the shared `rotate` above (same
  "repeated block-swap of the smaller side" idea) with an added length-1 fast path as a pure
  micro-optimization; safe to just use the shared `rotate` for this port, no separate override
  needed. Own logic:
  ```
  function findRun(a, b) -> Int:
      // returns the end of the run starting at `a` -- ascending runs found as-is, descending
      // runs found and reversed in place before returning
      i = a + 1
      if i == b: return i
      if array[i-1] > array[i]:
          i += 1
          while i < b and array[i-1] > array[i]: i += 1
          reverse array[a ..< i) in place
      else:
          i += 1
          while i < b and array[i-1] <= array[i]: i += 1
      return i

  function insert1(a, l):
      // classic single-element insertion-sort shift
      tmp = array[l]; l -= 1
      while l >= a and array[l] > tmp: array[l+1] = array[l]; l -= 1
      array[l+1] = tmp

  function insert2(a, l, r):
      // inserts a PAIR (array[l], array[r]) already known l < r, shifting both into place
      // in one pass (avoids re-scanning for the second element)
      tmpL = array[l]; tmpR = array[r]; l -= 1
      while l >= a and array[l] > tmpR: array[l+2] = array[l]; l -= 1
      array[l+2] = tmpR
      while l >= a and array[l] > tmpL: array[l+1] = array[l]; l -= 1
      array[l+1] = tmpL

  function insertionSort(a, b):
      i = findRun(a, b)
      while i < b:
          j = findRun(i, b)
          len = j - i
          if len == 1: insert1(a, i)
          elif len == 2: insert2(a, i, i+1)
          else: mergeWithoutBuffer(a, i - a, len)
          i = j
  ```
  Entry: `insertionSort(0, n)`.
- `LazyStableSort` — one line: `lazyStableSort(0, n)`.
- `GrailSort` — three buffer-mode variants selectable at runtime in ArrayV (in-place / 32-item
  static buffer / `sqrt(n)`-sized dynamic buffer); for this port, pick ONE mode to ship (in-place,
  i.e. `buffer = null`, is the simplest and matches what most of the other algorithms in this
  codebase already do — no precedent here for a user-selectable runtime parameter). Entry:
  `commonSort(0, n, null, 0, 0)`.
- `OptimizedLazyStableSort` — overrides `lazyStableSort` entirely with a version that natural-run
  + insertion-sorts 16-sized chunks first (via its own `insertionSort(a, b)` — same
  natural-run-detect-then-shift-insert shape as `BlockInsertionSort`'s, but chunked to fixed
  16-element windows rather than following variable-length runs) before doubling via
  `mergeWithoutBuffer`, instead of the base version's plain pairwise-compare-then-double. Entry:
  its own `lazyStableSort(0, n)` override.

**Stability expectation**: `GrailSort`/`LazyStableSort`/`OptimizedLazyStableSort` all claim
stable by name and by the explicit key/fragment tracking in `combineBlocks`/`mergeBuffersLeft` —
still verify empirically (matching the "never trust a name" policy), but this is the one cluster
in this whole batch with real algorithmic reason to expect the claim holds up.
`BlockInsertionSort` (natural-run detection + shift-based insertion + `mergeWithoutBuffer` for
long runs) has a similarly strong a priori case for being stable — `mergeWithoutBuffer`'s
binary-search-based merge never disturbs relative order of equal elements (ties always resolve
toward whichever operand keeps encounter order, same reasoning as `StableQuickSort`'s
list-partition stability) — but confirm with the standard fuzz test regardless.

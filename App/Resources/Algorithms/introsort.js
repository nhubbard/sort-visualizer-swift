// Substituted for the originally-planned TwinSort (hybrid/medium), whose real-world implementation
// (initial "twin swap" pre-pass + bottom-up tail-merging with a separate half-size swap buffer)
// proved far more intricate than its template length suggested. IntroSort reuses building blocks
// already validated elsewhere in this batch: ternary-quicksort-style strict comparisons, 0-indexed
// heapsort (maxheapsort.js), and swap-based insertion sort (insertionsort.js).
//
// partition() uses raw engine.getValue() comparisons against a copied pivot scalar (no recorded
// marks) rather than engine.compare — the pivot value is a plain lifted scalar here, not a live
// stable index reference (unlike the ternary quicksorts' pivot-at-hi/hi-1 trick), so it falls under
// the same "held value" tradeoff as insertion/shell sort. This matches ArrayV itself, which uses
// Reads.compareValues (not compareIndices) for the equivalent checks.
function sort(engine) {
    const n = engine.count();
    const sizeThreshold = 16;

    function medianOf3(left, mid, right) {
        if (!engine.compare(right, left)) {
            engine.swap(left, right);
        }
        if (!engine.compare(mid, left)) {
            engine.swap(mid, left);
        }
        if (!engine.compare(right, mid)) {
            engine.swap(right, mid);
        }
        return mid;
    }

    function partition(lo, hi, pivotValue) {
        let i = lo, j = hi;
        while (true) {
            while (engine.getValue(i) < pivotValue) i++;
            j--;
            while (pivotValue < engine.getValue(j)) j--;
            if (!(i < j)) return i;
            engine.swap(i, j);
            i++;
        }
    }

    function heapSortRange(lo, hi) {
        const size = hi - lo;
        function siftDown(root, rangeSize) {
            while (true) {
                let largest = root;
                const left = 2 * root + 1;
                const right = 2 * root + 2;
                if (left < rangeSize && !engine.compare(lo + largest, lo + left)) largest = left;
                if (right < rangeSize && !engine.compare(lo + largest, lo + right)) largest = right;
                if (largest === root) break;
                engine.swap(lo + root, lo + largest);
                root = largest;
            }
        }
        for (let i = Math.floor(size / 2) - 1; i >= 0; i--) siftDown(i, size);
        for (let end = size - 1; end > 0; end--) {
            engine.swap(lo, lo + end);
            siftDown(0, end);
        }
    }

    function introsortLoop(lo, hi, depthLimit) {
        while (hi - lo > sizeThreshold) {
            if (depthLimit === 0) {
                heapSortRange(lo, hi);
                return;
            }
            depthLimit--;
            const mid = lo + Math.floor((hi - lo) / 2);
            const pivotIndex = medianOf3(lo, mid, hi - 1);
            const pivotValue = engine.getValue(pivotIndex);
            const p = partition(lo, hi, pivotValue);
            introsortLoop(p, hi, depthLimit);
            hi = p;
        }
    }

    function insertionSort(start, end) {
        for (let i = start + 1; i < end; i++) {
            let j = i;
            while (j > start && !engine.compare(j, j - 1)) {
                engine.swap(j - 1, j);
                j--;
            }
        }
    }

    function floorLog2(a) {
        return Math.floor(Math.log(a) / Math.log(2));
    }

    introsortLoop(0, n, 2 * floorLog2(n));
    insertionSort(0, n);
}

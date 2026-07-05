// Bentley-McIlroy-style ternary quicksort, LR two-pointer scheme. Pivot is parked at hi, a slot
// provably untouched during the scan, so full compare3 fidelity is achievable throughout.
function sort(engine) {
    quicksortTernaryLR(0, engine.count() - 1);

    function compare3(a, b) {
        const geAB = engine.compare(a, b);
        const geBA = engine.compare(b, a);
        if (geAB && geBA) return 0;
        return geAB ? 1 : -1;
    }

    function selectPivot(lo, hi) {
        const mid = Math.floor((lo + hi) / 2);
        const cLoMid = compare3(lo, mid);
        if (cLoMid === 0) return lo;
        const cLoHi = compare3(lo, hi - 1);
        const cMidHi = compare3(mid, hi - 1);
        if (cLoHi === 0 || cMidHi === 0) return hi - 1;

        if (cLoMid < 0) {
            return cMidHi < 0 ? mid : (cLoHi < 0 ? hi - 1 : lo);
        } else {
            return cMidHi > 0 ? mid : (cLoHi < 0 ? lo : hi - 1);
        }
    }

    function quicksortTernaryLR(lo, hi) {
        if (hi <= lo) return;

        const piv = selectPivot(lo, hi + 1);
        engine.swap(piv, hi);
        const pivotIndex = hi;

        let i = lo, j = hi - 1;
        let p = lo, q = hi - 1;

        for (;;) {
            let cmp;
            while (i <= j && (cmp = compare3(i, pivotIndex)) <= 0) {
                if (cmp === 0) {
                    engine.swap(i, p);
                    p++;
                }
                i++;
            }
            while (i <= j && (cmp = compare3(j, pivotIndex)) >= 0) {
                if (cmp === 0) {
                    engine.swap(j, q);
                    q--;
                }
                j--;
            }
            if (i > j) break;
            engine.swap(i, j);
            i++;
            j--;
        }

        engine.swap(i, hi);

        const numLess = i - p;
        const numGreater = q - j;

        j = i - 1;
        i = i + 1;

        const pe = lo + Math.min(p - lo, numLess);
        for (let k = lo; k < pe; k++, j--) {
            engine.swap(k, j);
        }

        const qe = hi - 1 - Math.min(hi - 1 - q, numGreater - 1);
        for (let k = hi - 1; k > qe; k--, i++) {
            engine.swap(i, k);
        }

        quicksortTernaryLR(lo, lo + numLess - 1);
        quicksortTernaryLR(hi - numGreater + 1, hi);
    }
}

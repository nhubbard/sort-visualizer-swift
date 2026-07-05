// 3-way (ternary) quicksort, LL two-pointer partition scheme. Pivot is parked at hi-1, a slot
// provably untouched during the scan, so full compare3 fidelity is achievable via two
// engine.compare calls (no raw-value fallback needed here).
function sort(engine) {
    quicksortTernaryLL(0, engine.count());

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

    function partitionTernaryLL(lo, hi) {
        const p = selectPivot(lo, hi);
        engine.swap(p, hi - 1);
        const pivotIndex = hi - 1;

        let i = lo;
        let k = hi - 1;

        for (let j = lo; j < k; j++) {
            const cmp = compare3(j, pivotIndex);
            if (cmp === 0) {
                k--;
                engine.swap(k, j);
                j--;
            } else if (cmp < 0) {
                engine.swap(i, j);
                i++;
            }
        }

        for (let s = 0; s < hi - k; s++) {
            engine.swap(i + s, hi - 1 - s);
        }

        return { first: i, second: i + (hi - k) };
    }

    function quicksortTernaryLL(lo, hi) {
        if (lo + 1 < hi) {
            const mid = partitionTernaryLL(lo, hi);
            quicksortTernaryLL(lo, mid.first);
            quicksortTernaryLL(mid.second, hi);
        }
    }
}

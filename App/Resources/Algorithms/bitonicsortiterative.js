// Direct translation of ArrayV's generalized (non-power-of-2) iterative bitonic sort.
function sort(engine) {
    const n = engine.count();

    for (let k = 2; k < n * 2; k = 2 * k) {
        const m = (Math.floor((n + (k - 1)) / k) % 2) !== 0;

        for (let j = k >> 1; j > 0; j = j >> 1) {
            for (let i = 0; i < n; i++) {
                const ij = i ^ j;
                if (ij > i && ij < n) {
                    if (((i & k) === 0) === m && !engine.compare(ij, i)) {
                        engine.swap(i, ij);
                    }
                    if (((i & k) !== 0) === m && !engine.compare(i, ij)) {
                        engine.swap(i, ij);
                    }
                }
            }
        }
    }
}

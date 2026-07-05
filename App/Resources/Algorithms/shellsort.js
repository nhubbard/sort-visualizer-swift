// Same held-value-vs-live-index issue as insertionsort.js — this is a swap-based gapped insertion
// sort (using ArrayV's own ExtendedCiuraGaps sequence) rather than ArrayV's shift-based one.
function sort(engine) {
    const n = engine.count();
    const gaps = [8861, 3938, 1750, 701, 301, 132, 57, 23, 10, 4, 1];

    for (const gap of gaps) {
        if (gap >= n) continue;
        for (let i = gap; i < n; i++) {
            let j = i;
            // Strict "values[j-gap] > values[j]", same De Morgan trick as plain insertion sort.
            while (j >= gap && !engine.compare(j, j - gap)) {
                engine.swap(j, j - gap);
                j -= gap;
            }
        }
    }
}

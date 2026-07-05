// A genuine hybrid (insertion sort for small runs, merge sort otherwise) rather than a literal
// binary-search insertion sort — uses the same swap-based insertion technique established in
// insertionsort.js.
function sort(engine) {
    const n = engine.count();
    if (n < 2) return;

    const threshold = 32;
    const tempHandle = engine.createAuxArray(n);

    mergeSort(0, n);

    function insertionSort(start, end) {
        for (let i = start + 1; i < end; i++) {
            let j = i;
            while (j > start && !engine.compare(j, j - 1)) {
                engine.swap(j - 1, j);
                j--;
            }
        }
    }

    function mergeSort(start, end) {
        if (end - start <= threshold) {
            insertionSort(start, end);
            return;
        }
        const mid = start + Math.floor((end - start) / 2);
        mergeSort(start, mid);
        mergeSort(mid, end);
        merge(start, mid, end);
    }

    function merge(start, mid, end) {
        let low = start;
        let high = mid;
        const merged = [];
        while (low < mid && high < end) {
            if (engine.compare(high, low)) {
                merged.push(engine.getValue(low));
                low++;
            } else {
                merged.push(engine.getValue(high));
                high++;
            }
        }
        while (low < mid) { merged.push(engine.getValue(low)); low++; }
        while (high < end) { merged.push(engine.getValue(high)); high++; }
        for (let i = 0; i < merged.length; i++) {
            engine.writeAux(tempHandle, start + i, merged[i]);
        }
        for (let i = 0; i < merged.length; i++) {
            engine.setValue(start + i, merged[i]);
        }
    }

    engine.deleteAuxArray(tempHandle);
}

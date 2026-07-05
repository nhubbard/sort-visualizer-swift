function sort(engine) {
    const n = engine.count();
    if (n < 2) return;

    const tempHandle = engine.createAuxArray(n);

    mergeSort(0, n);

    function mergeSort(start, end) {
        if (end - start < 2) return;
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

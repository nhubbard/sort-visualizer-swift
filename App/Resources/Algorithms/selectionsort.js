function sort(engine) {
    const n = engine.count();
    for (let i = 0; i < n - 1; i++) {
        let lowestIndex = i;
        for (let j = i + 1; j < n; j++) {
            // Strict "values[j] < values[lowestIndex]": !engine.compare(j, lowestIndex).
            if (!engine.compare(j, lowestIndex)) {
                lowestIndex = j;
            }
        }
        engine.swap(i, lowestIndex);
    }
}

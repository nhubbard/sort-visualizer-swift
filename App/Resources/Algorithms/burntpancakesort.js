// Substituted for the originally-planned PancakeInsertionSort (misc/medium), which needed
// held-value binary-search "monobound" helpers plus a direction-flip state machine — too fragile
// to port faithfully in this batch. BurntPancakeSort is a direct, index-only translation.
function sort(engine) {
    const n = engine.count();

    function flip(end) {
        let start = 0;
        while (start < end) {
            engine.swap(start, end);
            start++;
            end--;
        }
    }

    for (let i = n - 1; i > 0; i--) {
        let max = 0;
        for (let j = max + 1; j <= i; j++) {
            if (engine.compare(j, max)) {
                max = j;
            }
        }
        if (max !== i) {
            flip(max);
            flip(i);
            flip(i - 1);
            flip(max - 1);
        }
    }
}

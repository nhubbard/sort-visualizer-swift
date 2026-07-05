// Canonical textbook pancake sort; drops ArrayV's early-exit-if-already-sorted micro-optimization
// (acceptable simplification — doesn't change asymptotic behavior or correctness).
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

    function findMaxIndex(end) {
        let maxIndex = 0;
        for (let i = 1; i <= end; i++) {
            if (!engine.compare(maxIndex, i)) {
                maxIndex = i;
            }
        }
        return maxIndex;
    }

    for (let currentSize = n - 1; currentSize > 0; currentSize--) {
        const maxIndex = findMaxIndex(currentSize);
        if (maxIndex !== currentSize) {
            flip(maxIndex);
            flip(currentSize);
        }
    }
}

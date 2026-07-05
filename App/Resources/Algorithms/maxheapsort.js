// Reindexed to a standard 0-indexed binary heap (ArrayV's is 1-indexed; mathematically equivalent).
function sort(engine) {
    const n = engine.count();

    function siftDown(root, size) {
        while (true) {
            let largest = root;
            const left = 2 * root + 1;
            const right = 2 * root + 2;
            // Strict "values[left] > values[largest]": !engine.compare(largest, left).
            if (left < size && !engine.compare(largest, left)) {
                largest = left;
            }
            if (right < size && !engine.compare(largest, right)) {
                largest = right;
            }
            if (largest === root) break;
            engine.swap(root, largest);
            root = largest;
        }
    }

    for (let i = Math.floor(n / 2) - 1; i >= 0; i--) {
        siftDown(i, n);
    }
    for (let end = n - 1; end > 0; end--) {
        engine.swap(0, end);
        siftDown(0, end);
    }
}

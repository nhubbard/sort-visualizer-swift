// Direct translation of ArrayV's iterative odd-even merge sort (a Batcher sorting network).
function sort(engine) {
    const n = engine.count();

    for (let p = 1; p < n; p += p) {
        for (let k = p; k > 0; k = Math.floor(k / 2)) {
            for (let j = k % p; j + k < n; j += k + k) {
                for (let i = 0; i < k; i++) {
                    if (Math.floor((i + j) / (p + p)) === Math.floor((i + j + k) / (p + p))) {
                        if (i + j + k < n) {
                            if (!engine.compare(i + j + k, i + j)) {
                                engine.swap(i + j, i + j + k);
                            }
                        }
                    }
                }
            }
        }
    }
}

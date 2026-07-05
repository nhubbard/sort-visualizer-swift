// Faithfully mirrors ArrayV's bogoSwap: a full Fisher-Yates reshuffle each iteration,
// not a single random swap.
function sort(engine) {
    const n = engine.count();

    function isSorted() {
        for (let i = 1; i < n; i++) {
            if (!engine.compare(i, i - 1)) return false;
        }
        return true;
    }

    function shuffle() {
        for (let i = 0; i < n; i++) {
            const j = i + Math.floor(Math.random() * (n - i));
            engine.swap(i, j);
        }
    }

    while (!isSorted()) {
        shuffle();
    }
}

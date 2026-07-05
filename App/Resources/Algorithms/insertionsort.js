// ArrayV's InsertionSort shifts elements via a held copy of the current value (`Writes.write`),
// which has no equivalent here — a value lifted out of the array can't be compared against a live
// index. This uses the equivalent swap-based technique instead (same technique, same stability,
// same complexity — just moves elements one adjacent swap at a time instead of shifting a gap).
function sort(engine) {
    const n = engine.count();
    for (let i = 1; i < n; i++) {
        let j = i;
        // Strict "values[j-1] > values[j]": a > b <=> !(b >= a), i.e. !engine.compare(j, j - 1).
        // Needed for stability — using >= would also shift past equal elements.
        while (j > 0 && !engine.compare(j, j - 1)) {
            engine.swap(j - 1, j);
            j--;
        }
    }
}

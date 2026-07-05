function sort(engine) {
    const n = engine.count();
    const shrink = 1.3;
    let gap = n;
    let swapped = false;

    while (gap > 1 || swapped) {
        if (gap > 1) {
            gap = Math.floor(gap / shrink);
        }
        swapped = false;
        for (let i = 0; gap + i < n; i++) {
            // Strict "values[i] > values[i+gap]": engine.compare is always >=, and using it
            // as-is here would swap equal adjacent elements forever once gap settles at 1.
            // a > b  <=>  !(b >= a), i.e. !engine.compare(i + gap, i).
            if (!engine.compare(i + gap, i)) {
                engine.swap(i, i + gap);
                swapped = true;
            }
        }
    }
}
